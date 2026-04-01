import 'dart:convert';

import 'package:genui/genui.dart';
import 'package:http/http.dart' as http;

/// Bridges the app's GenUI transport to the Gemini REST API.
class GeminiGenUiService {
  /// Creates a Gemini GenUI service.
  GeminiGenUiService({
    required this.apiKey,
    this.model = 'gemini-2.5-flash',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  /// Generates an updated GenUI response for the current surface.
  Future<String> generateSurfaceUpdate({
    required String surfaceId,
    required ChatMessage userMessage,
    required Catalog catalog,
    required SurfaceDefinition? currentSurface,
    required Map<String, Object?> currentDataModel,
  }) async {
    final promptBuilder = PromptBuilder.custom(
      catalog: catalog,
      allowedOperations: SurfaceOperations.updateOnly(dataModel: true),
      clientDataModel: currentDataModel,
      systemPromptFragments: <String>[
        PromptFragments.currentDate(prefix: 'IMPORTANT: '),
        'IMPORTANT: You are building a Flutter health and medical tracking '
            'prototype using GenUI.',
        'IMPORTANT: Only update the existing surface with id "$surfaceId".',
        'IMPORTANT: Prefer concise, readable layouts that work on mobile and '
            'desktop.',
        'IMPORTANT: Use only components from the provided catalog.',
      ],
    );

    final requestPayload = <String, Object?>{
      'system_instruction': <String, Object?>{
        'parts': <Map<String, String>>[
          <String, String>{'text': promptBuilder.systemPromptJoined()},
        ],
      },
      'contents': <Map<String, Object?>>[
        <String, Object?>{
          'role': 'user',
          'parts': <Map<String, String>>[
            <String, String>{
              'text': _buildUserPrompt(
                surfaceId: surfaceId,
                userMessage: userMessage,
                currentSurface: currentSurface,
                currentDataModel: currentDataModel,
              ),
            },
          ],
        },
      ],
      'generationConfig': <String, Object?>{'temperature': 0.3},
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
        'Gemini API request failed (${response.statusCode}): '
        '${response.body}',
      );
    }

    final Map<String, Object?> payload = decodeJsonObject(response.body);
    final List<Object?> candidates =
        (payload['candidates'] as List<Object?>?) ?? const <Object?>[];
    if (candidates.isEmpty) {
      throw Exception('Gemini API returned no candidates.');
    }

    final Map<String, Object?> firstCandidate =
        candidates.first! as Map<String, Object?>;
    final Map<String, Object?> content =
        firstCandidate['content']! as Map<String, Object?>;
    final List<Object?> parts =
        (content['parts'] as List<Object?>?) ?? const <Object?>[];
    final String text = parts
        .whereType<Map<String, Object?>>()
        .map((part) => (part['text'] as String?) ?? '')
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw Exception('Gemini API returned an empty text response.');
    }

    return text;
  }

  String _buildUserPrompt({
    required String surfaceId,
    required ChatMessage userMessage,
    required SurfaceDefinition? currentSurface,
    required Map<String, Object?> currentDataModel,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Current surface id: $surfaceId')
      ..writeln()
      ..writeln('Current surface definition:')
      ..writeln(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(currentSurface?.toJson() ?? <String, Object?>{}),
      )
      ..writeln()
      ..writeln('Current client data model:')
      ..writeln(const JsonEncoder.withIndent('  ').convert(currentDataModel))
      ..writeln()
      ..writeln('Latest user input:');

    if (userMessage.text.trim().isNotEmpty) {
      buffer.writeln(userMessage.text.trim());
    }

    for (final UiInteractionPart part in userMessage.parts.uiInteractionParts) {
      buffer
        ..writeln()
        ..writeln('UI interaction event JSON:')
        ..writeln(part.interaction);
    }

    buffer
      ..writeln()
      ..writeln('Respond with valid A2UI JSON in fenced ```json blocks only.')
      ..writeln(
        'Use `updateComponents` and `updateDataModel` for the existing surface.',
      );

    return buffer.toString().trim();
  }

  /// Decodes a JSON object string into a typed map.
  static Map<String, Object?> decodeJsonObject(String source) {
    return (jsonDecode(source) as Map).cast<String, Object?>();
  }

  /// Releases the underlying HTTP client.
  void dispose() {
    _client.close();
  }
}
