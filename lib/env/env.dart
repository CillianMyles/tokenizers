/// Compile-time environment values used by the app.
abstract final class Env {
  /// Gemini API key passed through `--dart-define=GEMINI_API_KEY=...`.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
