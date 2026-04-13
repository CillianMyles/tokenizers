import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:tokenizers/env/src/debug_env_loader.dart';

/// Runtime environment values loaded from a local debug `.env` file.
abstract final class Env {
  /// Loads local debug environment variables when present.
  static Future<void> load() => loadDebugEnv();

  /// Gemini API key sourced from a local debug `.env` file.
  static String get geminiApiKey => dotenv.maybeGet('GEMINI_API_KEY') ?? '';
}
