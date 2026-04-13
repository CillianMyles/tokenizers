import 'dart:async';
import 'dart:collection';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/drift_workspace.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

void main() {
  test(
    'DriftWorkspace includes future confirmed schedules in review context only',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final futureStartDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
      );

      await eventStore.append(<EventEnvelope<DomainEvent>>[
        _event(
          actorType: EventActorType.user,
          aggregateId: 'medication-1',
          eventId: 'event-medication-1',
          eventType: 'medication_registered',
          occurredAt: DateTime.now(),
          payload: const <String, Object?>{
            'medication_id': 'medication-1',
            'medication_name': 'Vitamin D',
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-future',
          eventId: 'event-schedule-future',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime.now(),
          payload: <String, Object?>{
            'schedule_id': 'schedule-future',
            'medication_id': 'medication-1',
            'medication_name': 'Vitamin D',
            'dose_amount': '1000',
            'dose_unit': 'IU',
            'start_date': futureStartDate.toIso8601String().split('T').first,
            'times': <String>['09:00'],
          },
        ),
      ]);
      await workspace.rebuild();

      final activeSchedules = await workspace.getActiveSchedules();
      final confirmedSchedules = await workspace
          .getCurrentAndUpcomingSchedules();

      expect(activeSchedules, isEmpty);
      expect(confirmedSchedules.single.scheduleId, 'schedule-future');

      await workspace.dispose();
    },
  );

  test(
    'DriftWorkspace serializes rebuilds so stale proposal snapshots do not overwrite confirmed state',
    () async {
      final firstLoad = Completer<List<EventEnvelope<DomainEvent>>>();
      final secondLoad = Completer<List<EventEnvelope<DomainEvent>>>();
      final store = _ControlledEventStore(
        loadResponses: Queue<Future<List<EventEnvelope<DomainEvent>>>>.from(
          <Future<List<EventEnvelope<DomainEvent>>>>[
            firstLoad.future,
            secondLoad.future,
          ],
        ),
      );
      final database = AppDatabase(NativeDatabase.memory());
      final workspace = DriftWorkspace(database: database, eventStore: store);

      store.emit(const <EventEnvelope<DomainEvent>>[]);
      store.emit(const <EventEnvelope<DomainEvent>>[]);

      secondLoad.complete(_confirmedProposalEvents());
      firstLoad.complete(_pendingProposalEvents());

      await _eventually(() async {
        final pending = await workspace.getPendingProposal('thread-1');
        final schedules = await workspace.getActiveSchedules();
        expect(pending, isNull);
        expect(schedules.single.medicationName, 'Vitamin D');
      });

      await workspace.dispose();
    },
  );

  test(
    'DriftWorkspace preserves later confirmations across multiple proposal cycles',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );
      final coordinator = ChatCoordinator(
        conversationRepository: workspace,
        eventStore: eventStore,
        medicationRepository: workspace,
        modelProvider: _SequencedModelProvider(
          responses: <ModelResponseContract>[
            _proposalResponse(
              actionId: 'action-1',
              assistantText: 'Drafted a vitamin D schedule.',
              medicationName: 'Vitamin D',
              startDate: DateTime(2026, 4, 5),
              times: const <String>['09:00'],
            ),
            _proposalResponse(
              actionId: 'action-2',
              assistantText: 'Drafted a magnesium schedule.',
              medicationName: 'Magnesium',
              startDate: null,
              times: const <String>['21:00'],
            ),
          ],
        ),
      );

      await eventStore.append(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-thread-1',
          eventType: 'thread_started',
          occurredAt: DateTime(2026, 4, 5, 8),
          payload: const <String, Object?>{
            'thread_id': 'thread-1',
            'title': 'Morning capture',
          },
        ),
      ]);

      await _eventually(() async {
        final threads = await workspace.watchThreads().first;
        expect(threads.single.threadId, 'thread-1');
      });

      await coordinator.submitText('thread-1', 'Add vitamin D 1000 IU at 9am');
      await _eventually(() async {
        final proposal = await workspace.getPendingProposal('thread-1');
        expect(proposal, isNotNull);
        expect(proposal?.status, ProposalStatus.pending);
        expect(proposal?.actions.single.medicationName, 'Vitamin D');
      });

      await coordinator.confirmPendingProposal('thread-1');
      await _eventually(() async {
        final proposal = await workspace.getPendingProposal('thread-1');
        final schedules = await workspace.getActiveSchedules();
        expect(proposal, isNull);
        expect(
          schedules.map((schedule) => schedule.medicationName),
          contains('Vitamin D'),
        );
      });

      await coordinator.submitText('thread-1', 'Add magnesium 250 mg at 9pm');
      await _eventually(() async {
        final proposal = await workspace.getPendingProposal('thread-1');
        expect(proposal, isNotNull);
        expect(proposal?.actions.single.medicationName, 'Magnesium');
      });

      await coordinator.confirmPendingProposal('thread-1');
      await _eventually(() async {
        final proposal = await workspace.getPendingProposal('thread-1');
        final schedules = await workspace.getActiveSchedules();
        expect(proposal, isNull);
        expect(
          schedules.map((schedule) => schedule.medicationName).toSet(),
          <String>{'Vitamin D', 'Magnesium'},
        );
      });

      await workspace.dispose();
    },
  );
}

