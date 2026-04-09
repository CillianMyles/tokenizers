import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// Orchestrates the chat-to-proposal-to-confirmation workflow.
class ChatCoordinator {
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

  /// Cancels the current pending proposal for the active thread.
  Future<void> cancelPendingProposal(String threadId) async {
    final proposal = await _conversationRepository.getPendingProposal(threadId);
    if (proposal == null) {
      return;
    }

    final correlationId = _id('corr');
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
    final proposal = await _conversationRepository.getPendingProposal(threadId);
    final confirmedActions = editedActions ?? proposal?.actions;
    if (proposal == null ||
        confirmedActions == null ||
        confirmedActions.isEmpty ||
        !_canConfirmActions(confirmedActions)) {
      return;
    }

    final occurredAt = DateTime.now();
    final correlationId = _id('corr');
    final activeSchedules = await _medicationRepository.getActiveSchedules();
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
            activeSchedules,
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
            activeSchedules,
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
                  'times': action.times,
                },
              ),
              occurredAt: occurredAt,
            ),
          );
          break;
      }
    }

    await _eventStore.append(events);
  }

  /// Sends a new text message through the local chat workflow.
  Future<void> submitText(String threadId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final correlationId = _id('corr');
    final existingMessages = await _conversationRepository.getMessages(
      threadId,
    );
    final pendingProposal = await _conversationRepository.getPendingProposal(
      threadId,
    );
    final activeSchedules = await _medicationRepository.getActiveSchedules();
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
            'text': trimmed,
          },
        ),
        occurredAt: now,
      ),
    ];

    if (pendingProposal != null) {
      initialEvents.add(
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

    await _eventStore.append(initialEvents);

    final responseConversation = <ConversationMessageView>[
      ...existingMessages,
      ConversationMessageView(
        actor: ConversationActor.user,
        createdAt: now,
        messageId: messageId,
        text: trimmed,
        threadId: threadId,
      ),
    ];

    late final ModelResponseContract response;
    try {
      response = await _modelProvider.generateResponse(
        activeSchedules: activeSchedules,
        conversation: responseConversation,
        threadId: threadId,
        userText: trimmed,
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

    final responseEvents = <EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'conversation',
        aggregateId: threadId,
        actorType: EventActorType.model,
        correlationId: correlationId,
        event: DomainEvent(
          type: 'model_turn_recorded',
          payload: <String, Object?>{
            'assistant_text': response.assistantText,
            'message_id': _id('message'),
            'raw_payload': response.rawPayload,
            'thread_id': threadId,
          },
        ),
        occurredAt: DateTime.now(),
      ),
    ];

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

    await _eventStore.append(responseEvents);
  }

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
        'Add ${first.medicationName} ${first.doseAmount ?? ''} ${first.doseUnit ?? ''}'
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
        'Add ${first.medicationName} ${first.doseAmount ?? ''} ${first.doseUnit ?? ''}'
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
}
