import 'package:flutter/foundation.dart';

/// The currently supported cloud AI providers.
enum AiProvider { gemini, localGemma }

extension AiProviderWireValue on AiProvider {
  /// Stable storage value for the provider.
  String get wireValue => switch (this) {
    AiProvider.gemini => 'gemini',
    AiProvider.localGemma => 'local_gemma',
  };

  /// Human-readable label for the provider.
  String get label => switch (this) {
    AiProvider.gemini => 'Gemini',
    AiProvider.localGemma => 'Offline Gemma 4',
  };

  /// Short copy explaining how the provider runs.
  String get description => switch (this) {
    AiProvider.gemini =>
      'Cloud-hosted Gemini with your API key and model selection.',
    AiProvider.localGemma =>
      'Run a Gemma 4 model on-device after downloading it once.',
  };
}

/// The Gemini models currently exposed in the settings UI.
enum GeminiModel { gemini25Flash, gemini3FlashPreview, gemini31ProPreview }

extension GeminiModelMetadata on GeminiModel {
  /// Stable storage value for the model selection.
  String get wireValue => switch (this) {
    GeminiModel.gemini25Flash => 'gemini-2.5-flash',
    GeminiModel.gemini3FlashPreview => 'gemini-3-flash-preview',
    GeminiModel.gemini31ProPreview => 'gemini-3.1-pro-preview',
  };

  /// The model id used in Gemini API requests.
  String get apiModelName => wireValue;

  /// Human-readable label for the settings UI.
  String get label => switch (this) {
    GeminiModel.gemini25Flash => '2.5 Flash',
    GeminiModel.gemini3FlashPreview => '3 Flash',
    GeminiModel.gemini31ProPreview => '3.1 Pro',
  };

  /// Short copy explaining the tradeoff of the selected model.
  String get description => switch (this) {
    GeminiModel.gemini25Flash => 'Stable default for fast scheduling.',
    GeminiModel.gemini3FlashPreview => 'Newer reasoning capabilities.',
    GeminiModel.gemini31ProPreview => 'Best multimodal reasoning.',
  };
}

/// Local Gemma 4 presets exposed in Settings.
enum LocalGemmaModel { gemma4E2bIt, gemma4E4bIt }

extension LocalGemmaModelMetadata on LocalGemmaModel {
  /// Stable storage value for the local model selection.
  String get wireValue => switch (this) {
    LocalGemmaModel.gemma4E2bIt => 'gemma-4-e2b-it',
    LocalGemmaModel.gemma4E4bIt => 'gemma-4-e4b-it',
  };

  /// Human-readable label for the settings UI.
  String get label => switch (this) {
    LocalGemmaModel.gemma4E2bIt => 'Gemma 4 E2B',
    LocalGemmaModel.gemma4E4bIt => 'Gemma 4 E4B',
  };

  /// Short copy explaining the tradeoff of the selected model.
  String get description => switch (this) {
    LocalGemmaModel.gemma4E2bIt =>
      'Recommended default. Smaller download and faster local inference.',
    LocalGemmaModel.gemma4E4bIt =>
      'Larger Gemma 4 checkpoint with more headroom for complex prompts.',
  };

  /// Friendly size label for the settings UI.
  String get sizeLabel => switch (this) {
    LocalGemmaModel.gemma4E2bIt => '~2.4 GB',
    LocalGemmaModel.gemma4E4bIt => '~4.3 GB',
  };

  /// Hugging Face repository path for this preset.
  String get repositoryPath => switch (this) {
    LocalGemmaModel.gemma4E2bIt => 'litert-community/gemma-4-E2B-it-litert-lm',
    LocalGemmaModel.gemma4E4bIt => 'litert-community/gemma-4-E4B-it-litert-lm',
  };

  /// Model filename for native platforms using LiteRT-LM.
  String get nativeFileName => switch (this) {
    LocalGemmaModel.gemma4E2bIt => 'gemma-4-E2B-it.litertlm',
    LocalGemmaModel.gemma4E4bIt => 'gemma-4-E4B-it.litertlm',
  };

