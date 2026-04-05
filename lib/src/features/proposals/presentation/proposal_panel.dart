import 'package:flutter/material.dart';

import '../../../app/app_scope.dart';
import '../../../core/presentation/date_formatters.dart';
import '../domain/proposal_models.dart';

/// Pinned proposal review surface for the active thread.
class ProposalPanel extends StatelessWidget {
  /// Creates a proposal panel.
  const ProposalPanel({required this.threadId, super.key});

  final String threadId;

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    return StreamBuilder<ProposalView?>(
      stream: bootstrap.conversationRepository.watchPendingProposal(threadId),
      builder: (context, snapshot) {
        final proposal = snapshot.data;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: proposal == null
                ? const _NoProposalState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Proposal Review',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Explicit confirmation is required before medication state changes.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Chip(
                        label: Text(
                          'Pending • ${formatDayAndTime(proposal.createdAt)}',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        proposal.summary,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(proposal.assistantText),
                      const SizedBox(height: 16),
                      ...proposal.actions.map(
                        (action) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ProposalActionCard(action: action),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (!proposal.isConfirmable)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            'This proposal needs more information before it can be confirmed.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                bootstrap.chatCoordinator.cancelPendingProposal(
                                  threadId,
                                );
                              },
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: proposal.isConfirmable
                                  ? () {
                                      bootstrap.chatCoordinator
                                          .confirmPendingProposal(threadId);
                                    }
                                  : null,
                              child: const Text('Confirm'),
                            ),
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
}

class _NoProposalState extends StatelessWidget {
  const _NoProposalState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Proposal Review', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'No pending proposal for this thread.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text(
          'Send a medication message to create a structured proposal that can be reviewed and confirmed here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProposalActionCard extends StatelessWidget {
  const _ProposalActionCard({required this.action});

  final ProposalActionView action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              action.type.wireValue,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(action.summary),
            if (action.notes case final notes?) ...<Widget>[
              const SizedBox(height: 8),
              Text(notes, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
