import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment values loaded from the local `.env` asset.
abstract final class Env {
  /// Loads local environment variables if a `.env` file is present.
  static Future<void> load() async {
    await dotenv.load(fileName: '.env', isOptional: true);
  }

  /// Gemini API key sourced from the local `.env` file.
  static String get geminiApiKey => dotenv.maybeGet('GEMINI_API_KEY') ?? '';
}
