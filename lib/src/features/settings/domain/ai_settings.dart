/// The currently supported cloud AI providers.
enum AiProvider { gemini }

extension AiProviderWireValue on AiProvider {
  /// Stable storage value for the provider.
  String get wireValue => switch (this) {
    AiProvider.gemini => 'gemini',
  };

  /// Human-readable label for the provider.
  String get label => switch (this) {
    AiProvider.gemini => 'Gemini',
  };
}

/// The Gemini models currently exposed in the settings UI.
enum GeminiModel { gemini25Flash, gemini3FlashPreview }

extension GeminiModelMetadata on GeminiModel {
  /// Stable storage value for the model selection.
  String get wireValue => switch (this) {
    GeminiModel.gemini25Flash => 'gemini-2.5-flash',
    GeminiModel.gemini3FlashPreview => 'gemini-3-flash-preview',
  };

  /// The model id used in Gemini API requests.
  String get apiModelName => wireValue;

  /// Human-readable label for the settings UI.
  String get label => switch (this) {
    GeminiModel.gemini25Flash => '2.5 Flash',
    GeminiModel.gemini3FlashPreview => '3 Flash Preview',
  };

  /// Short copy explaining the tradeoff of the selected model.
  String get description => switch (this) {
    GeminiModel.gemini25Flash => 'Stable default for fast scheduling.',
    GeminiModel.gemini3FlashPreview => 'Newer reasoning capabilities.',
  };
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
    this.provider = AiProvider.gemini,
  });

  /// Where the active Gemini API key came from.
  final ApiKeySource apiKeySource;

  /// Storage adapter used for the Gemini API key.
  final ApiKeyStorageKind apiKeyStorage;

  /// Selected Gemini model.
  final GeminiModel geminiModel;

  /// Selected AI provider.
  final AiProvider provider;

  /// Whether the assistant can make live model requests.
  bool get isConfigured => apiKeySource != ApiKeySource.none;

  /// Whether a Gemini key is currently available.
  bool get hasApiKey => isConfigured;

  /// Explains why the assistant is unavailable.
  String? get configurationError {
    if (isConfigured) {
      return null;
    }
    return 'Add a Gemini API key in Settings to use the assistant.';
  }

  /// Returns a copy with specific fields updated.
  AiSettings copyWith({
    ApiKeySource? apiKeySource,
    ApiKeyStorageKind? apiKeyStorage,
    GeminiModel? geminiModel,
    AiProvider? provider,
  }) {
    return AiSettings(
      apiKeySource: apiKeySource ?? this.apiKeySource,
      apiKeyStorage: apiKeyStorage ?? this.apiKeyStorage,
      geminiModel: geminiModel ?? this.geminiModel,
      provider: provider ?? this.provider,
    );
  }
}
