import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

const _providerPreferenceKey = 'ai_settings.provider';
const _geminiModelPreferenceKey = 'ai_settings.gemini_model';

/// Shared-preferences-backed repository for user AI settings.
class LocalAiSettingsRepository implements AiSettingsRepository {
  /// Creates a local AI settings repository.
  const LocalAiSettingsRepository({
    required ApiKeyStore apiKeyStore,
    required SharedPreferences preferences,
  }) : _apiKeyStore = apiKeyStore,
       _preferences = preferences;

  final ApiKeyStore _apiKeyStore;
  final SharedPreferences _preferences;

  @override
  Future<void> clearGeminiApiKey() => _apiKeyStore.delete();

  @override
  Future<AiSettings> load() async {
    final provider = _providerFromWireValue(
      _preferences.getString(_providerPreferenceKey),
    );
    final geminiModel = _geminiModelFromWireValue(
      _preferences.getString(_geminiModelPreferenceKey),
    );
    final apiKeyRecord = await loadGeminiApiKeyRecord();

    return AiSettings(
      apiKeySource: apiKeyRecord?.source ?? ApiKeySource.none,
      apiKeyStorage: _apiKeyStore.kind,
      geminiModel: geminiModel,
      provider: provider,
    );
  }

  @override
  Future<String?> loadGeminiApiKey() async {
    return (await _apiKeyStore.read())?.value;
  }

  @override
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord() => _apiKeyStore.read();

  @override
  Future<AiSettings> save(AiSettings settings) async {
    await _preferences.setString(
      _providerPreferenceKey,
      settings.provider.wireValue,
    );
    await _preferences.setString(
      _geminiModelPreferenceKey,
      settings.geminiModel.wireValue,
    );
    return settings.copyWith(apiKeyStorage: _apiKeyStore.kind);
  }

  @override
  Future<void> saveGeminiApiKey(String apiKey) => _apiKeyStore.write(apiKey);

  AiProvider _providerFromWireValue(String? wireValue) {
    return AiProvider.values.firstWhere(
      (provider) => provider.wireValue == wireValue,
      orElse: () => AiProvider.gemini,
    );
  }

  GeminiModel _geminiModelFromWireValue(String? wireValue) {
    return GeminiModel.values.firstWhere(
      (model) => model.wireValue == wireValue,
      orElse: () => GeminiModel.gemini25Flash,
    );
  }
}
