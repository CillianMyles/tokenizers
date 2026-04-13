import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tokenizers/src/data/gemini_model_provider.dart';

void main() {
  group('GeminiModelProvider', () {
    Map<String, Object?> successBody() => <String, Object?>{
      'candidates': <Map<String, Object?>>[
        <String, Object?>{
          'content': <String, Object?>{
            'parts': <Map<String, String>>[
              <String, String>{
                'text': jsonEncode(<String, Object?>{
                  'assistant_text': 'I drafted a pending ibuprofen schedule.',
                  'actions': <Map<String, Object?>>[
                    <String, Object?>{
                      'type': 'add_medication_schedule',
                      'medication_name': 'Ibuprofen',
                      'dose_amount': '200',
                      'dose_unit': 'mg',
                      'start_date': '2026-04-05',
                      'times': <String>['08:00'],
                    },
                  ],
                }),
              },
            ],
          },
        },
      ],
    };

    test('parses structured JSON responses into the app contract', () async {
      final client = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-key');
        return http.Response(jsonEncode(successBody()), 200);
      });
      final provider = GeminiModelProvider(apiKey: 'test-key', client: client);

      final response = await provider.generateResponse(
        activeSchedules: const [],
        conversation: const [],
        threadId: 'thread-1',
        userText: 'Add ibuprofen 200 mg at 8am',
      );

      expect(response.assistantText, 'I drafted a pending ibuprofen schedule.');
      expect(response.actions.single.medicationName, 'Ibuprofen');
      expect(response.actions.single.times, <String>['08:00']);
      expect(
        response.rawPayload['structured_response'],
        isA<Map<String, Object?>>(),
      );
    });

    test('retries on 503 then succeeds', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        if (callCount <= 2) {
          return http.Response('{"error":"unavailable"}', 503);
        }
        return http.Response(jsonEncode(successBody()), 200);
      });
      final provider = GeminiModelProvider(apiKey: 'test-key', client: client);

      final response = await provider.generateResponse(
        activeSchedules: const [],
        conversation: const [],
        threadId: 'thread-1',
        userText: 'Add ibuprofen 200 mg at 8am',
      );

      expect(callCount, 3);
      expect(response.assistantText, 'I drafted a pending ibuprofen schedule.');
    });

    test('throws after exhausting retries on 503', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('{"error":"unavailable"}', 503);
      });
      final provider = GeminiModelProvider(apiKey: 'test-key', client: client);

      await expectLater(
        provider.generateResponse(
          activeSchedules: const [],
          conversation: const [],
          threadId: 'thread-1',
          userText: 'test',
        ),
        throwsA(
          isA<GeminiTransientException>()
              .having((e) => e.statusCode, 'statusCode', 503)
              .having((e) => e.attempts, 'attempts', 4),
        ),
      );

      // 1 initial + 3 retries = 4 total attempts.
      expect(callCount, 4);
    });

    test('does not retry on non-retryable status codes', () async {
      var callCount = 0;
      final client = MockClient((request) async {
        callCount++;
        return http.Response('{"error":"bad request"}', 400);
      });
      final provider = GeminiModelProvider(apiKey: 'test-key', client: client);

      await expectLater(
        provider.generateResponse(
          activeSchedules: const [],
          conversation: const [],
          threadId: 'thread-1',
          userText: 'test',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('400'),
          ),
        ),
      );

      expect(callCount, 1);
    });
  });
}
