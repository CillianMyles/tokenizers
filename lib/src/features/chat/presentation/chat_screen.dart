import 'package:flutter/material.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/proposals/presentation/proposal_draft_sheet.dart';

/// Primary structured assistant surface.
class ChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
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
    final activityStreamId = bootstrap.activityStreamId;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: <Widget>[
              const _AssistantHeaderCard(),
              const SizedBox(height: 16),
              Expanded(
                child: _ChatColumn(
                  composer: _composer(
                    context,
                    bootstrap: bootstrap,
                    threadId: activityStreamId,
                  ),
                  header: null,
                  threadId: activityStreamId,
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
    return StreamBuilder<ProposalView?>(
      stream: bootstrap.conversationRepository.watchPendingProposal(threadId),
      builder: (context, snapshot) {
        final pendingProposal = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (pendingProposal != null) ...<Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () => _openDraftEditor(
                      context,
                      bootstrap: bootstrap,
                      proposal: pendingProposal,
                      threadId: threadId,
                    ),
                    icon: const Icon(Icons.fact_check_outlined),
                    label: Text(
                      'Review draft • ${pendingProposal.actions.length} action'
                      '${pendingProposal.actions.length == 1 ? '' : 's'}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pendingProposal.summary,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                ],
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(
                      avatar: const Icon(Icons.keyboard_alt_outlined, size: 18),
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
                        ? 'Describe a medication change. Drafts open above the keyboard before anything changes.'
                        : 'Add GEMINI_API_KEY to .env before sending medication updates.',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        configurationError ??
                            'Text stays local first. Drafts must be accepted manually before confirmed schedules update.',
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
        );
      },
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

class _ChatColumn extends StatelessWidget {
  const _ChatColumn({
    required this.composer,
    required this.threadId,
    this.header,
  });

  final Widget composer;
  final Widget? header;
  final String threadId;

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final composerMaxHeight = screenHeight < 760 ? screenHeight * 0.36 : 420.0;
    return Column(
      children: <Widget>[
        if (header case final header?) ...<Widget>[
          header,
          const SizedBox(height: 16),
        ],
        Expanded(
          child: StreamBuilder<List<ConversationMessageView>>(
            stream: bootstrap.conversationRepository.watchMessages(threadId),
            builder: (context, snapshot) {
              final messages =
                  snapshot.data ?? const <ConversationMessageView>[];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ListView.separated(
                    reverse: true,
                    itemCount: messages.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - index - 1];
                      final isUser = message.actor == ConversationActor.user;
                      final colorScheme = Theme.of(context).colorScheme;
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: colorScheme.primary),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(message.text),
                                  const SizedBox(height: 10),
                                  Text(
                                    formatTime(message.createdAt),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: composerMaxHeight),
          child: SingleChildScrollView(child: composer),
        ),
      ],
    );
  }
}

class _AssistantHeaderCard extends StatelessWidget {
  const _AssistantHeaderCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Medication Assistant',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Use chat to draft structured medication changes. The app treats '
              'chat as one assistant surface, not as separate conversations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Chip(
                  avatar: const Icon(Icons.offline_bolt, size: 18),
                  label: const Text('Offline-first local state'),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.secondaryContainer,
                ),
                Chip(
                  avatar: const Icon(Icons.shield_outlined, size: 18),
                  label: const Text('Confirmation-gated changes'),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.primaryContainer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
