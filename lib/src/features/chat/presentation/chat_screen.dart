import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../bootstrap/demo_app_bootstrap.dart';
import '../../../core/presentation/date_formatters.dart';
import '../../proposals/presentation/proposal_panel.dart';
import '../domain/conversation_models.dart';

/// Primary chat and proposal review surface.
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
    return ListenableBuilder(
      listenable: bootstrap.appSession,
      builder: (context, child) {
        final threadId = bootstrap.appSession.selectedThreadId;
        return StreamBuilder<List<ConversationThreadView>>(
          stream: bootstrap.conversationRepository.watchThreads(),
          builder: (context, snapshot) {
            final thread = _findThread(snapshot.data, threadId);
            return LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 960;
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: wide
                      ? Row(
                          children: <Widget>[
                            Expanded(
                              flex: 3,
                              child: _ChatColumn(
                                composer: _composer(
                                  context,
                                  bootstrap: bootstrap,
                                  threadId: threadId,
                                ),
                                header: _ThreadHeaderCard(thread: thread),
                                threadId: threadId,
                              ),
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              width: 360,
                              child: ProposalPanel(threadId: threadId),
                            ),
                          ],
                        )
                      : Column(
                          children: <Widget>[
                            _ThreadHeaderCard(thread: thread),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _ChatColumn(
                                composer: _composer(
                                  context,
                                  bootstrap: bootstrap,
                                  threadId: threadId,
                                ),
                                header: null,
                                threadId: threadId,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ProposalPanel(threadId: threadId),
                          ],
                        ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _composer(
    BuildContext context, {
    required AppBootstrap bootstrap,
    required String threadId,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
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
              decoration: const InputDecoration(
                hintText:
                    'Describe a medication change, for example “Add ibuprofen 200 mg at 8am”.',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Text stays local first. Structured proposals are reviewed before confirmation.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _isSubmitting
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
  }

  ConversationThreadView? _findThread(
    List<ConversationThreadView>? threads,
    String threadId,
  ) {
    if (threads == null) {
      return null;
    }
    for (final thread in threads) {
      if (thread.threadId == threadId) {
        return thread;
      }
    }
    return null;
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
        composer,
      ],
    );
  }
}

class _ThreadHeaderCard extends StatelessWidget {
  const _ThreadHeaderCard({required this.thread});

  final ConversationThreadView? thread;

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
              thread?.title ?? 'Conversation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Pending proposals stay isolated until you confirm them. '
              'Confirmed schedules are projected into the medication calendar.',
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
                  label: Text(
                    '${thread?.pendingProposalCount ?? 0} pending proposal'
                    '${(thread?.pendingProposalCount ?? 0) == 1 ? '' : 's'}',
                  ),
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
