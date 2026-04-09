import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/proposals/presentation/proposal_draft_sheet.dart';

/// Dedicated assistant workspace for proposals and medication changes.
class AssistantScreen extends StatefulWidget {
  /// Creates the assistant screen.
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _composerController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final threadId = bootstrap.activityStreamId;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Assistant',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Ask for schedule changes, review drafts, and confirm updates '
                'from one conversation.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _AssistantConversationPane(
                  onCancelProposal: () {
                    return bootstrap.chatCoordinator.cancelPendingProposal(
                      threadId,
                    );
                  },
                  onReviewProposal: (proposal) {
                    return _openDraftEditor(
                      context,
                      bootstrap: bootstrap,
                      proposal: proposal,
                      threadId: threadId,
                    );
                  },
                  threadId: threadId,
                ),
              ),
              const SizedBox(height: 12),
              _AssistantComposer(
                controller: _composerController,
                isSubmitting: _isSubmitting,
                onSend: () {
                  return _submitMessage(
                    bootstrap: bootstrap,
                    threadId: threadId,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitMessage({
    required AppBootstrap bootstrap,
    required String threadId,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    await bootstrap.chatCoordinator.submitText(
      threadId,
      _composerController.text,
    );

    if (!mounted) {
      return;
    }

    _composerController.clear();
    setState(() {
      _isSubmitting = false;
    });
  }

  Future<void> _openDraftEditor(
    BuildContext context, {
    required AppBootstrap bootstrap,
    required ProposalView proposal,
    required String threadId,
  }) {
    return showProposalDraftEditor(
      context: context,
      onCancelProposal: () {
        return bootstrap.chatCoordinator.cancelPendingProposal(threadId);
      },
      onConfirmProposal: (actions) {
        return bootstrap.chatCoordinator.confirmPendingProposal(
          threadId,
          editedActions: actions,
        );
      },
      proposal: proposal,
    );
  }
}

class _AssistantConversationPane extends StatelessWidget {
  const _AssistantConversationPane({
    required this.onCancelProposal,
    required this.onReviewProposal,
    required this.threadId,
  });

  final Future<void> Function() onCancelProposal;
  final Future<void> Function(ProposalView proposal) onReviewProposal;
  final String threadId;

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(28),
      ),
      child: StreamBuilder<ProposalView?>(
        stream: bootstrap.conversationRepository.watchPendingProposal(threadId),
        builder: (context, proposalSnapshot) {
          final proposal = proposalSnapshot.data;

          return StreamBuilder<List<ConversationMessageView>>(
            stream: bootstrap.conversationRepository.watchMessages(threadId),
            builder: (context, snapshot) {
              final messages =
                  snapshot.data ?? const <ConversationMessageView>[];
              final hasContent = proposal != null || messages.isNotEmpty;

              if (!hasContent) {
                return const _EmptyAssistantState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (proposal == null ? 0 : 1),
                itemBuilder: (context, index) {
                  if (proposal != null && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PendingProposalBanner(
                        onCancelProposal: onCancelProposal,
                        onReviewProposal: () => onReviewProposal(proposal),
                        proposal: proposal,
                      ),
                    );
                  }

                  final messageIndex = proposal == null ? index : index - 1;
                  final message = messages[messageIndex];
                  final isLast =
                      index == messages.length - 1 + (proposal == null ? 0 : 1);

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: _ConversationBubble(message: message),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AssistantComposer extends StatelessWidget {
  const _AssistantComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function() onSend;

  @override
  Widget build(BuildContext context) {
    final configurationError = AppScope.of(context).configurationError;
    final suggestions = <String>[
      'Add amoxicillin 500 mg at 8am and 8pm',
      'Stop metformin',
      'Add vitamin D 1000 IU at 9am',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: suggestions
                    .map((suggestion) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(suggestion),
                          onPressed: () {
                            controller.text = suggestion;
                            controller.selection = TextSelection.fromPosition(
                              TextPosition(offset: controller.text.length),
                            );
                          },
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              enabled: !isSubmitting && configurationError == null,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: configurationError == null
                    ? 'Describe a medication change...'
                    : 'Add GEMINI_API_KEY to .env before sending updates.',
                suffixIcon: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton(
                    onPressed: isSubmitting || configurationError != null
                        ? null
                        : onSend,
                    child: isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
                suffixIconConstraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 72,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              configurationError ??
                  'The assistant drafts structured changes first. Nothing is '
                      'applied until you review and confirm.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingProposalBanner extends StatelessWidget {
  const _PendingProposalBanner({
    required this.onCancelProposal,
    required this.onReviewProposal,
    required this.proposal,
  });

  final Future<void> Function() onCancelProposal;
  final Future<void> Function() onReviewProposal;
  final ProposalView proposal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.fact_check_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pending draft ready to review',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(
                    '${proposal.actions.length} action'
                    '${proposal.actions.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              proposal.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              proposal.assistantText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: onReviewProposal,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Review draft'),
                ),
                OutlinedButton.icon(
                  onPressed: onCancelProposal,
                  icon: const Icon(Icons.close),
                  label: const Text('Discard'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationBubble extends StatelessWidget {
  const _ConversationBubble({required this.message});

  final ConversationMessageView message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.actor == ConversationActor.user;
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isUser
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isUser ? 'You' : 'Assistant',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                ),
                const SizedBox(height: 6),
                Text(message.text),
                const SizedBox(height: 10),
                Text(
                  formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyAssistantState extends StatelessWidget {
  const _EmptyAssistantState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.auto_awesome_outlined,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ask to add, update, or stop a medication schedule. The assistant '
              'will draft the change for review before anything is applied.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