class _ControlledEventStore implements EventStore {
  _ControlledEventStore({
    required Queue<Future<List<EventEnvelope<DomainEvent>>>> loadResponses,
  }) : _loadResponses = loadResponses;

  final Queue<Future<List<EventEnvelope<DomainEvent>>>> _loadResponses;
  final StreamController<List<EventEnvelope<DomainEvent>>> _controller =
      StreamController<List<EventEnvelope<DomainEvent>>>.broadcast();

  void emit(List<EventEnvelope<DomainEvent>> events) {
    _controller.add(events);
  }

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events) {
    throw UnimplementedError();
  }

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() {
    return _loadResponses.removeFirst();
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return _controller.stream;
  }
}

Future<void> _eventually(Future<void> Function() assertion) async {
  Object? lastError;
  StackTrace? lastStackTrace;

  for (var attempt = 0; attempt < 20; attempt++) {
    try {
      await assertion();
      return;
    } on Object catch (error, stackTrace) {
      lastError = error;
      lastStackTrace = stackTrace;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  Error.throwWithStackTrace(lastError!, lastStackTrace!);
}

List<EventEnvelope<DomainEvent>> _pendingProposalEvents() {
  return <EventEnvelope<DomainEvent>>[
    _event(
      aggregateId: 'thread-1',
      eventId: 'event-1',
      eventType: 'thread_started',
      occurredAt: DateTime(2026, 4, 5, 8),
      payload: const <String, Object?>{
        'thread_id': 'thread-1',
        'title': 'Morning capture',
      },
    ),
    _event(
      actorType: EventActorType.model,
      aggregateId: 'proposal-1',
      eventId: 'event-2',
      eventType: 'proposal_created',
      occurredAt: DateTime(2026, 4, 5, 8, 1),
      payload: const <String, Object?>{
        'proposal_id': 'proposal-1',
        'thread_id': 'thread-1',
        'summary': 'Add vitamin D 1000 IU at 09:00.',
        'assistant_text': 'Review the vitamin D schedule.',
        'actions': <Map<String, Object?>>[
          <String, Object?>{
            'action_id': 'action-1',
            'type': 'add_medication_schedule',
            'medication_name': 'Vitamin D',
            'dose_amount': '1000',
            'dose_unit': 'IU',
            'start_date': '2026-04-05',
            'times': <String>['09:00'],
          },
        ],
      },
    ),
  ];
}

List<EventEnvelope<DomainEvent>> _confirmedProposalEvents() {
  return <EventEnvelope<DomainEvent>>[
    ..._pendingProposalEvents(),
    _event(
      actorType: EventActorType.user,
      aggregateId: 'proposal-1',
      eventId: 'event-3',
      eventType: 'proposal_confirmed',
      occurredAt: DateTime(2026, 4, 5, 8, 2),
      payload: const <String, Object?>{
        'proposal_id': 'proposal-1',
        'thread_id': 'thread-1',
      },
    ),
    _event(
      actorType: EventActorType.user,
      aggregateId: 'medication-1',
      eventId: 'event-4',
      eventType: 'medication_registered',
      occurredAt: DateTime(2026, 4, 5, 8, 2, 1),
      payload: const <String, Object?>{
        'medication_id': 'medication-1',
        'medication_name': 'Vitamin D',
      },
    ),
    _event(
      actorType: EventActorType.user,
      aggregateId: 'schedule-1',
      eventId: 'event-5',
      eventType: 'medication_schedule_added',
      occurredAt: DateTime(2026, 4, 5, 8, 2, 1),
      payload: const <String, Object?>{
        'schedule_id': 'schedule-1',
        'medication_id': 'medication-1',
        'medication_name': 'Vitamin D',
        'dose_amount': '1000',
        'dose_unit': 'IU',
        'start_date': '2026-04-05',
        'times': <String>['09:00'],
        'thread_id': 'thread-1',
        'source_proposal_id': 'proposal-1',
      },
    ),
  ];
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
  EventActorType actorType = EventActorType.system,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: eventType.startsWith('medication_')
        ? 'medication'
        : eventType.startsWith('proposal_')
        ? 'proposal'
        : 'conversation',
    aggregateId: aggregateId,
    actorType: actorType,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}

ModelResponseContract _proposalResponse({
  required String actionId,
  required String assistantText,
  required String medicationName,
  required DateTime? startDate,
  required List<String> times,
}) {
  return ModelResponseContract(
    actions: <ModelProposalAction>[
      ModelProposalAction(
        actionId: actionId,
        doseAmount: '1000',
        doseUnit: 'IU',
        medicationName: medicationName,
        startDate: startDate,
        times: times,
        type: ModelProposalActionType.addMedicationSchedule,
      ),
    ],
    assistantText: assistantText,
    rawPayload: <String, Object?>{'provider': 'test'},
  );
}

class _SequencedModelProvider implements ModelProvider {
  _SequencedModelProvider({required List<ModelResponseContract> responses})
    : _responses = Queue<ModelResponseContract>.from(responses);

  final Queue<ModelResponseContract> _responses;

  @override
  Future<ModelResponseContract> generateResponse({
    required List confirmedSchedules,
    required List conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    return _responses.removeFirst();
  }
}
