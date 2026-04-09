import 'dart:math' as math;

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
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Draft medication changes, review pending proposals, and keep '
                'the conversation in one focused workspace.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _AssistantWorkspace(
                  composer: _composer(
                    context,
                    bootstrap: bootstrap,
                    threadId: threadId,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _composer(
    BuildContext context, {
    required AppBootstrap bootstrap,
    required String threadId,
  }) {
    final configurationError = bootstrap.configurationError;
    return Card(
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: <Widget>[
                          Chip(
                            avatar: const Icon(
                              Icons.keyboard_alt_outlined,
                              size: 18,
                            ),
                            label: const Text('Text'),
                          ),
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.photo_camera_back_outlined),
                            label: const Text('Photo'),
                          ),
                          OutlinedButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.mic_none_outlined),
                            label: const Text('Voice'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            <String>[
                              'Add amoxicillin 500 mg at 8am and 8pm',
                              'Stop metformin',
                              'Add vitamin D 1000 IU at 9am',
                            ].map((suggestion) {
                              return ActionChip(
                                label: Text(suggestion),
                                onPressed: () {
                                  _composerController.text = suggestion;
                                },
                              );
                            }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _composerController,
                        maxLines: 4,
                        minLines: 2,
                        decoration: InputDecoration(
                          hintText: configurationError == null
                              ? 'Describe a medication change. Drafts stay '
                                    'pending until you review and confirm them.'
                              : 'Add GEMINI_API_KEY to .env before sending '
                                    'medication updates.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      configurationError ??
                          'The assistant only creates drafts. Nothing changes '
                              'until you review and confirm the proposal.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _isSubmitting || configurationError != null
                        ? null
                        : () async {
                            setState(() {
                              _isSubmitting = true;
                            });
                            await bootstrap.chatCoordinator.submitText(
                              threadId,
                              _composerController.text,
                            );
                            if (mounted) {
                              _composerController.clear();
                              setState(() {
                                _isSubmitting = false;
                              });
                            }
                          },
                    icon: _isSubmitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

class _AssistantWorkspace extends StatelessWidget {
  const _AssistantWorkspace({
    required this.composer,
    required this.onCancelProposal,
    required this.onReviewProposal,
    required this.threadId,
  });

  final Widget composer;
  final Future<void> Function() onCancelProposal;
  final Future<void> Function(ProposalView proposal) onReviewProposal;
  final String threadId;

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final composerHeight = math.min(340.0, constraints.maxHeight * 0.4);

        return StreamBuilder<ProposalView?>(
          stream: bootstrap.conversationRepository.watchPendingProposal(
            threadId,
          ),
          builder: (context, proposalSnapshot) {
            final proposal = proposalSnapshot.data;

            return Column(
              children: <Widget>[
                if (proposal != null) ...<Widget>[
                  _PendingProposalCard(
                    onCancelProposal: onCancelProposal,
                    onReviewProposal: () => onReviewProposal(proposal),
                    proposal: proposal,
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(
                  child: StreamBuilder<List<ConversationMessageView>>(
                    stream: bootstrap.conversationRepository.watchMessages(
                      threadId,
                    ),
                    builder: (context, snapshot) {
                      final messages =
                          snapshot.data ?? const <ConversationMessageView>[];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: messages.isEmpty
                              ? const _EmptyAssistantState()
                              : ListView.separated(
                                  reverse: true,
                                  itemCount: messages.length,
                                  separatorBuilder: (context, index) =>
                                      const SizedBox(height: 14),
                                  itemBuilder: (context, index) {
                                    final message =
                                        messages[messages.length - index - 1];
                                    return _ConversationBubble(
                                      message: message,
                                    );
                                  },
                                ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(height: composerHeight, child: composer),
              ],
            );
          },
        );
      },
    );
  }
}

class _PendingProposalCard extends StatelessWidget {
  const _PendingProposalCard({
    required this.onCancelProposal,
    required this.onReviewProposal,
    required this.proposal,
  });

  final Future<void> Function() onCancelProposal;
  final Future<void> Function() onReviewProposal;
  final ProposalView proposal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Pending draft',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  avatar: const Icon(Icons.fact_check_outlined, size: 18),
                  label: Text(
                    '${proposal.actions.length} action'
                    '${proposal.actions.length == 1 ? '' : 's'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              proposal.summary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              proposal.assistantText,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: onCancelProposal,
                  icon: const Icon(Icons.close),
                  label: const Text('Discard'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onReviewProposal,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Review draft'),
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
        constraints: const BoxConstraints(maxWidth: 520),
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
                  message.actor.name,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.auto_awesome_outlined,
            size: 32,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Start a conversation',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask the assistant to add, stop, or update a medication schedule.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
