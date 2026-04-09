import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/core/presentation/expandable_text.dart';
import 'package:tokenizers/src/features/history/domain/history_timeline_models.dart';

/// Day-grouped activity history built from the immutable event log.
class ConversationHistoryScreen extends StatelessWidget {
  /// Creates the conversation history screen.
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: StreamBuilder(
            stream: bootstrap.eventStore.watchAll(),
            builder: (context, snapshot) {
              final events = snapshot.data ?? const [];
              final groups = buildHistoryTimeline(events);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: groups.isEmpty
                        ? const _EmptyHistoryState()
                        : ListView.separated(
                            itemCount: groups.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              return _HistoryDaySection(group: groups[index]);
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No activity yet.',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _HistoryDaySection extends StatelessWidget {
  const _HistoryDaySection({required this.group});

  final HistoryTimelineDayGroup group;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            formatLongDate(group.day),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 12),
        ...group.items.map((item) => _HistoryEventCard(item: item)),
      ],
    );
  }
}

class _HistoryEventCard extends StatelessWidget {
  const _HistoryEventCard({required this.item});

  final HistoryTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                    const SizedBox(height: 6),
                    ExpandableText(
                      item.description,
                      maxLines: 3,
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