  /// Model filename for browsers using the web task format.
  String get webFileName => switch (this) {
    LocalGemmaModel.gemma4E2bIt => 'gemma-4-E2B-it-web.task',
    LocalGemmaModel.gemma4E4bIt => 'gemma-4-E4B-it-web.task',
  };

  /// Platform-specific file name used for storage and downloads.
  String get fileName => kIsWeb ? webFileName : nativeFileName;

  /// Stable identifier used when activating or deleting the installed model.
  String get modelId => fileName.split('.').first;

  /// Public Hugging Face page for this preset.
  Uri get repositoryUri => Uri.https('huggingface.co', '/$repositoryPath');

  /// Direct download URL used by the local installer.
  Uri get downloadUri =>
      Uri.https('huggingface.co', '/$repositoryPath/resolve/main/$fileName');
}

/// Where the current platform stores sensitive API keys.
enum ApiKeyStorageKind { secureStorage, sharedPreferencesFallback }

extension ApiKeyStorageKindMetadata on ApiKeyStorageKind {
  /// Human-readable storage label for the settings UI.
  String get label => switch (this) {
    ApiKeyStorageKind.secureStorage => 'Secure storage',
    ApiKeyStorageKind.sharedPreferencesFallback =>
      'Shared preferences fallback',
  };

  /// Describes the protection level for the active storage adapter.
  String get description => switch (this) {
    ApiKeyStorageKind.secureStorage =>
      'This platform uses OS-backed secure storage for the Gemini key.',
    ApiKeyStorageKind.sharedPreferencesFallback =>
      'This platform falls back to shared preferences for the Gemini key.',
  };
}

/// Where the currently active Gemini API key came from.
enum ApiKeySource { none, stored, debugEnv }

extension ApiKeySourceMetadata on ApiKeySource {
  /// Human-readable source label for the settings UI.
  String get label => switch (this) {
    ApiKeySource.none => 'No key stored',
    ApiKeySource.stored => 'Saved on this device',
    ApiKeySource.debugEnv => 'Loaded from debug .env',
  };
}

/// Snapshot of the user-configurable AI settings.
class AiSettings {
  /// Creates an AI settings snapshot.
  const AiSettings({
    this.apiKeySource = ApiKeySource.none,
    this.apiKeyStorage = ApiKeyStorageKind.secureStorage,
    this.geminiModel = GeminiModel.gemini25Flash,
    this.localModel = LocalGemmaModel.gemma4E2bIt,
    this.provider = AiProvider.gemini,
  });

  /// Where the active Gemini API key came from.
  final ApiKeySource apiKeySource;

  /// Storage adapter used for the Gemini API key.
  final ApiKeyStorageKind apiKeyStorage;

  /// Selected Gemini model.
  final GeminiModel geminiModel;

  /// Selected on-device Gemma model.
  final LocalGemmaModel localModel;

  /// Selected AI provider.
  final AiProvider provider;

  /// Whether the assistant can make live model requests.
  bool get isConfigured => switch (provider) {
    AiProvider.gemini => apiKeySource != ApiKeySource.none,
    AiProvider.localGemma => true,
  };

  /// Whether a Gemini key is currently available.
  bool get hasApiKey => isConfigured;

  /// Explains why the assistant is unavailable.
  String? get configurationError {
    return switch (provider) {
      AiProvider.gemini when isConfigured => null,
      AiProvider.gemini =>
        'Add a Gemini API key in Settings to use the assistant.',
      AiProvider.localGemma => null,
    };
  }

  /// Returns a copy with specific fields updated.
  AiSettings copyWith({
    ApiKeySource? apiKeySource,
    ApiKeyStorageKind? apiKeyStorage,
    GeminiModel? geminiModel,
    LocalGemmaModel? localModel,
    AiProvider? provider,
  }) {
    return AiSettings(
      apiKeySource: apiKeySource ?? this.apiKeySource,
      apiKeyStorage: apiKeyStorage ?? this.apiKeyStorage,
      geminiModel: geminiModel ?? this.geminiModel,
      localModel: localModel ?? this.localModel,
      provider: provider ?? this.provider,
    );
  }
}
