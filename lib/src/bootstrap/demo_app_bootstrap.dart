import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/app/theme_mode_controller.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/device_local_data_reset_service.dart';
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
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';

/// Bundles the app's core services and repositories.
class AppBootstrap {
  /// Creates an app bootstrap.
  const AppBootstrap({
    required this.activityStreamId,
    required this.aiSettingsController,
    required this.chatCoordinator,
    required this.conversationRepository,
    required this.eventStore,
    required this.localDataResetService,
    required this.medicationCommandService,
    required this.medicationRepository,
    required this.modelProvider,
    required this.projectionRunner,
    required this.themeModeController,
  });

  final String activityStreamId;
  final AiSettingsController aiSettingsController;
  final ChatCoordinator chatCoordinator;
  final ConversationRepository conversationRepository;
  final EventStore eventStore;
  final LocalDataResetService localDataResetService;
  final MedicationCommandService medicationCommandService;
  final MedicationRepository medicationRepository;
  final ModelProvider modelProvider;
  final ProjectionRunner projectionRunner;
  final ThemeModeController themeModeController;

  /// Explains why live assistant requests are unavailable.
  String? get configurationError => aiSettingsController.configurationError;
}

/// Creates the application bootstrap used by the v0 shell.
Future<AppBootstrap> createDemoAppBootstrap() async {
  const activityStreamId = 'thread-current';
  final sharedPreferences = await SharedPreferences.getInstance();
  final writableApiKeyStore = createPlatformApiKeyStore(
    preferences: sharedPreferences,
  );
  final aiSettingsRepository = LocalAiSettingsRepository(
    apiKeyStore: FallbackApiKeyStore(
      fallback: DebugApiKeyStore(readValue: () => Env.geminiApiKey),
      primary: writableApiKeyStore,
    ),
    preferences: sharedPreferences,
  );
  final themeModeController = ThemeModeController(
    preferences: sharedPreferences,
  );
  final aiSettingsController = AiSettingsController(
    repository: aiSettingsRepository,
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
  final chatCoordinator = ChatCoordinator(
    conversationRepository: workspace,
    eventStore: eventStore,
    medicationRepository: workspace,
    modelProvider: modelProvider,
  );

  return AppBootstrap(
    activityStreamId: activityStreamId,
    aiSettingsController: aiSettingsController,
    chatCoordinator: chatCoordinator,
    conversationRepository: workspace,
    eventStore: eventStore,
    localDataResetService: DeviceLocalDataResetService(
      database: database,
      resetGuard: chatCoordinator,
      settingsRepository: aiSettingsRepository,
    ),
    medicationCommandService: medicationCommandService,
    medicationRepository: workspace,
    modelProvider: modelProvider,
    projectionRunner: workspace,
    themeModeController: themeModeController,
  );
}
