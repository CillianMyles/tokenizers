import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/drift_workspace.dart';
import 'package:tokenizers/src/data/local_ai_settings_repository.dart';
import 'package:tokenizers/src/data/platform_api_key_store.dart';
import 'package:tokenizers/src/data/settings_backed_model_provider.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';

/// Bundles the app's core services and repositories.
class AppBootstrap {
  /// Creates an app bootstrap.
  const AppBootstrap({
    required this.activityStreamId,
    required this.aiSettingsController,
    required this.chatCoordinator,
    required this.conversationRepository,
    required this.eventStore,
    required this.medicationCommandService,
    required this.medicationRepository,
    required this.modelProvider,
    required this.projectionRunner,
  });

  final String activityStreamId;
  final AiSettingsController aiSettingsController;
  final ChatCoordinator chatCoordinator;
  final ConversationRepository conversationRepository;
  final EventStore eventStore;
  final MedicationCommandService medicationCommandService;
  final MedicationRepository medicationRepository;
  final ModelProvider modelProvider;
  final ProjectionRunner projectionRunner;

  /// Explains why live assistant requests are unavailable.
  String? get configurationError => aiSettingsController.configurationError;
}

/// Creates the application bootstrap used by the v0 shell.
Future<AppBootstrap> createDemoAppBootstrap() async {
  const activityStreamId = 'thread-current';
  final sharedPreferences = await SharedPreferences.getInstance();
  final aiSettingsController = AiSettingsController(
    repository: LocalAiSettingsRepository(
      apiKeyStore: FallbackApiKeyStore(
        fallback: DebugApiKeyStore(readValue: () => Env.geminiApiKey),
        primary: createPlatformApiKeyStore(preferences: sharedPreferences),
      ),
      preferences: sharedPreferences,
    ),
  );
  await aiSettingsController.load();
  final modelProvider = SettingsBackedModelProvider(
    settingsController: aiSettingsController,
  );

  final database = AppDatabase();
  final eventStore = DriftEventStore(database: database);
  final medicationCommandService = MedicationCommandService(
    eventStore: eventStore,
  );
  final workspace = DriftWorkspace(database: database, eventStore: eventStore);
  await workspace.rebuild();

  return AppBootstrap(
    activityStreamId: activityStreamId,
    aiSettingsController: aiSettingsController,
    chatCoordinator: ChatCoordinator(
      conversationRepository: workspace,
      eventStore: eventStore,
      medicationRepository: workspace,
      modelProvider: modelProvider,
    ),
    conversationRepository: workspace,
    eventStore: eventStore,
    medicationCommandService: medicationCommandService,
    medicationRepository: workspace,
    modelProvider: modelProvider,
    projectionRunner: workspace,
  );
}
