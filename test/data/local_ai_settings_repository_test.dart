import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/data/local_ai_settings_repository.dart';
import 'package:tokenizers/src/data/platform_api_key_store.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalAiSettingsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('stores non-sensitive settings in shared preferences', () async {
      final preferences = await SharedPreferences.getInstance();
      final apiKeyStore = _InMemoryApiKeyStore(
        kind: ApiKeyStorageKind.secureStorage,
      );
      final repository = LocalAiSettingsRepository(
        apiKeyStore: apiKeyStore,
        preferences: preferences,
      );

      await repository.save(
        const AiSettings(geminiModel: GeminiModel.gemini3FlashPreview),
      );

      expect(
        preferences.getString('ai_settings.gemini_model'),
        'gemini-3-flash-preview',
      );
      expect(preferences.getString('ai_settings.provider'), 'gemini');
      expect(preferences.containsKey('ai_settings.gemini_api_key'), isFalse);
    });

    test('reports a debug env key source from the adapter', () async {
      final preferences = await SharedPreferences.getInstance();
      final repository = LocalAiSettingsRepository(
        apiKeyStore: const DebugApiKeyStore(readValue: _readDebugApiKey),
        preferences: preferences,
      );

      final settings = await repository.load();
      final apiKey = await repository.loadGeminiApiKey();

      expect(settings.apiKeySource, ApiKeySource.debugEnv);
      expect(settings.hasApiKey, isTrue);
      expect(apiKey, 'debug-key');
    });

    test('prefers a saved device key over the debug env fallback', () async {
      final preferences = await SharedPreferences.getInstance();
      final primaryStore = _InMemoryApiKeyStore(
        kind: ApiKeyStorageKind.secureStorage,
      );
      await primaryStore.write('saved-key');
      final repository = LocalAiSettingsRepository(
        apiKeyStore: FallbackApiKeyStore(
          fallback: const DebugApiKeyStore(readValue: _readDebugApiKey),
          primary: primaryStore,
        ),
        preferences: preferences,
      );

      final settings = await repository.load();
      final apiKey = await repository.loadGeminiApiKey();

      expect(settings.apiKeySource, ApiKeySource.stored);
      expect(apiKey, 'saved-key');
    });
  });
}

String? _readDebugApiKey() => 'debug-key';

class _InMemoryApiKeyStore implements ApiKeyStore {
  _InMemoryApiKeyStore({required this.kind});

  @override
  final ApiKeyStorageKind kind;
  String? _value;

  @override
  Future<void> delete() async {
    _value = null;
  }

  @override
  Future<ApiKeyRecord?> read() async {
    if (_value == null) {
      return null;
    }
    return ApiKeyRecord(source: ApiKeySource.stored, value: _value!);
  }

  @override
  Future<void> write(String value) async {
    _value = value;
  }
}
