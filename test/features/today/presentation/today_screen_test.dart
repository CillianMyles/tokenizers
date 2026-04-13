import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';
import 'package:tokenizers/src/features/today/presentation/today_screen.dart';

void main() {
  testWidgets('TodayScreen shows taken progress for scheduled doses', (
    tester,
  ) async {
    final today = DateTime.now();
    final date = DateTime(today.year, today.month, today.day);
    final morningDose = MedicationCalendarEntry(
      dateTime: DateTime(date.year, date.month, date.day, 8),
      doseLabel: '500 mg',
      medicationName: 'Metformin',
      scheduleId: 'schedule-1',
    );
    final eveningDose = MedicationCalendarEntry(
      dateTime: DateTime(date.year, date.month, date.day, 20),
      doseLabel: '1000 IU',
      medicationName: 'Vitamin D',
      scheduleId: 'schedule-2',
    );
    final repository = _FakeMedicationRepository(
      entries: <MedicationCalendarEntry>[morningDose, eveningDose],
    );
    final eventStore = _FakeEventStore(
      events: <EventEnvelope<DomainEvent>>[
        EventEnvelope<DomainEvent>(
          eventId: 'event-1',
          aggregateType: 'medication',
          aggregateId: 'schedule-1',
          actorType: EventActorType.user,
          correlationId: 'corr-1',
          event: DomainEvent(
            type: 'medication_taken',
            payload: <String, Object?>{
              'medication_name': 'Metformin',
              'schedule_id': 'schedule-1',
              'scheduled_for': morningDose.dateTime.toIso8601String(),
              'taken_at': DateTime(
                date.year,
                date.month,
                date.day,
                8,
                5,
              ).toIso8601String(),
            },
          ),
          occurredAt: DateTime(date.year, date.month, date.day, 8, 5),
        ),
      ],
    );

    await tester.pumpWidget(
      AppScope(
        bootstrap: _buildBootstrap(
          eventStore: eventStore,
          medicationRepository: repository,
        ),
        child: MaterialApp(theme: AppTheme.light, home: const TodayScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Today\'s progress'), findsOneWidget);
    expect(find.text('1 of 2 doses recorded today'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'TodayScreen shows adherence insights for recently stopped medications',
    (tester) async {
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      final stoppedOn = date.subtract(const Duration(days: 1));
      final previousDay = date.subtract(const Duration(days: 2));
      final repository = _FakeMedicationRepository(
        entries: const <MedicationCalendarEntry>[],
      );
      final eventStore = _FakeEventStore(
        events: <EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'medication-omeprazole',
            eventId: 'event-medication-registered',
            eventType: 'medication_registered',
            occurredAt: previousDay.subtract(const Duration(days: 21)),
            payload: const <String, Object?>{
              'medication_id': 'medication-omeprazole',
              'medication_name': 'Omeprazole',
            },
          ),
          _event(
            aggregateId: 'schedule-omeprazole',
            eventId: 'event-schedule-added',
            eventType: 'medication_schedule_added',
            occurredAt: previousDay.subtract(const Duration(days: 20)),
            payload: <String, Object?>{
              'medication_id': 'medication-omeprazole',
              'schedule_id': 'schedule-omeprazole',
              'medication_name': 'Omeprazole',
              'dose_amount': '20',
              'dose_unit': 'mg',
              'start_date': previousDay
                  .subtract(const Duration(days: 20))
                  .toIso8601String()
                  .split('T')
                  .first,
              'times': <String>['08:00'],
            },
          ),
          _event(
            aggregateId: 'schedule-omeprazole',
            eventId: 'event-taken-1',
            eventType: 'medication_taken',
            occurredAt: DateTime(
              previousDay.year,
              previousDay.month,
              previousDay.day,
              8,
              5,
            ),
            payload: <String, Object?>{
              'medication_name': 'Omeprazole',
              'schedule_id': 'schedule-omeprazole',
              'scheduled_for': DateTime(
                previousDay.year,
                previousDay.month,
                previousDay.day,
                8,
              ).toIso8601String(),
              'taken_at': DateTime(
                previousDay.year,
                previousDay.month,
                previousDay.day,
                8,
                5,
              ).toIso8601String(),
            },
          ),
          _event(
            aggregateId: 'schedule-omeprazole',
            eventId: 'event-taken-2',
            eventType: 'medication_taken',
            occurredAt: DateTime(
              stoppedOn.year,
              stoppedOn.month,
              stoppedOn.day,
              8,
              5,
            ),
            payload: <String, Object?>{
              'medication_name': 'Omeprazole',
              'schedule_id': 'schedule-omeprazole',
              'scheduled_for': DateTime(
                stoppedOn.year,
                stoppedOn.month,
                stoppedOn.day,
                8,
              ).toIso8601String(),
              'taken_at': DateTime(
                stoppedOn.year,
                stoppedOn.month,
                stoppedOn.day,
                8,
                5,
              ).toIso8601String(),
            },
          ),
          _event(
            aggregateId: 'schedule-omeprazole',
            eventId: 'event-schedule-stopped',
            eventType: 'medication_schedule_stopped',
            occurredAt: DateTime(
              stoppedOn.year,
              stoppedOn.month,
              stoppedOn.day,
              9,
            ),
            payload: <String, Object?>{
              'schedule_id': 'schedule-omeprazole',
              'end_date': stoppedOn.toIso8601String().split('T').first,
            },
          ),
        ],
      );

      await tester.pumpWidget(
        AppScope(
          bootstrap: _buildBootstrap(
            eventStore: eventStore,
            medicationRepository: repository,
          ),
          child: MaterialApp(theme: AppTheme.light, home: const TodayScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Adherence insights'),
        300,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();

      expect(find.text('Adherence insights'), findsOneWidget);
      expect(find.text('Week at a glance'), findsOneWidget);
      expect(find.text('Omeprazole'), findsOneWidget);
      expect(find.text('2-day streak'), findsOneWidget);
    },
  );
}

AppBootstrap _buildBootstrap({
  required EventStore eventStore,
  required MedicationRepository medicationRepository,
}) {
  final conversationRepository = _FakeConversationRepository();
  final modelProvider = _FakeModelProvider();

  return AppBootstrap(
    activityStreamId: 'thread-current',
    aiSettingsController: AiSettingsController(
      repository: const _FakeAiSettingsRepository(),
    ),
    chatCoordinator: ChatCoordinator(
      conversationRepository: conversationRepository,
      eventStore: eventStore,
      medicationRepository: medicationRepository,
      modelProvider: modelProvider,
    ),
    conversationRepository: conversationRepository,
    eventStore: eventStore,
    localDataResetService: const _FakeLocalDataResetService(),
    medicationCommandService: MedicationCommandService(eventStore: eventStore),
    medicationRepository: medicationRepository,
    modelProvider: modelProvider,
    projectionRunner: const _FakeProjectionRunner(),
  );
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: 'medication',
    aggregateId: aggregateId,
    actorType: EventActorType.user,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
  const _FakeAiSettingsRepository();

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearGeminiApiKey() async {}

  @override
  Future<AiSettings> load() async => const AiSettings();

  @override
  Future<String?> loadGeminiApiKey() async => null;

  @override
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord() async => null;

  @override
  Future<AiSettings> save(AiSettings settings) async => settings;

  @override
  Future<void> saveGeminiApiKey(String apiKey) async {}
}

class _FakeLocalDataResetService implements LocalDataResetService {
  const _FakeLocalDataResetService();

  @override
  Future<void> deleteAllLocalData() async {}
}

class _FakeMedicationRepository implements MedicationRepository {
  _FakeMedicationRepository({required this.entries});

  final List<MedicationCalendarEntry> entries;

  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    return const <MedicationScheduleView>[];
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules() {
    return Stream<List<MedicationScheduleView>>.value(
      <MedicationScheduleView>[],
    );
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) {
    return Stream<List<MedicationCalendarEntry>>.value(entries);
  }
}

class _FakeConversationRepository implements ConversationRepository {
  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    return const <ConversationMessageView>[];
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    return null;
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) {
    return Stream<List<ConversationMessageView>>.value(
      <ConversationMessageView>[],
    );
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) {
    return Stream<ProposalView?>.value(null);
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() {
    return Stream<List<ConversationThreadView>>.value(
      <ConversationThreadView>[],
    );
  }
}

class _FakeEventStore implements EventStore {
  _FakeEventStore({required this.events});

  final List<EventEnvelope<DomainEvent>> events;

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> newEvents) async {}

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async => events;

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(events);
  }
}

class _FakeModelProvider implements ModelProvider {
  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    return const ModelResponseContract(
      actions: <ModelProposalAction>[],
      assistantText: '',
      rawPayload: <String, Object?>{},
    );
  }
}

class _FakeProjectionRunner implements ProjectionRunner {
  const _FakeProjectionRunner();

  @override
  Future<void> rebuild() async {}
}
