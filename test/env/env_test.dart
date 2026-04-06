import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/env/env.dart';

void main() {
  group('Env', () {
    tearDown(dotenv.clean);

    test('reads the Gemini API key from loaded dotenv values', () {
      dotenv.loadFromString(envString: 'GEMINI_API_KEY=test-key');

      expect(Env.geminiApiKey, 'test-key');
    });

    test('falls back to an empty string when the key is missing', () {
      dotenv.loadFromString(envString: '', isOptional: true);

      expect(Env.geminiApiKey, isEmpty);
    });
  });
}
