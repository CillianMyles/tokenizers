import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/core/presentation/expandable_text.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_taken_editor.dart';
import 'package:tokenizers/src/features/history/domain/history_timeline_models.dart';

/// Day-grouped activity history built from the immutable event log.
class ConversationHistoryScreen extends StatefulWidget {
  /// Creates the conversation history screen.
  const ConversationHistoryScreen({super.key});

  @override
  State<ConversationHistoryScreen> createState() =>
      _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  _HistoryFilter _selectedFilter = _HistoryFilter.all;

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
              final filteredGroups = _filterGroups(
                groups,
                filter: _selectedFilter,
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _HistoryFilterBar(
                    selectedFilter: _selectedFilter,
                    onFilterSelected: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: filteredGroups.isEmpty
                        ? _EmptyHistoryState(filter: _selectedFilter)
                        : ListView.separated(
                            itemCount: filteredGroups.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 20),
                            itemBuilder: (context, index) {
                              return _HistoryDaySection(
                                group: filteredGroups[index],
                              );
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

enum _HistoryFilter { all, assistant, medication, adherence }

class _HistoryFilterBar extends StatelessWidget {
  const _HistoryFilterBar({
    required this.onFilterSelected,
    required this.selectedFilter,
  });

  final ValueChanged<_HistoryFilter> onFilterSelected;
  final _HistoryFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactLabels = constraints.maxWidth < 420;
        return SegmentedButton<_HistoryFilter>(
          selected: <_HistoryFilter>{selectedFilter},
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            textStyle: WidgetStatePropertyAll(theme.textTheme.labelMedium),
          ),
          onSelectionChanged: (selection) {
            onFilterSelected(selection.first);
          },
          segments: _HistoryFilter.values
              .map((filter) {
                return ButtonSegment<_HistoryFilter>(
                  value: filter,
                  label: Text(
                    _labelForFilter(filter, compact: useCompactLabels),
                    overflow: TextOverflow.fade,
                    softWrap: false,
                  ),
                  tooltip: _labelForFilter(filter),
                );
              })
              .toList(growable: false),
        );
      },
    );
  }

  String _labelForFilter(_HistoryFilter filter, {bool compact = false}) {
    return switch (filter) {
      _HistoryFilter.all => 'All',
      _HistoryFilter.assistant => compact ? 'Chat' : 'Assistant',
      _HistoryFilter.medication => compact ? 'Meds' : 'Medication',
      _HistoryFilter.adherence => compact ? 'Taken' : 'Adherence',
    };
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.filter});

  final _HistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _messageForFilter(filter),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  String _messageForFilter(_HistoryFilter filter) {
    return switch (filter) {
      _HistoryFilter.all => 'No activity yet.',
      _HistoryFilter.assistant => 'No assistant activity yet.',
      _HistoryFilter.medication => 'No medication changes yet.',
      _HistoryFilter.adherence => 'No adherence activity yet.',
    };
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

List<HistoryTimelineDayGroup> _filterGroups(
  List<HistoryTimelineDayGroup> groups, {
  required _HistoryFilter filter,
}) {
  if (filter == _HistoryFilter.all) {
    return groups;
  }

  final filtered = <HistoryTimelineDayGroup>[];
  for (final group in groups) {
    final items = group.items
        .where((item) {
          return _matchesFilter(item.kind, filter: filter);
        })
        .toList(growable: false);
    if (items.isEmpty) {
      continue;
    }
    filtered.add(HistoryTimelineDayGroup(day: group.day, items: items));
  }
  return filtered;
}

bool _matchesFilter(
  HistoryTimelineItemKind kind, {
  required _HistoryFilter filter,
}) {
  return switch (filter) {
    _HistoryFilter.all => true,
    _HistoryFilter.assistant =>
      kind == HistoryTimelineItemKind.chat ||
          kind == HistoryTimelineItemKind.proposal ||
          kind == HistoryTimelineItemKind.system,
    _HistoryFilter.medication => kind == HistoryTimelineItemKind.medication,
    _HistoryFilter.adherence => kind == HistoryTimelineItemKind.adherence,
  };
}

class _HistoryEventCard extends StatelessWidget {
  const _HistoryEventCard({required this.item});

  final HistoryTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final canEditAdherence = item.adherenceAction != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: canEditAdherence ? () => _editAdherence(context) : null,
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
                      if (canEditAdherence) ...<Widget>[
                        const SizedBox(height: 6),
                        Text(
                          'Tap to edit',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
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
      ),
    );
  }

  Future<void> _editAdherence(BuildContext context) async {
    final action = item.adherenceAction;
    if (action == null) {
      return;
    }
    final bootstrap = AppScope.of(context);
    final entries = await bootstrap.medicationRepository
        .watchCalendarEntriesForDay(action.scheduledFor)
        .first;
    if (!context.mounted) {
      return;
    }
    final matchingEntries = entries
        .where((entry) {
          return entry.scheduleId == action.scheduleId;
        })
        .toList(growable: false);
    final selectedEntry = matchingEntries.firstWhere(
      (entry) => entry.dateTime == action.scheduledFor,
      orElse: () {
        return MedicationCalendarEntry(
          dateTime: action.scheduledFor,
          doseLabel: '',
          medicationName: action.medicationName,
          scheduleId: action.scheduleId,
          sourceProposalId: action.sourceProposalId,
          threadId: action.threadId,
        );
      },
    );
    final draft = await showMedicationTakenEditor(
      context: context,
      entry: selectedEntry,
      initialTakenAt: action.takenAt,
      scheduleEntries: matchingEntries.isEmpty
          ? <MedicationCalendarEntry>[selectedEntry]
          : matchingEntries,
    );
    if (draft == null) {
      return;
    }
    await bootstrap.medicationCommandService.correctMedicationTaken(
      actorType: EventActorType.user,
      entry: selectedEntry,
      previousTakenAt: action.takenAt,
      scheduledFor: draft.scheduledFor,
      takenAt: draft.takenAt,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Updated ${selectedEntry.medicationName} to '
            '${formatTime(draft.takenAt)}.',
          ),
        ),
      );
    }
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
