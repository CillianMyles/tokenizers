import '../../features/calendar/domain/medication_models.dart';
import '../../features/chat/domain/conversation_models.dart';
import 'model_response_contract.dart';

/// Produces app-owned model responses for a user turn.
abstract interface class ModelProvider {
  /// Generates a response for the current user turn.
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
  });
}
