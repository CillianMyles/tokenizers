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
import 'package:tokenizers/src/features/calendar/presentation/medication_calendar_screen.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  testWidgets(
    'MedicationCalendarScreen uses the injected current date for initial and '
    'reset state',
    (tester) async {
      final repository = _FakeMedicationRepository();
      final bootstrap = _buildBootstrap(repository);
      final injectedNow = DateTime(2026, 4, 9, 17, 45);
      final today = DateUtils.dateOnly(injectedNow);
      final previousDay = today.subtract(const Duration(days: 1));

      await tester.pumpWidget(
        AppScope(
          bootstrap: bootstrap,
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: MedicationCalendarScreen(currentDate: () => injectedNow),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Thursday, April 9'), findsOneWidget);
      expect(repository.requestedDays, isNotEmpty);
      expect(repository.requestedDays.last, today);

      final initialRequestCount = repository.requestedDays.length;
      await tester.tap(find.byTooltip('Previous day'));
      await tester.pumpAndSettle();

      expect(find.text('Wednesday, April 8'), findsOneWidget);
      expect(repository.requestedDays.length, greaterThan(initialRequestCount));
      expect(repository.requestedDays.last, previousDay);

      final requestCountAfterPrevious = repository.requestedDays.length;
      await tester.tap(find.text('Wednesday, April 8'));
      await tester.pumpAndSettle();

      expect(find.text('Thursday, April 9'), findsOneWidget);
      expect(
        repository.requestedDays.length,
        greaterThan(requestCountAfterPrevious),
      );
      expect(repository.requestedDays.last, today);
    },
  );
}

AppBootstrap _buildBootstrap(_FakeMedicationRepository medicationRepository) {
  final eventStore = _FakeEventStore();
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
    medicationCommandService: MedicationCommandService(eventStore: eventStore),
    medicationRepository: medicationRepository,
    modelProvider: modelProvider,
    projectionRunner: const _FakeProjectionRunner(),
  );
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
  const _FakeAiSettingsRepository();

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

class _FakeMedicationRepository implements MedicationRepository {
  final List<DateTime> requestedDays = <DateTime>[];

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
    requestedDays.add(DateUtils.dateOnly(day));
    return Stream<List<MedicationCalendarEntry>>.value(
      <MedicationCalendarEntry>[],
    );
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
  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events) async {}

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    return const <EventEnvelope<DomainEvent>>[];
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(
      <EventEnvelope<DomainEvent>>[],
    );
  }
}

class _FakeModelProvider implements ModelProvider {
  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
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
