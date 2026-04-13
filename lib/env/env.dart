import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:tokenizers/env/src/debug_env_loader.dart';

const _geminiApiKeyFromDartDefine = String.fromEnvironment('GEMINI_API_KEY');

/// Runtime environment values loaded from local debug configuration.
abstract final class Env {
  /// Loads local debug environment variables when present.
  static Future<void> load() => loadDebugEnv();

  /// Gemini API key sourced from `.env` or a Flutter `--dart-define`.
  static String get geminiApiKey {
    final dotenvValue = dotenv.maybeGet('GEMINI_API_KEY')?.trim();
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue;
    }
    return _geminiApiKeyFromDartDefine.trim();
  }
}
