import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/core/domain/medication_schedule_preferences.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

const _providerPreferenceKey = 'ai_settings.provider';
const _geminiModelPreferenceKey = 'ai_settings.gemini_model';
const _morningTimePreferenceKey = 'ai_settings.medication_time.morning';
const _lunchTimePreferenceKey = 'ai_settings.medication_time.lunch';
const _eveningTimePreferenceKey = 'ai_settings.medication_time.evening';

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
  Future<void> clearAll() async {
    await _removePreference(_providerPreferenceKey);
    await _removePreference(_geminiModelPreferenceKey);
    await _removePreference(_morningTimePreferenceKey);
    await _removePreference(_lunchTimePreferenceKey);
    await _removePreference(_eveningTimePreferenceKey);
    await _apiKeyStore.delete();
  }

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
    final medicationSchedulePreferences = MedicationSchedulePreferences(
      eveningTime:
          _preferences.getString(_eveningTimePreferenceKey) ??
          MedicationSchedulePreferences.defaultEveningTime,
      lunchTime:
          _preferences.getString(_lunchTimePreferenceKey) ??
          MedicationSchedulePreferences.defaultLunchTime,
      morningTime:
          _preferences.getString(_morningTimePreferenceKey) ??
          MedicationSchedulePreferences.defaultMorningTime,
    ).normalized();
    final apiKeyRecord = await loadGeminiApiKeyRecord();

    return AiSettings(
      apiKeySource: apiKeyRecord?.source ?? ApiKeySource.none,
      apiKeyStorage: _apiKeyStore.kind,
      geminiModel: geminiModel,
      medicationSchedulePreferences: medicationSchedulePreferences,
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
    final providerSaved = await _preferences.setString(
      _providerPreferenceKey,
      settings.provider.wireValue,
    );
    final modelSaved = await _preferences.setString(
      _geminiModelPreferenceKey,
      settings.geminiModel.wireValue,
    );
    final normalizedPreferences = settings.medicationSchedulePreferences
        .normalized();
    final morningSaved = await _preferences.setString(
      _morningTimePreferenceKey,
      normalizedPreferences.morningTime,
    );
    final lunchSaved = await _preferences.setString(
      _lunchTimePreferenceKey,
      normalizedPreferences.lunchTime,
    );
    final eveningSaved = await _preferences.setString(
      _eveningTimePreferenceKey,
      normalizedPreferences.eveningTime,
    );
    if (!providerSaved ||
        !modelSaved ||
        !morningSaved ||
        !lunchSaved ||
        !eveningSaved) {
      throw StateError('Could not persist the AI settings.');
    }
    return settings.copyWith(
      apiKeyStorage: _apiKeyStore.kind,
      medicationSchedulePreferences: normalizedPreferences,
    );
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

  Future<void> _removePreference(String key) async {
    if (!_preferences.containsKey(key)) {
      return;
    }

    final removed = await _preferences.remove(key);
    if (!removed) {
      throw StateError('Could not remove the AI setting "$key".');
    }
  }
}
