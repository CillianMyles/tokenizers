import 'dart:typed_data';

import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';

/// Image bytes attached to a model turn.
class ModelImageAttachment {
  /// Creates an image attachment for a model turn.
  const ModelImageAttachment({required this.bytes, required this.mimeType});

  /// Raw image bytes.
  final Uint8List bytes;

  /// MIME type such as `image/jpeg`.
  final String mimeType;
}

/// Produces app-owned model responses for a user turn.
abstract interface class ModelProvider {
  /// Generates a response for the current user turn.
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  });
}
