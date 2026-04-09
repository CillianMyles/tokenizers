import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/drift_workspace.dart';
import 'package:tokenizers/src/data/gemini_model_provider.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';

/// Bundles the app's core services and repositories.
class AppBootstrap {
  /// Creates an app bootstrap.
  const AppBootstrap({
    required this.activityStreamId,
    required this.chatCoordinator,
    required this.configurationError,
    required this.conversationRepository,
    required this.eventStore,
    required this.medicationCommandService,
    required this.medicationRepository,
    required this.modelProvider,
    required this.projectionRunner,
  });

  final String activityStreamId;
  final ChatCoordinator chatCoordinator;
  final String? configurationError;
  final ConversationRepository conversationRepository;
  final EventStore eventStore;
  final MedicationCommandService medicationCommandService;
  final MedicationRepository medicationRepository;
  final ModelProvider modelProvider;
  final ProjectionRunner projectionRunner;
}

/// Creates the application bootstrap used by the v0 shell.
Future<AppBootstrap> createDemoAppBootstrap() async {
  const activityStreamId = 'thread-current';
  final configurationError = _configurationError();
  final modelProvider = _createModelProvider(configurationError);

  final database = AppDatabase();
  final eventStore = DriftEventStore(database: database);
  final medicationCommandService = MedicationCommandService(
    eventStore: eventStore,
  );
  final workspace = DriftWorkspace(database: database, eventStore: eventStore);
  await workspace.rebuild();

  return AppBootstrap(
    activityStreamId: activityStreamId,
    chatCoordinator: ChatCoordinator(
      conversationRepository: workspace,
      eventStore: eventStore,
      medicationRepository: workspace,
      modelProvider: modelProvider,
    ),
    configurationError: configurationError,
    conversationRepository: workspace,
    eventStore: eventStore,
    medicationCommandService: medicationCommandService,
    medicationRepository: workspace,
    modelProvider: modelProvider,
    projectionRunner: workspace,
  );
}

String? _configurationError() {
  if (Env.geminiApiKey.isNotEmpty) {
    return null;
  }
  return 'Missing GEMINI_API_KEY in your local .env. Copy .env.example to '
      '.env, add your Gemini key, and relaunch the app.';
}

ModelProvider _createModelProvider(String? configurationError) {
  if (configurationError != null) {
    return _MissingConfigurationModelProvider(message: configurationError);
  }
  return GeminiModelProvider(apiKey: Env.geminiApiKey);
}

final class _MissingConfigurationModelProvider implements ModelProvider {
  const _MissingConfigurationModelProvider({required this.message});

  final String message;

  @override
  Future<ModelResponseContract> generateResponse({
    required List activeSchedules,
    required List conversation,
    required String threadId,
    required String userText,
  }) {
    throw StateError(message);
  }
}
