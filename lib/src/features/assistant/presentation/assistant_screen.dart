import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/core/presentation/expandable_text.dart';
import 'package:tokenizers/src/features/assistant/presentation/assistant_voice_input_sheet.dart';
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
  final ScrollController _conversationScrollController = ScrollController();
  bool _isSubmitting = false;
  String? _lastConversationAnchor;

  @override
  void dispose() {
    _composerController.dispose();
    _conversationScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final threadId = bootstrap.activityStreamId;

    return StreamBuilder<ProposalView?>(
      stream: bootstrap.conversationRepository.watchPendingProposal(threadId),
      builder: (context, proposalSnapshot) {
        final proposal = proposalSnapshot.data;
        return StreamBuilder<List<ConversationMessageView>>(
          stream: bootstrap.conversationRepository.watchMessages(threadId),
          builder: (context, snapshot) {
            final messages = snapshot.data ?? const <ConversationMessageView>[];
            _scrollToLatestIfNeeded(messages, proposal);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    children: <Widget>[
                      Expanded(
                        child: _AssistantConversationPane(
                          controller: _conversationScrollController,
                          messages: messages,
                        ),
                      ),
                      if (proposal != null) ...<Widget>[
                        const SizedBox(height: 8),
                        _PendingProposalActionBar(
                          onCancelProposal: () {
                            return bootstrap.chatCoordinator
                                .cancelPendingProposal(threadId);
                          },
                          onReviewProposal: () {
                            return _openDraftEditor(
                              context,
                              bootstrap: bootstrap,
                              proposal: proposal,
                              threadId: threadId,
                            );
                          },
                          proposal: proposal,
                        ),
                      ],
                      const SizedBox(height: 8),
                      _AssistantComposer(
                        controller: _composerController,
                        isSubmitting: _isSubmitting,
                        onInputActionSelected: (action) {
                          return _handleComposerInputAction(
                            action,
                            bootstrap: bootstrap,
                          );
                        },
                        onSend: () {
                          return _submitMessage(
                            bootstrap: bootstrap,
                            threadId: threadId,
                          );
                        },
                        showSuggestions: proposal == null && messages.isEmpty,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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

  Future<void> _handleComposerInputAction(
    _ComposerInputAction action, {
    required AppBootstrap bootstrap,
  }) async {
    switch (action) {
      case _ComposerInputAction.recordAudio:
        final transcript = await showAssistantVoiceInputSheet(
          context,
          speechToTextService: bootstrap.speechToTextService,
        );
        if (!mounted || transcript == null || transcript.trim().isEmpty) {
          return;
        }
        _insertTranscript(transcript.trim());
      case _ComposerInputAction.takePhoto:
      case _ComposerInputAction.chooseImage:
      case _ComposerInputAction.chooseFile:
        final label = switch (action) {
          _ComposerInputAction.recordAudio => 'Record audio',
          _ComposerInputAction.takePhoto => 'Take photo',
          _ComposerInputAction.chooseImage => 'Choose image',
          _ComposerInputAction.chooseFile => 'Choose file',
        };
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$label is not wired yet.')));
    }
  }

  void _insertTranscript(String transcript) {
    final existingText = _composerController.text.trimRight();
    _composerController.text = existingText.isEmpty
        ? transcript
        : '$existingText\n$transcript';
    _composerController.selection = TextSelection.fromPosition(
      TextPosition(offset: _composerController.text.length),
    );
  }

  Future<void> _openDraftEditor(
    BuildContext context, {
    required AppBootstrap bootstrap,
    required ProposalView proposal,
    required String threadId,
  }) async {
    final activeSchedules = await bootstrap.medicationRepository
        .getActiveSchedules();
    if (!context.mounted) {
      return;
    }
    return showProposalDraftEditor(
      activeSchedules: activeSchedules,
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

  void _scrollToLatestIfNeeded(
    List<ConversationMessageView> messages,
    ProposalView? proposal,
  ) {
    final anchor =
        '${proposal?.proposalId ?? 'no-proposal'}:'
        '${messages.length}:'
        '${messages.isEmpty ? 'no-message' : messages.last.messageId}';
    if (_lastConversationAnchor == anchor) {
      return;
    }
    _lastConversationAnchor = anchor;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_conversationScrollController.hasClients) {
        return;
      }
      _conversationScrollController.jumpTo(
        _conversationScrollController.position.maxScrollExtent,
      );
    });
  }
}

class _AssistantConversationPane extends StatelessWidget {
  const _AssistantConversationPane({
    required this.controller,
    required this.messages,
  });

  final ScrollController controller;
  final List<ConversationMessageView> messages;

  @override
  Widget build(BuildContext context) {
    final hasContent = messages.isNotEmpty;

    if (!hasContent) {
      return const _EmptyAssistantState();
    }

    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isLast = index == messages.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
          child: _ConversationBubble(message: message),
        );
      },
    );
  }
}

class _AssistantComposer extends StatelessWidget {
  const _AssistantComposer({
    required this.controller,
    required this.isSubmitting,
    required this.onInputActionSelected,
    required this.onSend,
    required this.showSuggestions,
  });

  final TextEditingController controller;
  final bool isSubmitting;
  final Future<void> Function(_ComposerInputAction action)
  onInputActionSelected;
  final Future<void> Function() onSend;
  final bool showSuggestions;

  @override
  Widget build(BuildContext context) {
    final settingsController = AppScope.of(context).aiSettingsController;
    final colorScheme = Theme.of(context).colorScheme;
    const suggestions = <({String label, String text})>[
      (label: 'Vit D', text: 'Add vitamin D 1000 IU at 9am'),
      (label: 'Amox', text: 'Add amoxicillin 500 mg at 8am and 8pm'),
    ];

    return ListenableBuilder(
      listenable: settingsController,
      builder: (context, child) {
        final configurationError = settingsController.configurationError;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (showSuggestions) ...<Widget>[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: suggestions
                        .map((suggestion) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _SuggestionPromptChip(
                              label: suggestion.label,
                              onPressed: () {
                                controller.text = suggestion.text;
                                controller
                                    .selection = TextSelection.fromPosition(
                                  TextPosition(offset: controller.text.length),
                                );
                              },
                            ),
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  final hasText = value.text.trim().isNotEmpty;
                  return TextField(
                    controller: controller,
                    enabled: !isSubmitting && configurationError == null,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) {
                      if (hasText) {
                        onSend();
                      }
                    },
                    decoration: InputDecoration(
                      hintText: configurationError == null
                          ? 'Describe a medication change...'
                          : 'Add a Gemini API key in Settings before sending.',
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 160),
                          child: isSubmitting
                              ? const SizedBox.square(
                                  key: ValueKey('sending'),
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : hasText
                              ? IconButton(
                                  key: const ValueKey('send'),
                                  onPressed: configurationError != null
                                      ? null
                                      : onSend,
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    foregroundColor: colorScheme.primary,
                                    minimumSize: const Size.square(40),
                                    maximumSize: const Size.square(40),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_upward,
                                    size: 18,
                                  ),
                                )
                              : _ComposerActionMenu(
                                  key: const ValueKey('plus'),
                                  enabled:
                                      !isSubmitting &&
                                      configurationError == null,
                                  onSelected: onInputActionSelected,
                                ),
                        ),
                      ),
                      suffixIconConstraints: const BoxConstraints(
                        minHeight: 44,
                        minWidth: 52,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SuggestionPromptChip extends StatelessWidget {
  const _SuggestionPromptChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      avatar: Icon(
        Icons.auto_awesome_outlined,
        size: 16,
        color: colorScheme.primary,
      ),
      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.9),
      label: Text(label),
      onPressed: onPressed,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }
}

enum _ComposerInputAction { recordAudio, takePhoto, chooseImage, chooseFile }

class _ComposerActionMenu extends StatelessWidget {
  const _ComposerActionMenu({
    required this.enabled,
    required this.onSelected,
    super.key,
  });

  final bool enabled;
  final ValueChanged<_ComposerInputAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_ComposerInputAction>(
      tooltip: 'More input options',
      enabled: enabled,
      onSelected: onSelected,
      color: colorScheme.surface,
      elevation: 6,
      icon: Icon(Icons.add, size: 18, color: colorScheme.onSurfaceVariant),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surfaceContainerHighest,
        minimumSize: const Size.square(40),
        maximumSize: const Size.square(40),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      itemBuilder: (context) => <PopupMenuEntry<_ComposerInputAction>>[
        const PopupMenuItem<_ComposerInputAction>(
          value: _ComposerInputAction.recordAudio,
          child: _ComposerActionRow(
            icon: Icons.mic_none_outlined,
            label: 'Record audio',
          ),
        ),
        const PopupMenuItem<_ComposerInputAction>(
          value: _ComposerInputAction.takePhoto,
          child: _ComposerActionRow(
            icon: Icons.photo_camera_back_outlined,
            label: 'Take photo',
          ),
        ),
        const PopupMenuItem<_ComposerInputAction>(
          value: _ComposerInputAction.chooseImage,
          child: _ComposerActionRow(
            icon: Icons.image_outlined,
            label: 'Choose image',
          ),
        ),
        const PopupMenuItem<_ComposerInputAction>(
          value: _ComposerInputAction.chooseFile,
          child: _ComposerActionRow(
            icon: Icons.attach_file_outlined,
            label: 'Choose file',
          ),
        ),
      ],
    );
  }
}

class _ComposerActionRow extends StatelessWidget {
  const _ComposerActionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 18),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}

class _PendingProposalActionBar extends StatelessWidget {
  const _PendingProposalActionBar({
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
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Draft ready: ${proposal.actions.length} action'
                '${proposal.actions.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: onReviewProposal,
              child: const Text('Review'),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCancelProposal,
              icon: const Icon(Icons.close),
              tooltip: 'Discard draft',
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
                ExpandableText(
                  message.text,
                  maxLines: 8,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
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
