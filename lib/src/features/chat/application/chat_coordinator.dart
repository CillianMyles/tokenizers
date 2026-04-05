import '../../../core/application/event_store.dart';
import '../../../core/domain/domain_event.dart';
import '../../../core/domain/event_envelope.dart';
import '../../../core/model/model_provider.dart';
import '../../../core/model/model_response_contract.dart';
import '../../calendar/application/medication_repository.dart';
import '../domain/conversation_models.dart';
import '../../proposals/domain/proposal_models.dart';
import 'conversation_repository.dart';

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
  Future<void> confirmPendingProposal(String threadId) async {
    final proposal = await _conversationRepository.getPendingProposal(threadId);
    if (proposal == null || !proposal.isConfirmable) {
      return;
    }

    final occurredAt = DateTime.now();
    final correlationId = _id('corr');
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
            'proposal_id': proposal.proposalId,
            'thread_id': threadId,
          },
        ),
        occurredAt: occurredAt,
      ),
    ];

    for (final action in proposal.actions) {
      switch (action.type) {
        case ProposalActionType.addMedicationSchedule:
          final medicationId = _id('medication');
          final scheduleId = _id('schedule');
          events.addAll(<EventEnvelope<DomainEvent>>[
            EventEnvelope<DomainEvent>(
              eventId: _id('event'),
              aggregateType: 'medication',
              aggregateId: medicationId,
              actorType: EventActorType.user,
              correlationId: correlationId,
              causationId: proposal.proposalId,
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
              causationId: proposal.proposalId,
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
                  'source_proposal_id': proposal.proposalId,
                  'start_date': _date(action.startDate),
                  'thread_id': threadId,
                  'times': action.times,
                },
              ),
              occurredAt: occurredAt,
            ),
          ]);
          break;
        case ProposalActionType.stopMedicationSchedule:
          if (action.targetScheduleId == null) {
            continue;
          }
          events.add(
            EventEnvelope<DomainEvent>(
              eventId: _id('event'),
              aggregateType: 'medication',
              aggregateId: action.targetScheduleId!,
              actorType: EventActorType.user,
              correlationId: correlationId,
              causationId: proposal.proposalId,
              event: DomainEvent(
                type: 'medication_schedule_stopped',
                payload: <String, Object?>{
                  'schedule_id': action.targetScheduleId,
                  'end_date': _date(action.startDate ?? occurredAt),
                },
              ),
              occurredAt: occurredAt,
            ),
          );
          break;
        case ProposalActionType.requestMissingInfo:
        case ProposalActionType.updateMedicationSchedule:
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

    final response = await _modelProvider.generateResponse(
      activeSchedules: activeSchedules,
      conversation: <ConversationMessageView>[
        ...existingMessages,
        ConversationMessageView(
          actor: ConversationActor.user,
          createdAt: now,
          messageId: messageId,
          text: trimmed,
          threadId: threadId,
        ),
      ],
      threadId: threadId,
      userText: trimmed,
    );

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
}
