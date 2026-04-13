import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/core/presentation/expandable_text.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_taken_editor.dart';
import 'package:tokenizers/src/features/history/domain/history_timeline_models.dart';
import 'package:tokenizers/src/features/home/domain/medication_reminder_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/proposals/presentation/proposal_draft_sheet.dart';

/// Operational dashboard for today's activity and next actions.
class TodayScreen extends StatelessWidget {
  /// Creates the today screen.
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    final today = DateTime.now();
    final threadId = bootstrap.activityStreamId;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: StreamBuilder<List<MedicationCalendarEntry>>(
            stream: bootstrap.medicationRepository.watchCalendarEntriesForDay(
              today,
            ),
            builder: (context, entriesSnapshot) {
              final entries =
                  entriesSnapshot.data ?? const <MedicationCalendarEntry>[];

              return StreamBuilder<List<EventEnvelope<DomainEvent>>>(
                stream: bootstrap.eventStore.watchAll(),
                builder: (context, eventsSnapshot) {
                  final events =
                      eventsSnapshot.data ??
                      const <EventEnvelope<DomainEvent>>[];
                  final reminders = buildMedicationReminders(
                    entries: entries,
                    events: events,
                    now: today,
                  );
                  final historyItems = buildHistoryTimeline(events)
                      .expand((group) => group.items)
                      .take(3)
                      .toList(growable: false);

                  return StreamBuilder<ProposalView?>(
                    stream: bootstrap.conversationRepository
                        .watchPendingProposal(threadId),
                    builder: (context, proposalSnapshot) {
                      final proposal = proposalSnapshot.data;
                      final summary = _TodaySummary.fromData(
                        proposal: proposal,
                        reminders: reminders,
                      );

                      return ListView(
                        children: <Widget>[
                          _TodaySummaryCard(summary: summary),
                          const SizedBox(height: 16),
                          _ReminderSectionCard(
                            emptyText: 'Nothing is due right now.',
                            onMarkTaken: (entry) async {
                              final draft = await showMedicationTakenEditor(
                                context: context,
                                entry: entry,
                                scheduleEntries: entries,
                              );
                              if (draft == null) {
                                return;
                              }
                              await bootstrap.medicationCommandService
                                  .recordMedicationTaken(
                                    actorType: EventActorType.user,
                                    entry: entry,
                                    scheduledFor: draft.scheduledFor,
                                    takenAt: draft.takenAt,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Recorded ${entry.medicationName} at '
                                      '${formatTime(draft.takenAt)}.',
                                    ),
                                  ),
                                );
                              }
                            },
                            reminders: reminders
                                .where((reminder) {
                                  return reminder.status ==
                                          MedicationReminderStatus.overdue ||
                                      reminder.status ==
                                          MedicationReminderStatus.dueNow;
                                })
                                .toList(growable: false),
                            subtitle:
                                'The most urgent reminders that need attention '
                                'today.',
                            title: 'Due now',
                          ),
                          if (proposal != null) ...<Widget>[
                            const SizedBox(height: 16),
                            _PendingReviewCard(
                              onReviewProposal: () async {
                                final activeSchedules = await bootstrap
                                    .medicationRepository
                                    .getActiveSchedules();
                                if (!context.mounted) {
                                  return;
                                }
                                return showProposalDraftEditor(
                                  activeSchedules: activeSchedules,
                                  context: context,
                                  onCancelProposal: () {
                                    return bootstrap.chatCoordinator
                                        .cancelPendingProposal(threadId);
                                  },
                                  onConfirmProposal: (actions) {
                                    return bootstrap.chatCoordinator
                                        .confirmPendingProposal(
                                          threadId,
                                          editedActions: actions,
                                        );
                                  },
                                  proposal: proposal,
                                );
                              },
                              proposal: proposal,
                            ),
                          ],
                          const SizedBox(height: 16),
                          _ReminderSectionCard(
                            emptyText:
                                'Nothing else is scheduled for later today.',
                            onMarkTaken: (entry) async {
                              final draft = await showMedicationTakenEditor(
                                context: context,
                                entry: entry,
                                scheduleEntries: entries,
                              );
                              if (draft == null) {
                                return;
                              }
                              await bootstrap.medicationCommandService
                                  .recordMedicationTaken(
                                    actorType: EventActorType.user,
                                    entry: entry,
                                    scheduledFor: draft.scheduledFor,
                                    takenAt: draft.takenAt,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Recorded ${entry.medicationName} at '
                                      '${formatTime(draft.takenAt)}.',
                                    ),
                                  ),
                                );
                              }
                            },
                            reminders: reminders
                                .where((reminder) {
                                  return reminder.status ==
                                      MedicationReminderStatus.upcoming;
                                })
                                .take(3)
                                .toList(growable: false),
                            subtitle:
                                'A quick look at what is still coming up later '
                                'today.',
                            title: 'Up next',
                          ),
                          const SizedBox(height: 16),
                          _RecentActivityCard(items: historyItems),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TodaySummary {
  const _TodaySummary({
    required this.completionRatio,
    required this.completionText,
    required this.dueNowCount,
    required this.nextLabel,
    required this.overdueCount,
    required this.pendingDraftCount,
    required this.takenCount,
    required this.totalDoseCount,
  });

  factory _TodaySummary.fromData({
    required ProposalView? proposal,
    required List<MedicationReminderView> reminders,
  }) {
    final overdueCount = reminders.where((reminder) {
      return reminder.status == MedicationReminderStatus.overdue;
    }).length;
    final dueNowCount = reminders.where((reminder) {
      return reminder.status == MedicationReminderStatus.dueNow;
    }).length;
    final takenCount = reminders.where((reminder) {
      return reminder.status == MedicationReminderStatus.taken;
    }).length;
    final totalDoseCount = reminders.length;

    String nextLabel = 'No upcoming medications';
    for (final reminder in reminders) {
      if (reminder.status == MedicationReminderStatus.taken) {
        continue;
      }
      nextLabel =
          '${reminder.entry.medicationName} at '
          '${formatTime(reminder.entry.dateTime)}';
      break;
    }

    return _TodaySummary(
      completionRatio: totalDoseCount == 0 ? 0 : takenCount / totalDoseCount,
      completionText: totalDoseCount == 0
          ? 'No confirmed doses scheduled today'
          : '$takenCount of $totalDoseCount doses recorded today',
      dueNowCount: dueNowCount,
      nextLabel: nextLabel,
      overdueCount: overdueCount,
      pendingDraftCount: proposal == null ? 0 : 1,
      takenCount: takenCount,
      totalDoseCount: totalDoseCount,
    );
  }

  final double completionRatio;
  final String completionText;
  final int dueNowCount;
  final String nextLabel;
  final int overdueCount;
  final int pendingDraftCount;
  final int takenCount;
  final int totalDoseCount;
}

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.summary});

