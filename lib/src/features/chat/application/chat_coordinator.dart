import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/local_data_reset_guard.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// Orchestrates the chat-to-proposal-to-confirmation workflow.
class ChatCoordinator implements LocalDataResetGuard {
  /// Creates a chat coordinator.
  ChatCoordinator({
    required ConversationRepository conversationRepository,
    required EventStore eventStore,
    required MedicationRepository medicationRepository,
    required ModelProvider modelProvider,
  }) : _conversationRepository = conversationRepository,
       _eventStore = eventStore,
       _medicationRepository = medicationRepository,
       _modelProvider = modelProvider;

  final ConversationRepository _conversationRepository;
  final EventStore _eventStore;
  final MedicationRepository _medicationRepository;
  final ModelProvider _modelProvider;
  int _idCounter = 0;
  int _writeGeneration = 0;

  @override
  void beginLocalDataReset() {
    _writeGeneration += 1;
  }

  /// Cancels the current pending proposal for the active thread.
  Future<void> cancelPendingProposal(String threadId) async {
    final writeGeneration = _writeGeneration;
    final proposal = await _conversationRepository.getPendingProposal(threadId);
    if (!_isWriteCurrent(writeGeneration) || proposal == null) {
      return;
    }

    final correlationId = _id('corr');
    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    await _eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'proposal',
        aggregateId: proposal.proposalId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        event: DomainEvent(
          type: 'proposal_cancelled',
          payload: <String, Object?>{
            'proposal_id': proposal.proposalId,
            'thread_id': threadId,
          },
        ),
        occurredAt: DateTime.now(),
      ),
    ]);
  }

  /// Confirms the current pending proposal and emits medication events.
  Future<void> confirmPendingProposal(
    String threadId, {
    List<ProposalActionView>? editedActions,
  }) async {
    final writeGeneration = _writeGeneration;
    final proposal = await _conversationRepository.getPendingProposal(threadId);
    final confirmedActions = editedActions ?? proposal?.actions;
    if (!_isWriteCurrent(writeGeneration) ||
        proposal == null ||
        confirmedActions == null ||
        confirmedActions.isEmpty ||
        !_canConfirmActions(confirmedActions)) {
      return;
    }

    final occurredAt = DateTime.now();
    final correlationId = _id('corr');
    final confirmedSchedules = await _medicationRepository
        .getCurrentAndUpcomingSchedules();
    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    final events = <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'proposal',
        aggregateId: proposal.proposalId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        event: DomainEvent(
          type: 'proposal_confirmed',
          payload: <String, Object?>{
            'accepted_actions': confirmedActions
                .map(_proposalActionToJson)
                .toList(),
            'accepted_summary': _summarizeConfirmedActions(confirmedActions),
            'proposal_id': proposal.proposalId,
            'thread_id': threadId,
          },
        ),
        occurredAt: occurredAt,
      ),
    ];

    for (final action in confirmedActions) {
      switch (action.type) {
        case ProposalActionType.addMedicationSchedule:
          events.addAll(
            _addScheduleEvents(
              action: action,
              causationId: proposal.proposalId,
              correlationId: correlationId,
              occurredAt: occurredAt,
              sourceProposalId: proposal.proposalId,
              threadId: threadId,
            ),
          );
          break;
        case ProposalActionType.stopMedicationSchedule:
          final targetSchedule = _findSchedule(
            confirmedSchedules,
            action.targetScheduleId,
          );
          if (targetSchedule == null) {
            continue;
          }
          events.addAll(
            _removeScheduleEvents(
              existingSchedule: targetSchedule,
              causationId: proposal.proposalId,
              correlationId: correlationId,
              endDate: action.startDate ?? occurredAt,
              occurredAt: occurredAt,
            ),
          );
          break;
        case ProposalActionType.requestMissingInfo:
          break;
        case ProposalActionType.updateMedicationSchedule:
          final targetSchedule = _findSchedule(
            confirmedSchedules,
            action.targetScheduleId,
          );
          if (targetSchedule == null) {
            continue;
          }
          if ((action.medicationName ?? '').trim() !=
              targetSchedule.medicationName.trim()) {
            events.addAll(
              _removeScheduleEvents(
                existingSchedule: targetSchedule,
                causationId: proposal.proposalId,
                correlationId: correlationId,
                endDate: action.startDate ?? occurredAt,
                occurredAt: occurredAt,
              ),
            );
            events.addAll(
              _addScheduleEvents(
                action: action,
                causationId: proposal.proposalId,
                correlationId: correlationId,
                occurredAt: occurredAt,
                sourceProposalId: proposal.proposalId,
                threadId: targetSchedule.threadId ?? threadId,
              ),
            );
            continue;
          }
          events.add(
            EventEnvelope<DomainEvent>(
              eventId: _id('event'),
              aggregateType: 'medication',
              aggregateId: targetSchedule.scheduleId,
              actorType: EventActorType.user,
              correlationId: correlationId,
              causationId: proposal.proposalId,
              event: DomainEvent(
                type: 'medication_schedule_updated',
                payload: <String, Object?>{
                  'schedule_id': targetSchedule.scheduleId,
                  'medication_name':
                      action.medicationName ?? targetSchedule.medicationName,
                  'dose_amount': action.doseAmount,
                  'dose_unit': action.doseUnit,
                  'end_date': _date(action.endDate),
                  'notes': action.notes,
                  'route': action.route,
                  'source_proposal_id': proposal.proposalId,
                  'start_date': _date(action.startDate ?? occurredAt),
                  'thread_id': targetSchedule.threadId ?? threadId,
                  'dose_schedule': medicationDoseScheduleToJsonList(
                    action.resolvedDoseSchedule,
                  ),
                  'times': action.times,
                },
              ),
              occurredAt: occurredAt,
            ),
          );
          break;
      }
    }

    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    await _eventStore.append(events);
  }

  /// Sends a new text message through the local chat workflow.
  Future<void> submitText(String threadId, String text) async {
    return _submitUserTurn(threadId: threadId, userText: text);
  }

  /// Sends an image-assisted message through the local chat workflow.
  Future<void> submitImage(
    String threadId, {
    required ModelImageAttachment imageAttachment,
    String text = '',
  }) async {
    return _submitUserTurn(
      threadId: threadId,
      userText: text,
      imageAttachment: imageAttachment,
    );
  }

  Future<void> _submitUserTurn({
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    final writeGeneration = _writeGeneration;
    final trimmed = userText.trim();
    final effectiveUserText = _effectiveUserText(
      userText: trimmed,
      imageAttachment: imageAttachment,
    );
    if (effectiveUserText.isEmpty || !_isWriteCurrent(writeGeneration)) {
      return;
    }

    final now = DateTime.now();
    final correlationId = _id('corr');
    final existingMessages = await _conversationRepository.getMessages(
      threadId,
    );
    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    final pendingProposal = await _conversationRepository.getPendingProposal(
      threadId,
    );
    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    final confirmedSchedules = await _medicationRepository
        .getCurrentAndUpcomingSchedules();
    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }
    final activeSchedules = _schedulesActiveOn(now, confirmedSchedules);

    final messageId = _id('message');

    final initialEvents = <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'conversation',
        aggregateId: threadId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        event: DomainEvent(
          type: 'message_added',
          payload: <String, Object?>{
            'thread_id': threadId,
            'message_id': messageId,
            'text': _conversationMessageText(
              userText: trimmed,
              imageAttachment: imageAttachment,
            ),
            if (imageAttachment != null)
              'attachments': <Map<String, String>>[
                <String, String>{
                  'mime_type': imageAttachment.mimeType,
                  'type': 'image',
                },
              ],
          },
        ),
        occurredAt: now,
      ),
    ];

    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    await _eventStore.append(initialEvents);

    final responseConversation = <ConversationMessageView>[
      ...existingMessages,
      ConversationMessageView(
        actor: ConversationActor.user,
        createdAt: now,
        messageId: messageId,
        text: _conversationMessageText(
          userText: trimmed,
          imageAttachment: imageAttachment,
        ),
        threadId: threadId,
      ),
    ];

    final directAdherenceResult = imageAttachment == null
        ? _tryHandleTakenMessage(
            activeSchedules: activeSchedules,
            correlationId: correlationId,
            now: now,
            text: effectiveUserText,
            threadId: threadId,
          )
        : null;
    if (directAdherenceResult != null) {
      if (!_isWriteCurrent(writeGeneration)) {
        return;
      }

      await _eventStore.append(
        _assistantResponseEvents(
          assistantText: directAdherenceResult.assistantText,
          correlationId: correlationId,
          extraEvents: directAdherenceResult.events,
          threadId: threadId,
        ),
      );
      return;
    }

    late final ModelResponseContract response;
    try {
      response = await _modelProvider.generateResponse(
        confirmedSchedules: confirmedSchedules,
        conversation: responseConversation,
        threadId: threadId,
        userText: effectiveUserText,
        imageAttachment: imageAttachment,
      );
    } on Object catch (error, stackTrace) {
      final errorMessage = _describeModelError(error);
      response = ModelResponseContract(
        actions: const <ModelProposalAction>[],
        assistantText:
            'Gemini request failed. $errorMessage Your message is still stored locally.',
        rawPayload: <String, Object?>{
          'provider_error_message': errorMessage,
          'provider_error': error.toString(),
          'stack_trace': stackTrace.toString(),
        },
      );
    }

    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    final responseEvents = <EventEnvelope<DomainEvent>>[];

    if (response.actions.isNotEmpty) {
      if (pendingProposal != null) {
        responseEvents.add(
          EventEnvelope<DomainEvent>(
            eventId: _id('event'),
            aggregateType: 'proposal',
            aggregateId: pendingProposal.proposalId,
            actorType: EventActorType.system,
            correlationId: correlationId,
            event: DomainEvent(
              type: 'proposal_superseded',
              payload: <String, Object?>{
                'proposal_id': pendingProposal.proposalId,
                'thread_id': threadId,
              },
            ),
            occurredAt: now,
          ),
        );
      }
    }

    responseEvents.addAll(
      _assistantResponseEvents(
        assistantText: response.assistantText,
        correlationId: correlationId,
        rawPayload: response.rawPayload,
        threadId: threadId,
      ),
    );

    if (response.actions.isNotEmpty) {
      final proposalId = _id('proposal');
      responseEvents.add(
        EventEnvelope<DomainEvent>(
          eventId: _id('event'),
          aggregateType: 'proposal',
          aggregateId: proposalId,
          actorType: EventActorType.model,
          correlationId: correlationId,
          event: DomainEvent(
            type: 'proposal_created',
            payload: <String, Object?>{
              'actions': response.actions.map(_actionToJson).toList(),
              'assistant_text': response.assistantText,
              'proposal_id': proposalId,
              'summary': _summarizeActions(response.actions),
              'thread_id': threadId,
            },
          ),
          occurredAt: DateTime.now(),
        ),
      );
    }

    if (!_isWriteCurrent(writeGeneration)) {
      return;
    }

    await _eventStore.append(responseEvents);
  }

  String _conversationMessageText({
    required String userText,
    required ModelImageAttachment? imageAttachment,
  }) {
    if (imageAttachment == null) {
      return userText;
    }
    if (userText.isEmpty) {
      return 'Shared a script photo for review.';
    }
    return 'Shared a script photo for review.\n\n$userText';
  }

  String _effectiveUserText({
    required String userText,
    required ModelImageAttachment? imageAttachment,
  }) {
    if (userText.isNotEmpty) {
      return userText;
    }
    if (imageAttachment == null) {
      return '';
    }
    return 'Review this prescription photo and draft any medication '
        'schedule changes it implies.';
  }

  bool _isWriteCurrent(int generation) => generation == _writeGeneration;

  Map<String, Object?> _actionToJson(ModelProposalAction action) {
    return <String, Object?>{
      'action_id': action.actionId,
      'dose_amount': action.doseAmount,
      'dose_unit': action.doseUnit,
      'end_date': _date(action.endDate),
      'medication_name': action.medicationName,
      'missing_fields': action.missingFields,
      'notes': action.notes,
      'route': action.route,
      'start_date': _date(action.startDate),
      'target_schedule_id': action.targetScheduleId,
      'dose_schedule': medicationDoseScheduleToJsonList(
        action.resolvedDoseSchedule,
      ),
      'times': action.times,
      'type': switch (action.type) {
        ModelProposalActionType.addMedicationSchedule =>
          'add_medication_schedule',
        ModelProposalActionType.requestMissingInfo => 'request_missing_info',
        ModelProposalActionType.stopMedicationSchedule =>
          'stop_medication_schedule',
        ModelProposalActionType.updateMedicationSchedule =>
          'update_medication_schedule',
      },
    };
  }

  List<EventEnvelope<DomainEvent>> _assistantResponseEvents({
    required String assistantText,
    required String correlationId,
    required String threadId,
    Map<String, Object?> rawPayload = const <String, Object?>{},
    List<EventEnvelope<DomainEvent>> extraEvents =
        const <EventEnvelope<DomainEvent>>[],
  }) {
    return <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'conversation',
        aggregateId: threadId,
        actorType: EventActorType.model,
        correlationId: correlationId,
        event: DomainEvent(
          type: 'model_turn_recorded',
          payload: <String, Object?>{
            'assistant_text': assistantText,
            'message_id': _id('message'),
            'raw_payload': rawPayload,
            'thread_id': threadId,
          },
        ),
        occurredAt: DateTime.now(),
      ),
      ...extraEvents,
    ];
  }

  List<EventEnvelope<DomainEvent>> _addScheduleEvents({
    required ProposalActionView action,
    required String causationId,
    required String correlationId,
    required DateTime occurredAt,
    required String sourceProposalId,
    required String threadId,
  }) {
    final medicationId = _id('medication');
    final scheduleId = _id('schedule');
    return <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: medicationId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_registered',
          payload: <String, Object?>{
            'medication_id': medicationId,
            'medication_name': action.medicationName,
          },
        ),
        occurredAt: occurredAt,
      ),
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: scheduleId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_schedule_added',
          payload: <String, Object?>{
            'schedule_id': scheduleId,
            'medication_id': medicationId,
            'medication_name': action.medicationName,
            'dose_amount': action.doseAmount,
            'dose_unit': action.doseUnit,
            'end_date': _date(action.endDate),
            'notes': action.notes,
            'route': action.route,
            'source_proposal_id': sourceProposalId,
            'start_date': _date(action.startDate ?? occurredAt),
            'thread_id': threadId,
            'dose_schedule': medicationDoseScheduleToJsonList(
              action.resolvedDoseSchedule,
            ),
            'times': action.times,
          },
        ),
        occurredAt: occurredAt,
      ),
    ];
  }

  bool _canConfirmActions(List<ProposalActionView> actions) {
    return actions.every((action) {
      return action.type != ProposalActionType.requestMissingInfo &&
          _draftFromAction(action).isValid;
    });
  }

  MedicationScheduleDraft _draftFromAction(ProposalActionView action) {
    return MedicationScheduleDraft(
      doseAmount: action.doseAmount,
      doseSchedule: action.doseSchedule,
      doseUnit: action.doseUnit,
      endDate: action.endDate,
      medicationName: action.medicationName ?? '',
      notes: action.notes,
      route: action.route,
      startDate: action.startDate ?? DateTime.now(),
      times: action.times,
    );
  }

  MedicationScheduleView? _findSchedule(
    List<MedicationScheduleView> schedules,
    String? scheduleId,
  ) {
    if (scheduleId == null) {
      return null;
    }
    for (final schedule in schedules) {
      if (schedule.scheduleId == scheduleId) {
        return schedule;
      }
    }
    return null;
  }

  Map<String, Object?> _proposalActionToJson(ProposalActionView action) {
    return <String, Object?>{
      'action_id': action.actionId,
      'dose_amount': action.doseAmount,
      'dose_unit': action.doseUnit,
      'end_date': _date(action.endDate),
      'medication_name': action.medicationName,
      'missing_fields': action.missingFields,
      'notes': action.notes,
      'route': action.route,
      'start_date': _date(action.startDate),
      'target_schedule_id': action.targetScheduleId,
      'dose_schedule': medicationDoseScheduleToJsonList(
        action.resolvedDoseSchedule,
      ),
      'times': action.times,
      'type': action.type.wireValue,
    };
  }

  List<EventEnvelope<DomainEvent>> _removeScheduleEvents({
    required MedicationScheduleView existingSchedule,
    required String causationId,
    required String correlationId,
    required DateTime endDate,
    required DateTime occurredAt,
  }) {
    return <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: existingSchedule.scheduleId,
        actorType: EventActorType.user,
        correlationId: correlationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_schedule_stopped',
          payload: <String, Object?>{
            'schedule_id': existingSchedule.scheduleId,
            'end_date': _date(endDate),
          },
        ),
        occurredAt: occurredAt,
      ),
    ];
  }

  String _date(DateTime? dateTime) {
    if (dateTime == null) {
      return '';
    }
    return dateTime.toIso8601String().split('T').first;
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
  }

  String _summarizeActions(List<ModelProposalAction> actions) {
    final first = actions.first;
    return switch (first.type) {
      ModelProposalActionType.addMedicationSchedule =>
        'Add ${first.medicationName ?? 'medication'}'
                '${first.resolvedDoseSchedule.isEmpty ? '' : ' ${summarizeMedicationDoseSchedule(first.resolvedDoseSchedule)}'}'
            .trim(),
      ModelProposalActionType.requestMissingInfo =>
        'Request missing information before a schedule can be created.',
      ModelProposalActionType.stopMedicationSchedule =>
        'Stop ${first.medicationName ?? 'the active medication schedule'}.',
      ModelProposalActionType.updateMedicationSchedule =>
        'Update ${first.medicationName ?? 'the medication schedule'}.',
    };
  }

  String _summarizeConfirmedActions(List<ProposalActionView> actions) {
    final first = actions.first;
    return switch (first.type) {
      ProposalActionType.addMedicationSchedule =>
        'Add ${first.medicationName ?? 'medication'}'
                '${first.resolvedDoseSchedule.isEmpty ? '' : ' ${summarizeMedicationDoseSchedule(first.resolvedDoseSchedule)}'}'
            .trim(),
      ProposalActionType.requestMissingInfo =>
        'Request missing information before a schedule can be created.',
      ProposalActionType.stopMedicationSchedule =>
        'Stop ${first.medicationName ?? 'the active medication schedule'}.',
      ProposalActionType.updateMedicationSchedule =>
        'Update ${first.medicationName ?? 'the medication schedule'}.',
    };
  }

  String _describeModelError(Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) {
      return 'An unknown error occurred.';
    }
    if (error case StateError(:final message)) {
      return message;
    }
    return message;
  }

  _TakenMessageResult? _tryHandleTakenMessage({
    required List<MedicationScheduleView> activeSchedules,
    required String correlationId,
    required DateTime now,
    required String text,
    required String threadId,
  }) {
    final normalizedText = text.toLowerCase();
    final explicitTakenPattern = RegExp(
      r'\b(i\s+(already\s+)?took|already\s+took|i\s+have\s+taken|have\s+taken|i\s+took|took)\b',
    );
    if (!explicitTakenPattern.hasMatch(normalizedText)) {
      return null;
    }

    final matchedSchedules = activeSchedules
        .where((schedule) {
          return normalizedText.contains(schedule.medicationName.toLowerCase());
        })
        .toList(growable: false);

    MedicationScheduleView? schedule;
    if (matchedSchedules.length == 1) {
      schedule = matchedSchedules.single;
    } else if (matchedSchedules.isEmpty && activeSchedules.length == 1) {
      schedule = activeSchedules.single;
    }

    if (schedule == null) {
      return const _TakenMessageResult(
        assistantText:
            'I can record that, but tell me which medication you took.',
      );
    }

    final takenAt = _parseReportedTime(text, now) ?? now;
    final scheduledFor = _resolveScheduledFor(
      schedule: schedule,
      referenceTime: takenAt,
    );
    final event = EventEnvelope<DomainEvent>(
      eventId: _id('event'),
      aggregateType: 'medication',
      aggregateId: schedule.scheduleId,
      actorType: EventActorType.user,
      correlationId: correlationId,
      event: DomainEvent(
        type: 'medication_taken',
        payload: <String, Object?>{
          'medication_name': schedule.medicationName,
          'recorded_at': now.toIso8601String(),
          'schedule_id': schedule.scheduleId,
          'scheduled_for': scheduledFor.toIso8601String(),
          'source_proposal_id': schedule.sourceProposalId,
          'taken_at': takenAt.toIso8601String(),
          'thread_id': schedule.threadId ?? threadId,
        },
      ),
      occurredAt: now,
    );

    return _TakenMessageResult(
      assistantText:
          'Recorded ${schedule.medicationName} as taken at '
          '${_timeLabel(takenAt)}.',
      events: <EventEnvelope<DomainEvent>>[event],
    );
  }

  List<MedicationScheduleView> _schedulesActiveOn(
    DateTime day,
    List<MedicationScheduleView> schedules,
  ) {
    final dayOnly = _dateOnly(day);
    return schedules
        .where((schedule) {
          final startDate = _dateOnly(schedule.startDate);
          final endDate = schedule.endDate == null
              ? null
              : _dateOnly(schedule.endDate!);
          return !startDate.isAfter(dayOnly) &&
              (endDate == null || !endDate.isBefore(dayOnly));
        })
        .toList(growable: false);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime? _parseReportedTime(String text, DateTime now) {
    final match = RegExp(
      r'\bat\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) {
      return null;
    }
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final meridiem = match.group(3)?.toLowerCase();
    if (meridiem == 'pm' && hour < 12) {
      hour += 12;
    } else if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  DateTime _resolveScheduledFor({
    required MedicationScheduleView schedule,
    required DateTime referenceTime,
  }) {
    if (schedule.times.isEmpty) {
      return DateTime(
        referenceTime.year,
        referenceTime.month,
        referenceTime.day,
        referenceTime.hour,
        referenceTime.minute,
      );
    }

    DateTime? bestMatch;
    Duration? bestDifference;
    for (final time in schedule.times) {
      final parts = time.split(':');
      final scheduledTime = DateTime(
        referenceTime.year,
        referenceTime.month,
        referenceTime.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
      final difference = scheduledTime.difference(referenceTime).abs();
      if (bestDifference == null || difference < bestDifference) {
        bestDifference = difference;
        bestMatch = scheduledTime;
      }
    }
    return bestMatch!;
  }

  String _timeLabel(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TakenMessageResult {
  const _TakenMessageResult({
    required this.assistantText,
    this.events = const <EventEnvelope<DomainEvent>>[],
  });

  final String assistantText;
  final List<EventEnvelope<DomainEvent>> events;
}
