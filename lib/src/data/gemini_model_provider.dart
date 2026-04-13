import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/medication_assistant_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';

const _defaultModel = 'gemini-2.5-flash';

/// Gemini-backed implementation of the app-owned model contract.
class GeminiModelProvider implements ModelProvider {
  /// Creates a Gemini model provider.
  GeminiModelProvider({
    required this.apiKey,
    this.model = _defaultModel,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    final contentParts = <Map<String, Object?>>[
      <String, Object?>{
        'text': buildMedicationAssistantPrompt(
          confirmedSchedules: confirmedSchedules,
          conversation: conversation,
          threadId: threadId,
          userText: userText,
          imageAttachment: imageAttachment,
        ),
      },
    ];
    if (imageAttachment != null) {
      contentParts.add(<String, Object?>{
        'inline_data': <String, Object?>{
          'mime_type': imageAttachment.mimeType,
          'data': base64Encode(imageAttachment.bytes),
        },
      });
    }

    final requestPayload = <String, Object?>{
      'system_instruction': <String, Object?>{
        'parts': <Map<String, String>>[
          <String, String>{'text': medicationAssistantSystemPrompt},
        ],
      },
      'contents': <Map<String, Object?>>[
        <String, Object?>{'role': 'user', 'parts': contentParts},
      ],
      'generationConfig': <String, Object?>{
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseJsonSchema': medicationAssistantResponseSchema,
      },
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );

    final response = await _client.post(
      uri,
      headers: <String, String>{
        'x-goog-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemini API request failed (${response.statusCode}): ${response.body}',
      );
    }

    final apiPayload = decodeJsonObject(response.body);
    final text = _extractCandidateText(apiPayload);
    final structured = decodeJsonObject(text);
    return parseMedicationAssistantResponse(
      structured: structured,
      rawPayload: apiPayload,
      rawPayloadKey: 'gemini_response',
    );
  }

  String _extractCandidateText(Map<String, Object?> payload) {
    final candidates =
        (payload['candidates'] as List<Object?>?) ?? const <Object?>[];
    if (candidates.isEmpty) {
      throw Exception('Gemini API returned no candidates.');
    }

    final firstCandidate = candidates.first! as Map<String, Object?>;
    final content = firstCandidate['content']! as Map<String, Object?>;
    final parts = (content['parts'] as List<Object?>?) ?? const <Object?>[];
    final text = parts
        .whereType<Map<String, Object?>>()
        .map((part) => (part['text'] as String?) ?? '')
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw Exception('Gemini API returned an empty structured response.');
    }
    return text;
  }
}
