/// Logical actor type for conversation messages.
enum ConversationActor { user, model, system }

/// A projected conversation message.
class ConversationMessageView {
  /// Creates a conversation message view.
  const ConversationMessageView({
    required this.actor,
    required this.createdAt,
    required this.messageId,
    required this.text,
    required this.threadId,
  });

  /// The message actor.
  final ConversationActor actor;

  /// Message timestamp.
  final DateTime createdAt;

  /// Stable message id.
  final String messageId;

  /// Message text.
  final String text;

  /// Parent thread id.
  final String threadId;
}

/// A projected conversation thread summary.
class ConversationThreadView {
  /// Creates a conversation thread view.
  const ConversationThreadView({
    required this.lastMessagePreview,
    required this.lastUpdatedAt,
    required this.pendingProposalCount,
    required this.threadId,
    required this.title,
  });

  /// Latest message preview.
  final String lastMessagePreview;

  /// Last updated time.
  final DateTime lastUpdatedAt;

  /// Number of pending proposals in the thread.
  final int pendingProposalCount;

  /// Stable thread id.
  final String threadId;

  /// Human-readable title.
  final String title;
}
