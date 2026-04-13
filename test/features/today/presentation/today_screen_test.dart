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
