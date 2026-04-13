import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/data/local_gemma_service.dart';

void main() {
  group('resolveLocalGemmaRuntimeConfig', () {
    test('uses a conservative profile on iOS', () {
      final config = resolveLocalGemmaRuntimeConfig(
        platform: TargetPlatform.iOS,
      );

      expect(config.isThinkingEnabled, isFalse);
      expect(config.maxTokens, 512);
      expect(config.preferredBackend, PreferredBackend.cpu);
    });

    test('uses the default GPU profile on non-iOS platforms', () {
      final config = resolveLocalGemmaRuntimeConfig(
        platform: TargetPlatform.android,
      );

      expect(config.isThinkingEnabled, isTrue);
      expect(config.maxTokens, 1024);
      expect(config.preferredBackend, PreferredBackend.gpu);
    });
  });
}
