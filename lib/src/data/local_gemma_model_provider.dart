import 'dart:convert';

import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/local_gemma_service.dart';
import 'package:tokenizers/src/data/medication_assistant_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// On-device Gemma-backed implementation of the app-owned model contract.
class LocalGemmaModelProvider implements ModelProvider {
  /// Creates a local Gemma model provider.
  const LocalGemmaModelProvider({
    required LocalGemmaService service,
    required this.model,
  }) : _service = service;

  final LocalGemmaService _service;
  final LocalGemmaModel model;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    if (imageAttachment != null) {
      throw StateError(
        'Offline Gemma does not support image attachments yet. '
        'Switch to Gemini or send text only.',
      );
    }

    final rawText = await _service.generateText(
      model: model,
      prompt: buildMedicationAssistantPrompt(
        confirmedSchedules: confirmedSchedules,
        conversation: conversation,
        threadId: threadId,
        userText: userText,
      ),
      systemInstruction: _localGemmaSystemInstruction,
    );

    final jsonText = _extractJsonObject(rawText);
    final structured = decodeJsonObject(jsonText);
    return parseMedicationAssistantResponse(
      structured: structured,
      rawPayload: <String, Object?>{'model': model.wireValue, 'text': rawText},
      rawPayloadKey: 'local_gemma_response',
    );
  }

  String _extractJsonObject(String response) {
    final trimmed = response.trim();
    if (trimmed.startsWith('{')) {
      return trimmed;
    }

    final fencedJson = RegExp(r'```json\s*(\{[\s\S]*\})\s*```');
    final fencedMatch = fencedJson.firstMatch(trimmed);
    if (fencedMatch != null) {
      return fencedMatch.group(1)!;
    }

    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return trimmed.substring(firstBrace, lastBrace + 1);
    }

    throw const FormatException('Local Gemma returned a non-JSON response.');
  }
}

final _localGemmaSystemInstruction = <String>[
  medicationAssistantSystemPrompt.trim(),
  'Return a single JSON object with no markdown.',
  'Use this exact schema:',
  const JsonEncoder.withIndent('  ').convert(medicationAssistantResponseSchema),
].join('\n\n');
