import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// Reads projected conversation threads, messages, and pending proposals.
abstract interface class ConversationRepository {
  /// Loads messages for a thread.
  Future<List<ConversationMessageView>> getMessages(String threadId);

  /// Loads the current pending proposal for a thread.
  Future<ProposalView?> getPendingProposal(String threadId);

  /// Watches messages for a thread.
  Stream<List<ConversationMessageView>> watchMessages(String threadId);

  /// Watches the current pending proposal for a thread.
  Stream<ProposalView?> watchPendingProposal(String threadId);

  /// Watches conversation threads.
  Stream<List<ConversationThreadView>> watchThreads();
}
