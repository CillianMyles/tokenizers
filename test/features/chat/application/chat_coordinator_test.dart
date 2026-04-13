import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
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

    test('confirmPendingProposal preserves per-time doses', () async {
      final eventStore = _FakeEventStore();
      final conversationRepository = _FakeConversationRepository(
        pendingProposal: ProposalView(
          actions: <ProposalActionView>[
            ProposalActionView(
              actionId: 'action-1',
              medicationName: 'Tacrolimus',
              startDate: DateTime(2026, 4, 5),
              doseSchedule: const <MedicationDoseScheduleEntry>[
                MedicationDoseScheduleEntry(
                  time: '07:00',
                  doseAmount: '1.2',
                  doseUnit: 'mg',
                ),
                MedicationDoseScheduleEntry(
                  time: '19:00',
                  doseAmount: '1.0',
                  doseUnit: 'mg',
                ),
              ],
              times: <String>['07:00', '19:00'],
              type: ProposalActionType.addMedicationSchedule,
            ),
          ],
          assistantText: 'Review the tacrolimus schedule.',
          createdAt: DateTime(2026, 4, 5, 8),
          proposalId: 'proposal-1',
          status: ProposalStatus.pending,
          summary: 'Add Tacrolimus',
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

      final scheduleAdded = eventStore.events.singleWhere(
        (event) => event.event.type == 'medication_schedule_added',
      );

      expect(
        scheduleAdded.event.payload['dose_schedule'],
        <Map<String, Object?>>[
          <String, Object?>{
            'time': '07:00',
            'dose_amount': '1.2',
            'dose_unit': 'mg',
          },
          <String, Object?>{
            'time': '19:00',
            'dose_amount': '1.0',
            'dose_unit': 'mg',
          },
        ],
      );
    });

    test('confirmPendingProposal uses edited actions when provided', () async {
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

      await coordinator.confirmPendingProposal(
        'thread-1',
        editedActions: <ProposalActionView>[
          ProposalActionView(
            actionId: 'action-1',
            doseAmount: '400',
            doseUnit: 'mg',
            medicationName: 'Ibuprofen',
            startDate: DateTime(2026, 4, 6),
            times: <String>['09:00'],
            type: ProposalActionType.addMedicationSchedule,
          ),
        ],
      );

      final proposalConfirmed = eventStore.events.singleWhere(
        (event) => event.event.type == 'proposal_confirmed',
      );
      final scheduleAdded = eventStore.events.singleWhere(
        (event) => event.event.type == 'medication_schedule_added',
      );

      expect(
        proposalConfirmed.event.payload['accepted_summary'],
        'Add Ibuprofen 09:00 • 400 mg',
      );
      expect(scheduleAdded.event.payload['dose_amount'], '400');
      expect(scheduleAdded.event.payload['start_date'], '2026-04-06');
      expect(scheduleAdded.event.payload['times'], <String>['09:00']);
    });

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
      'submitText drops delayed response events after a local data reset begins',
      () async {
        final modelProvider = _CompletingModelProvider();
        final eventStore = _FakeEventStore();
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(),
          modelProvider: modelProvider,
        );

        final submission = coordinator.submitText('thread-1', 'Add vitamin D');
        await Future<void>.delayed(Duration.zero);

        coordinator.beginLocalDataReset();
        modelProvider.complete(
          const ModelResponseContract(
            actions: <ModelProposalAction>[
              ModelProposalAction(
                actionId: 'action-1',
                medicationName: 'Vitamin D',
                startDate: null,
                times: <String>['09:00'],
                type: ModelProposalActionType.addMedicationSchedule,
              ),
            ],
            assistantText: 'Review the vitamin D proposal.',
            rawPayload: <String, Object?>{},
          ),
        );
        await submission;

        expect(
          eventStore.events.map((event) => event.event.type).toList(),
          <String>['message_added'],
        );
      },
    );

    test(
      'submitImage records a placeholder message and forwards the attachment',
      () async {
        final eventStore = _FakeEventStore();
        final modelProvider = _FakeModelProvider(
          response: const ModelResponseContract(
            actions: <ModelProposalAction>[],
            assistantText: 'Drafted from the script photo.',
            rawPayload: <String, Object?>{},
          ),
        );
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(),
          modelProvider: modelProvider,
        );

        await coordinator.submitImage(
          'thread-1',
          imageAttachment: ModelImageAttachment(
            bytes: Uint8List.fromList(<int>[1, 2, 3]),
            mimeType: 'image/jpeg',
          ),
        );

        final messageAdded = eventStore.events.firstWhere(
          (event) => event.event.type == 'message_added',
        );

        expect(
          messageAdded.event.payload['text'],
          'Shared a script photo for review.',
        );
        expect(messageAdded.event.payload['attachments'], <Map<String, String>>[
          <String, String>{'mime_type': 'image/jpeg', 'type': 'image'},
        ]);
        expect(
          modelProvider.lastUserText,
          'Review this prescription photo and draft any medication '
          'schedule changes it implies.',
        );
        expect(modelProvider.lastImageAttachment, isNotNull);
        expect(modelProvider.lastImageAttachment?.mimeType, 'image/jpeg');
        expect(
          modelProvider.lastConversation.single.text,
          'Shared a script photo for review.',
        );
      },
    );

    test(
      'confirmPendingProposal emits schedule update events for update actions',
      () async {
        final eventStore = _FakeEventStore();
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(
            pendingProposal: ProposalView(
              actions: <ProposalActionView>[
                ProposalActionView(
                  actionId: 'action-1',
                  doseAmount: '750',
                  doseUnit: 'mg',
                  medicationName: 'Metformin',
                  startDate: DateTime(2026, 4, 5),
                  targetScheduleId: 'schedule-1',
                  times: <String>['09:00', '21:00'],
                  type: ProposalActionType.updateMedicationSchedule,
                ),
              ],
              assistantText: 'Review the updated metformin schedule.',
              createdAt: DateTime(2026, 4, 5, 8),
              proposalId: 'proposal-1',
              status: ProposalStatus.pending,
              summary: 'Update metformin.',
              threadId: 'thread-1',
            ),
          ),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(
            activeSchedules: <MedicationScheduleView>[
              MedicationScheduleView(
                doseAmount: '500',
                doseUnit: 'mg',
                medicationName: 'Metformin',
                scheduleId: 'schedule-1',
                startDate: DateTime(2026, 4, 1),
                threadId: 'thread-1',
                times: const <String>['08:00', '20:00'],
              ),
            ],
          ),
          modelProvider: _FakeModelProvider(),
        );

        await coordinator.confirmPendingProposal('thread-1');

        final eventTypes = eventStore.events
            .map((event) => event.event.type)
            .toList();
        final scheduleUpdated = eventStore.events.singleWhere(
          (event) => event.event.type == 'medication_schedule_updated',
        );

        expect(eventTypes, <String>[
          'proposal_confirmed',
          'medication_schedule_updated',
        ]);
        expect(scheduleUpdated.event.payload['schedule_id'], 'schedule-1');
        expect(scheduleUpdated.event.payload['dose_amount'], '750');
        expect(scheduleUpdated.event.payload['times'], <String>[
          '09:00',
          '21:00',
        ]);
      },
    );

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

    test(
      'submitText surfaces provider failures in the recorded assistant turn',
      () async {
        final eventStore = _FakeEventStore();
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(),
          modelProvider: _ThrowingModelProvider(
            message: 'Missing GEMINI_API_KEY in your local .env.',
          ),
        );

        await coordinator.submitText('thread-1', 'Add ibuprofen 200 mg at 8am');

        final assistantTurn = eventStore.events.singleWhere(
          (event) => event.event.type == 'model_turn_recorded',
        );

        expect(
          assistantTurn.event.payload['assistant_text'],
          contains('Missing GEMINI_API_KEY in your local .env.'),
        );
      },
    );

    test(
      'submitText records taken medication directly without replacing drafts',
      () async {
        final eventStore = _FakeEventStore();
        final modelProvider = _FakeModelProvider();
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(
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
          ),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(
            activeSchedules: <MedicationScheduleView>[
              MedicationScheduleView(
                doseAmount: '1000',
                doseUnit: 'IU',
                medicationName: 'Vitamin D',
                scheduleId: 'schedule-1',
                sourceProposalId: 'proposal-source',
                startDate: DateTime(2026, 4, 1),
                threadId: 'thread-1',
                times: const <String>['09:00'],
              ),
            ],
          ),
          modelProvider: modelProvider,
        );

        await coordinator.submitText('thread-1', 'I took vitamin d at 9:05');

        final eventTypes = eventStore.events
            .map((event) => event.event.type)
            .toList();
        final takenEvent = eventStore.events.singleWhere(
          (event) => event.event.type == 'medication_taken',
        );
        final assistantTurn = eventStore.events.singleWhere(
          (event) => event.event.type == 'model_turn_recorded',
        );

        expect(eventTypes, <String>[
          'message_added',
          'model_turn_recorded',
          'medication_taken',
        ]);
        expect(modelProvider.lastUserText, isNull);
        expect(takenEvent.event.payload['schedule_id'], 'schedule-1');
        expect(
          takenEvent.event.payload['source_proposal_id'],
          'proposal-source',
        );
        final scheduledFor = DateTime.parse(
          takenEvent.event.payload['scheduled_for']! as String,
        );
        final recordedAt = DateTime.parse(
          takenEvent.event.payload['recorded_at']! as String,
        );
        final takenAt = DateTime.parse(
          takenEvent.event.payload['taken_at']! as String,
        );
        expect(scheduledFor.year, recordedAt.year);
        expect(scheduledFor.month, recordedAt.month);
        expect(scheduledFor.day, recordedAt.day);
        expect(scheduledFor.hour, 9);
        expect(scheduledFor.minute, 0);
        expect(takenAt.year, recordedAt.year);
        expect(takenAt.month, recordedAt.month);
        expect(takenAt.day, recordedAt.day);
        expect(takenAt.hour, 9);
        expect(takenAt.minute, 5);
        expect(recordedAt, takenEvent.occurredAt);
        expect(
          assistantTurn.event.payload['assistant_text'],
          'Recorded Vitamin D as taken at 09:05.',
        );
      },
    );

    test(
      'submitText asks for clarification when a taken message is ambiguous',
      () async {
        final eventStore = _FakeEventStore();
        final modelProvider = _FakeModelProvider();
        final coordinator = ChatCoordinator(
          conversationRepository: _FakeConversationRepository(),
          eventStore: eventStore,
          medicationRepository: _FakeMedicationRepository(
            activeSchedules: <MedicationScheduleView>[
              MedicationScheduleView(
                medicationName: 'Vitamin D',
                scheduleId: 'schedule-1',
                startDate: DateTime(2026, 4, 1),
                times: const <String>['09:00'],
              ),
              MedicationScheduleView(
                medicationName: 'Magnesium',
                scheduleId: 'schedule-2',
                startDate: DateTime(2026, 4, 1),
                times: const <String>['21:00'],
              ),
            ],
          ),
          modelProvider: modelProvider,
        );

        await coordinator.submitText('thread-1', 'I already took it');

        final eventTypes = eventStore.events
            .map((event) => event.event.type)
            .toList();
        final assistantTurn = eventStore.events.singleWhere(
          (event) => event.event.type == 'model_turn_recorded',
        );

        expect(eventTypes, <String>['message_added', 'model_turn_recorded']);
        expect(modelProvider.lastUserText, isNull);
        expect(
          assistantTurn.event.payload['assistant_text'],
          'I can record that, but tell me which medication you took.',
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
  ModelImageAttachment? lastImageAttachment;
  String? lastUserText;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    lastConversation = conversation;
    lastImageAttachment = imageAttachment;
    lastUserText = userText;
    return response;
  }
}

class _CompletingModelProvider implements ModelProvider {
  final Completer<ModelResponseContract> _completer =
      Completer<ModelResponseContract>();

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) {
    return _completer.future;
  }

  void complete(ModelResponseContract response) {
    _completer.complete(response);
  }
}

class _ThrowingModelProvider implements ModelProvider {
  const _ThrowingModelProvider({required this.message});

  final String message;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) {
    throw StateError(message);
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
