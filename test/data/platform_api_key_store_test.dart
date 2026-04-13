import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokenizers/src/data/platform_api_key_store.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('uses shared preferences storage on macOS', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = createPlatformApiKeyStore(
      preferences: preferences,
      targetPlatform: TargetPlatform.macOS,
    );

    expect(store.kind, ApiKeyStorageKind.sharedPreferencesFallback);

    await store.write('mac-key');

    final record = await store.read();

    expect(record?.value, 'mac-key');
    expect(preferences.getString('ai_settings.gemini_api_key'), 'mac-key');
  });
}
