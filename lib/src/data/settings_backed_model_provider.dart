import 'package:http/http.dart' as http;
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/gemini_model_provider.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Resolves the active model provider from the current saved AI settings.
class SettingsBackedModelProvider implements ModelProvider {
  /// Creates a settings-backed model provider.
  SettingsBackedModelProvider({
    required AiSettingsController settingsController,
    http.Client? client,
  }) : _settingsController = settingsController,
       _client = client ?? http.Client();

  final AiSettingsController _settingsController;
  final http.Client _client;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) {
    final settings = _settingsController.settings;
    final geminiApiKey = _settingsController.geminiApiKey;

    if (settings.provider != AiProvider.gemini) {
      throw StateError('Unsupported AI provider: ${settings.provider.name}.');
    }

    if (geminiApiKey == null || geminiApiKey.isEmpty) {
      throw StateError(
        settings.configurationError ??
            'Add a Gemini API key in Settings to use the assistant.',
      );
    }

    return GeminiModelProvider(
      apiKey: geminiApiKey,
      client: _client,
      model: settings.geminiModel.apiModelName,
      schedulePreferences: settings.medicationSchedulePreferences,
    ).generateResponse(
      confirmedSchedules: confirmedSchedules,
      conversation: conversation,
      threadId: threadId,
      userText: userText,
      imageAttachment: imageAttachment,
    );
  }
}
