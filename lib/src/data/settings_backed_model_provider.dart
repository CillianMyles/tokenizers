import 'package:http/http.dart' as http;
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/gemini_model_provider.dart';
import 'package:tokenizers/src/data/local_gemma_model_provider.dart';
import 'package:tokenizers/src/data/local_gemma_service.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Resolves the active model provider from the current saved AI settings.
class SettingsBackedModelProvider implements ModelProvider {
  /// Creates a settings-backed model provider.
  SettingsBackedModelProvider({
    required AiSettingsController settingsController,
    LocalGemmaService? localGemmaService,
    http.Client? client,
  }) : _settingsController = settingsController,
       _localGemmaService = localGemmaService,
       _client = client ?? http.Client();

  final LocalGemmaService? _localGemmaService;
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

    return switch (settings.provider) {
      AiProvider.gemini =>
        _buildGeminiProvider(
          geminiApiKey: geminiApiKey,
          settings: settings,
        ).generateResponse(
          confirmedSchedules: confirmedSchedules,
          conversation: conversation,
          threadId: threadId,
          userText: userText,
          imageAttachment: imageAttachment,
        ),
      AiProvider.localGemma =>
        _buildLocalGemmaProvider(settings).generateResponse(
          confirmedSchedules: confirmedSchedules,
          conversation: conversation,
          threadId: threadId,
          userText: userText,
          imageAttachment: imageAttachment,
        ),
    };
  }

  GeminiModelProvider _buildGeminiProvider({
    required String? geminiApiKey,
    required AiSettings settings,
  }) {
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
    );
  }

  LocalGemmaModelProvider _buildLocalGemmaProvider(AiSettings settings) {
    final service = _localGemmaService;
    if (service == null) {
      throw StateError(
        'Offline Gemma support is not configured in this app bootstrap.',
      );
    }

    return LocalGemmaModelProvider(
      model: settings.localModel,
      service: service,
    );
  }
}
