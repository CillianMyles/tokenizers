import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// A stored Gemini API key and the source it came from.
class ApiKeyRecord {
  /// Creates an API key record.
  const ApiKeyRecord({required this.source, required this.value});

  /// Where the key came from.
  final ApiKeySource source;

  /// The raw Gemini API key value.
  final String value;
}

/// Adapter for storing a Gemini API key on the current platform.
abstract interface class ApiKeyStore {
  /// The storage strategy used by this adapter.
  ApiKeyStorageKind get kind;

  /// Loads the stored Gemini API key, if present.
  Future<ApiKeyRecord?> read();

  /// Persists the Gemini API key.
  Future<void> write(String value);

  /// Removes the stored Gemini API key.
  Future<void> delete();
}
