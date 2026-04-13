import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/data/settings_backed_model_provider.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  group('SettingsBackedModelProvider', () {
    test('uses the selected Gemini model from saved settings', () async {
      late Uri requestUri;
      final client = MockClient((request) async {
        requestUri = request.url;
        final responseBody = <String, Object?>{
          'candidates': <Map<String, Object?>>[
            <String, Object?>{
              'content': <String, Object?>{
                'parts': <Map<String, String>>[
                  <String, String>{
                    'text': jsonEncode(<String, Object?>{
                      'assistant_text': 'Ready for review.',
                      'actions': const <Object?>[],
                    }),
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(responseBody), 200);
      });
      final controller = AiSettingsController(
        repository: _FakeAiSettingsRepository(
          apiKeyRecord: const ApiKeyRecord(
            source: ApiKeySource.stored,
            value: 'test-key',
          ),
          settings: const AiSettings(
            geminiModel: GeminiModel.gemini3FlashPreview,
          ),
        ),
      );
      await controller.load();
      final provider = SettingsBackedModelProvider(
        settingsController: controller,
        client: client,
      );

      final response = await provider.generateResponse(
        activeSchedules: const [],
        conversation: const [],
        threadId: 'thread-1',
        userText: 'Add ibuprofen 200 mg at 8am',
      );

      expect(
        requestUri.toString(),
        contains('models/gemini-3-flash-preview:generateContent'),
      );
      expect(response, isA<ModelResponseContract>());
    });

    test('passes image attachments through to Gemini', () async {
      late Map<String, Object?> requestBody;
      final client = MockClient((request) async {
        requestBody = jsonDecode(request.body) as Map<String, Object?>;
        final responseBody = <String, Object?>{
          'candidates': <Map<String, Object?>>[
            <String, Object?>{
              'content': <String, Object?>{
                'parts': <Map<String, String>>[
                  <String, String>{
                    'text': jsonEncode(<String, Object?>{
                      'assistant_text': 'Ready for review.',
                      'actions': const <Object?>[],
                    }),
                  },
                ],
              },
            },
          ],
        };
        return http.Response(jsonEncode(responseBody), 200);
      });
      final controller = AiSettingsController(
        repository: _FakeAiSettingsRepository(
          apiKeyRecord: const ApiKeyRecord(
            source: ApiKeySource.stored,
            value: 'test-key',
          ),
          settings: const AiSettings(),
        ),
      );
      await controller.load();
      final provider = SettingsBackedModelProvider(
        settingsController: controller,
        client: client,
      );

      await provider.generateResponse(
        activeSchedules: const [],
        conversation: const [],
        threadId: 'thread-1',
        userText: 'Read this script.',
        imageAttachment: ModelImageAttachment(
          bytes: Uint8List.fromList(<int>[9, 8, 7]),
          mimeType: 'image/png',
        ),
      );

      final contents =
          (requestBody['contents'] as List<Object?>).single
              as Map<String, Object?>;
      final parts = (contents['parts'] as List<Object?>)
          .cast<Map<String, Object?>>();
      expect(parts.length, 2);
      expect(parts.last['inline_data'], <String, Object?>{
        'mime_type': 'image/png',
        'data': base64Encode(<int>[9, 8, 7]),
      });
    });

    test('throws when no Gemini API key is configured', () async {
      final controller = AiSettingsController(
        repository: _FakeAiSettingsRepository(settings: const AiSettings()),
      );
      await controller.load();
      final provider = SettingsBackedModelProvider(
        settingsController: controller,
      );

      expect(
        () => provider.generateResponse(
          activeSchedules: const [],
          conversation: const [],
          threadId: 'thread-1',
          userText: 'Hello',
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Add a Gemini API key in Settings to use the assistant.',
          ),
        ),
      );
    });
  });
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
  _FakeAiSettingsRepository({
    ApiKeyRecord? apiKeyRecord,
    required AiSettings settings,
  }) : _apiKeyRecord = apiKeyRecord,
       _settings = settings;

  ApiKeyRecord? _apiKeyRecord;
  AiSettings _settings;

  @override
  Future<void> clearAll() async {
    _apiKeyRecord = null;
    _settings = const AiSettings();
  }

  @override
  Future<void> clearGeminiApiKey() async {
    _apiKeyRecord = null;
  }

  @override
  Future<AiSettings> load() async => _settings.copyWith(
    apiKeySource: _apiKeyRecord?.source ?? ApiKeySource.none,
  );

  @override
  Future<String?> loadGeminiApiKey() async => _apiKeyRecord?.value;

  @override
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord() async => _apiKeyRecord;

  @override
  Future<AiSettings> save(AiSettings settings) async {
    _settings = settings;
    return load();
  }

  @override
  Future<void> saveGeminiApiKey(String apiKey) async {
    _apiKeyRecord = ApiKeyRecord(source: ApiKeySource.stored, value: apiKey);
  }
}
