import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

void main() {
  group('ChatCoordinator', () {
    test(
      'confirmPendingProposal emits medication events for confirmable proposals',
      () async {
        final eventStore = _FakeEventStore();
        final conversationRepository = _FakeConversationRepository(
          pendingProposal: ProposalView(
            actions: <ProposalActionView>[
              ProposalActionView(
                actionId: 'action-1',
                doseAmount: '200',
                doseUnit: 'mg',
                medicationName: 'Ibuprofen',
                startDate: DateTime(2026, 4, 5),
                times: <String>['08:00'],
                type: ProposalActionType.addMedicationSchedule,
              ),
            ],
            assistantText: 'Review the ibuprofen schedule.',
            createdAt: DateTime(2026, 4, 5, 8),
            proposalId: 'proposal-1',
            status: ProposalStatus.pending,
            summary: 'Add ibuprofen 200 mg at 08:00.',
            threadId: 'thread-1',
          ),
        );
        final coordinator = ChatCoordinator(
          conversationRepository: conversationRepository,
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(),
          modelProvider: _FakeModelProvider(),
        );

        await coordinator.confirmPendingProposal('thread-1');

        final eventTypes = eventStore.events
            .map((event) => event.event.type)
            .toList();
        final scheduleAdded = eventStore.events.singleWhere(
          (event) => event.event.type == 'medication_schedule_added',
        );

        expect(eventTypes, <String>[
          'proposal_confirmed',
          'medication_registered',
          'medication_schedule_added',
        ]);
        expect(
          scheduleAdded.event.payload['source_proposal_id'],
          conversationRepository.pendingProposal!.proposalId,
        );
      },
    );

    test('confirmPendingProposal ignores non-confirmable proposals', () async {
      final eventStore = _FakeEventStore();
      final coordinator = ChatCoordinator(
        conversationRepository: _FakeConversationRepository(
          pendingProposal: ProposalView(
            actions: const <ProposalActionView>[
              ProposalActionView(
                actionId: 'action-1',
                missingFields: <String>['dose'],
                type: ProposalActionType.requestMissingInfo,
              ),
            ],
            assistantText: 'I need more detail.',
            createdAt: DateTime(2026, 4, 5, 8),
            proposalId: 'proposal-1',
            status: ProposalStatus.pending,
            summary: 'Missing dose information.',
            threadId: 'thread-1',
          ),
        ),
        eventStore: eventStore,
        medicationRepository: _FakeMedicationRepository(),
        modelProvider: _FakeModelProvider(),
      );

      await coordinator.confirmPendingProposal('thread-1');

      expect(eventStore.events, isEmpty);
    });

    test(
      'submitText supersedes pending proposals and creates a new proposal',
      () async {
        final eventStore = _FakeEventStore();
        final modelProvider = _FakeModelProvider(
          response: ModelResponseContract(
            actions: <ModelProposalAction>[
              ModelProposalAction(
                actionId: 'action-2',
                doseAmount: '200',
                doseUnit: 'mg',
                medicationName: 'Ibuprofen',
                startDate: DateTime(2026, 4, 5),
                times: <String>['08:00'],
                type: ModelProposalActionType.addMedicationSchedule,
              ),
            ],
            assistantText: 'Drafted a pending ibuprofen schedule.',
            rawPayload: <String, Object?>{'provider': 'fake'},
          ),
        );
        final conversationRepository = _FakeConversationRepository(
          messages: <ConversationMessageView>[
            ConversationMessageView(
              actor: ConversationActor.user,
              createdAt: DateTime(2026, 4, 5, 7, 55),
              messageId: 'message-old',
              text: 'Current context',
              threadId: 'thread-1',
            ),
          ],
          pendingProposal: ProposalView(
            actions: const <ProposalActionView>[
              ProposalActionView(
                actionId: 'action-1',
                type: ProposalActionType.addMedicationSchedule,
              ),
            ],
            assistantText: 'Old pending proposal.',
            createdAt: DateTime(2026, 4, 5, 7, 56),
            proposalId: 'proposal-old',
            status: ProposalStatus.pending,
            summary: 'Old proposal',
            threadId: 'thread-1',
          ),
        );
        final coordinator = ChatCoordinator(
          conversationRepository: conversationRepository,
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(),
          modelProvider: modelProvider,
        );

        await coordinator.submitText('thread-1', 'Add ibuprofen 200 mg at 8am');

        final eventTypes = eventStore.events
            .map((event) => event.event.type)
            .toList();
        final proposalCreated = eventStore.events.singleWhere(
          (event) => event.event.type == 'proposal_created',
        );

        expect(eventTypes, <String>[
          'message_added',
          'proposal_superseded',
          'model_turn_recorded',
          'proposal_created',
        ]);
        expect(modelProvider.lastUserText, 'Add ibuprofen 200 mg at 8am');
        expect(
          modelProvider.lastConversation.last.text,
          'Add ibuprofen 200 mg at 8am',
        );
        expect(
          proposalCreated.aggregateId,
          proposalCreated.event.payload['proposal_id'],
        );
      },
    );
  });
}

class _FakeConversationRepository implements ConversationRepository {
  _FakeConversationRepository({
    List<ConversationMessageView>? messages,
    this.pendingProposal,
  }) : messages = messages ?? <ConversationMessageView>[];

  final List<ConversationMessageView> messages;
  final ProposalView? pendingProposal;

  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    return messages;
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    return pendingProposal;
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) {
    throw UnimplementedError();
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) {
    throw UnimplementedError();
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() {
    throw UnimplementedError();
  }
}

class _FakeMedicationRepository implements MedicationRepository {
  _FakeMedicationRepository({List<MedicationScheduleView>? activeSchedules})
    : activeSchedules = activeSchedules ?? <MedicationScheduleView>[];

  final List<MedicationScheduleView> activeSchedules;

  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    return activeSchedules;
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules() {
    throw UnimplementedError();
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) {
    throw UnimplementedError();
  }
}

class _FakeModelProvider implements ModelProvider {
  _FakeModelProvider({ModelResponseContract? response})
    : response =
          response ??
          const ModelResponseContract(
            actions: <ModelProposalAction>[],
            assistantText: 'No-op response.',
            rawPayload: <String, Object?>{},
          );

  final ModelResponseContract response;
  List<ConversationMessageView> lastConversation =
      const <ConversationMessageView>[];
  String? lastUserText;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
  }) async {
    lastConversation = conversation;
    lastUserText = userText;
    return response;
  }
}

class _FakeEventStore implements EventStore {
  final List<EventEnvelope<DomainEvent>> events =
      <EventEnvelope<DomainEvent>>[];

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> newEvents) async {
    events.addAll(newEvents);
  }

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    return List<EventEnvelope<DomainEvent>>.unmodifiable(events);
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(
      List<EventEnvelope<DomainEvent>>.unmodifiable(events),
    );
  }
}
