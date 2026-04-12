import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

const _geminiApiKeyStorageKey = 'ai_settings.gemini_api_key';

/// Builds the API key storage adapter for the current platform.
ApiKeyStore createPlatformApiKeyStore({
  required SharedPreferences preferences,
  FlutterSecureStorage? secureStorage,
}) {
  if (kIsWeb) {
    return SharedPreferencesApiKeyStore(preferences: preferences);
  }

  return SecureStorageApiKeyStore(
    storage: secureStorage ?? const FlutterSecureStorage(),
  );
}

/// Stores API keys in OS-backed secure storage.
class SecureStorageApiKeyStore implements ApiKeyStore {
  /// Creates a secure-storage API key store.
  const SecureStorageApiKeyStore({required FlutterSecureStorage storage})
    : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  ApiKeyStorageKind get kind => ApiKeyStorageKind.secureStorage;

  @override
  Future<void> delete() => _storage.delete(key: _geminiApiKeyStorageKey);

  @override
  Future<ApiKeyRecord?> read() async {
    final value = await _storage.read(key: _geminiApiKeyStorageKey);
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return ApiKeyRecord(source: ApiKeySource.stored, value: trimmed);
  }

  @override
  Future<void> write(String value) {
    return _storage.write(key: _geminiApiKeyStorageKey, value: value.trim());
  }
}

/// Stores API keys in shared preferences when secure storage is unavailable.
class SharedPreferencesApiKeyStore implements ApiKeyStore {
  /// Creates a shared-preferences API key store.
  const SharedPreferencesApiKeyStore({required SharedPreferences preferences})
    : _preferences = preferences;

  final SharedPreferences _preferences;

  @override
  ApiKeyStorageKind get kind => ApiKeyStorageKind.sharedPreferencesFallback;

  @override
  Future<void> delete() async {
    await _preferences.remove(_geminiApiKeyStorageKey);
  }

  @override
  Future<ApiKeyRecord?> read() async {
    final value = _preferences.getString(_geminiApiKeyStorageKey)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return ApiKeyRecord(source: ApiKeySource.stored, value: value);
  }

  @override
  Future<void> write(String value) async {
    await _preferences.setString(_geminiApiKeyStorageKey, value.trim());
  }
}

/// Read-only adapter for loading a development Gemini key from `.env`.
class DebugApiKeyStore implements ApiKeyStore {
  /// Creates a debug `.env` API key store.
  const DebugApiKeyStore({required String? Function() readValue})
    : _readValue = readValue;

  final String? Function() _readValue;

  @override
  ApiKeyStorageKind get kind => ApiKeyStorageKind.sharedPreferencesFallback;

  @override
  Future<void> delete() async {}

  @override
  Future<ApiKeyRecord?> read() async {
    final value = _readValue()?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return ApiKeyRecord(source: ApiKeySource.debugEnv, value: value);
  }

  @override
  Future<void> write(String value) async {}
}

/// Primary writable store with a secondary read-only fallback.
class FallbackApiKeyStore implements ApiKeyStore {
  /// Creates a fallback API key store.
  const FallbackApiKeyStore({
    required ApiKeyStore fallback,
    required ApiKeyStore primary,
  }) : _fallback = fallback,
       _primary = primary;

  final ApiKeyStore _fallback;
  final ApiKeyStore _primary;

  @override
  ApiKeyStorageKind get kind => _primary.kind;

  @override
  Future<void> delete() => _primary.delete();

  @override
  Future<ApiKeyRecord?> read() async {
    final primaryRecord = await _primary.read();
    if (primaryRecord != null) {
      return primaryRecord;
    }
    return _fallback.read();
  }

  @override
  Future<void> write(String value) => _primary.write(value);
}