  final _TodaySummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('At a glance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              summary.nextLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Today\'s progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: summary.completionRatio,
                backgroundColor: colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              summary.completionText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                _SummaryChip(
                  icon: Icons.error_outline,
                  label: '${summary.overdueCount} overdue',
                ),
                _SummaryChip(
                  icon: Icons.schedule_outlined,
                  label: '${summary.dueNowCount} due now',
                ),
                _SummaryChip(
                  icon: Icons.check_circle_outline,
                  label: '${summary.takenCount} taken',
                ),
                _SummaryChip(
                  icon: Icons.fact_check_outlined,
                  label: '${summary.pendingDraftCount} pending draft',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _ReminderSectionCard extends StatelessWidget {
  const _ReminderSectionCard({
    required this.emptyText,
    required this.onMarkTaken,
    required this.reminders,
    required this.subtitle,
    required this.title,
  });

  final String emptyText;
  final Future<void> Function(MedicationCalendarEntry entry) onMarkTaken;
  final List<MedicationReminderView> reminders;
  final String subtitle;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            if (reminders.isEmpty)
              Text(emptyText, style: Theme.of(context).textTheme.bodyMedium)
            else
              ...reminders.map(
                (reminder) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ReminderTile(
                    onMarkTaken: onMarkTaken,
                    reminder: reminder,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.onMarkTaken, required this.reminder});

  final Future<void> Function(MedicationCalendarEntry entry) onMarkTaken;
  final MedicationReminderView reminder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              reminder.entry.medicationName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '${formatTime(reminder.entry.dateTime)} • '
              '${reminder.entry.doseLabel}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            _ReminderStatusBadge(reminder: reminder),
            if (reminder.status != MedicationReminderStatus.taken) ...<Widget>[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: () => onMarkTaken(reminder.entry),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark taken'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReminderStatusBadge extends StatelessWidget {
  const _ReminderStatusBadge({required this.reminder});

  final MedicationReminderView reminder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (backgroundColor, foregroundColor) = switch (reminder.status) {
      MedicationReminderStatus.overdue => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      MedicationReminderStatus.dueNow => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      MedicationReminderStatus.upcoming => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
      MedicationReminderStatus.taken => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          _statusLabel(reminder),
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: foregroundColor),
        ),
      ),
    );
  }

  String _statusLabel(MedicationReminderView reminder) {
    if (reminder.status == MedicationReminderStatus.taken) {
      if (reminder.takenAt != null) {
        return 'Taken at ${formatTime(reminder.takenAt!)}';
      }
      return 'Taken';
    }
    return switch (reminder.status) {
      MedicationReminderStatus.overdue => 'Overdue',
      MedicationReminderStatus.dueNow => 'Due now',
      MedicationReminderStatus.upcoming => 'Up next',
      MedicationReminderStatus.taken => 'Taken',
    };
  }
}

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({
    required this.onReviewProposal,
    required this.proposal,
  });

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
            Text(
              'Pending review',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ExpandableText(
              proposal.summary,
              maxLines: 3,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'A draft is ready in Assistant. Review it before anything changes '
              'in the confirmed schedule.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReviewProposal,
              icon: const Icon(Icons.auto_awesome_outlined),
              label: const Text('Review draft'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.items});

  final List<HistoryTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Recent activity',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'A small preview of what changed most recently.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                'No activity yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: Icon(_iconForKind(item.kind)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(item.title),
                            const SizedBox(height: 4),
                            ExpandableText(
                              item.description,
                              maxLines: 2,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              formatTime(item.occurredAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            FilledButton.tonalIcon(
              onPressed: () => context.go('/history'),
              icon: const Icon(Icons.history_outlined),
              label: const Text('See full history'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForKind(HistoryTimelineItemKind kind) {
    return switch (kind) {
      HistoryTimelineItemKind.chat => Icons.chat_bubble_outline,
      HistoryTimelineItemKind.proposal => Icons.fact_check_outlined,
      HistoryTimelineItemKind.medication => Icons.medication_outlined,
      HistoryTimelineItemKind.adherence => Icons.check_circle_outline,
      HistoryTimelineItemKind.reminder => Icons.notifications_none,
      HistoryTimelineItemKind.system => Icons.info_outline,
    };
  }
}
