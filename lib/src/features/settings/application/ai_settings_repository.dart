import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Loads and persists user-configurable AI settings.
abstract interface class AiSettingsRepository {
  /// Removes all persisted AI settings and any stored Gemini API key.
  Future<void> clearAll();

  /// Loads the stored AI settings snapshot.
  Future<AiSettings> load();

  /// Persists non-sensitive AI settings.
  Future<AiSettings> save(AiSettings settings);

  /// Loads the stored Gemini API key, if present.
  Future<String?> loadGeminiApiKey();

  /// Loads the stored Gemini API key together with its source metadata.
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord();

  /// Persists the Gemini API key.
  Future<void> saveGeminiApiKey(String apiKey);

  /// Removes the stored Gemini API key.
  Future<void> clearGeminiApiKey();
}
