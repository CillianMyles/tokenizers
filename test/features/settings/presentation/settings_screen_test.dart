import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/app/theme_mode_controller.dart';
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
import 'package:tokenizers/src/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets(
    'SettingsScreen requires typing delete before local data can be removed',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final settingsRepository = _FakeAiSettingsRepository();
      final settingsController = AiSettingsController(
        repository: settingsRepository,
      );
      final resetService = _RecordingLocalDataResetService();
      final bootstrap = await _buildBootstrap(
        localDataResetService: resetService,
        settingsController: settingsController,
      );

      await settingsController.load();

      await tester.pumpWidget(
        AppScope(
          bootstrap: bootstrap,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Danger Zone'), findsOneWidget);

      await tester.tap(
        find.widgetWithIcon(FilledButton, Icons.delete_forever_outlined),
      );
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      final dialogDeleteButton = find.descendant(
        of: dialog,
        matching: find.widgetWithText(FilledButton, 'Delete Data'),
      );

      expect(dialog, findsOneWidget);
      expect(tester.widget<FilledButton>(dialogDeleteButton).onPressed, isNull);

      await tester.enterText(
        find.descendant(of: dialog, matching: find.byType(TextField)),
        'delete',
      );
      await tester.pump();

      expect(
        tester.widget<FilledButton>(dialogDeleteButton).onPressed,
        isNotNull,
      );

      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(resetService.deleteCallCount, 1);
      expect(find.text('All local data has been deleted.'), findsOneWidget);
    },
  );
}

Future<AppBootstrap> _buildBootstrap({
  required LocalDataResetService localDataResetService,
  required AiSettingsController settingsController,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final eventStore = _FakeEventStore();
  final conversationRepository = _FakeConversationRepository();
  final medicationRepository = _FakeMedicationRepository();
  final modelProvider = _FakeModelProvider();

  return AppBootstrap(
    activityStreamId: 'thread-current',
    aiSettingsController: settingsController,
    chatCoordinator: ChatCoordinator(
      conversationRepository: conversationRepository,
      eventStore: eventStore,
      medicationRepository: medicationRepository,
      modelProvider: modelProvider,
    ),
    conversationRepository: conversationRepository,
    eventStore: eventStore,
    localDataResetService: localDataResetService,
    medicationCommandService: MedicationCommandService(eventStore: eventStore),
    medicationRepository: medicationRepository,
    modelProvider: modelProvider,
    projectionRunner: const _FakeProjectionRunner(),
    themeModeController: ThemeModeController(preferences: prefs),
  );
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
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

class _RecordingLocalDataResetService implements LocalDataResetService {
  int deleteCallCount = 0;

  @override
  Future<void> deleteAllLocalData() async {
    deleteCallCount += 1;
  }
}

class _FakeMedicationRepository implements MedicationRepository {
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
