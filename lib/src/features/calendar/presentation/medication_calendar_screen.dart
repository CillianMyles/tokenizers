import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/presentation/medication_schedule_editor.dart';

/// Day-based calendar view for confirmed medication schedules.
class MedicationCalendarScreen extends StatefulWidget {
  /// Creates the medication calendar screen.
  const MedicationCalendarScreen({super.key});

  @override
  State<MedicationCalendarScreen> createState() =>
      _MedicationCalendarScreenState();
}

class _MedicationCalendarScreenState extends State<MedicationCalendarScreen> {
  DateTime _selectedDay = DateTime(2026, 4, 5);

  @override
  Widget build(BuildContext context) {
    final bootstrap = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  IconButton.outlined(
                    tooltip: 'Previous day',
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.subtract(
                          const Duration(days: 1),
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          _selectedDay = DateTime(2026, 4, 5);
                        });
                      },
                      child: Text(formatLongDate(_selectedDay)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    tooltip: 'Next day',
                    onPressed: () {
                      setState(() {
                        _selectedDay = _selectedDay.add(
                          const Duration(days: 1),
                        );
                      });
                    },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      StreamBuilder<List<MedicationCalendarEntry>>(
                        stream: bootstrap.medicationRepository
                            .watchCalendarEntriesForDay(_selectedDay),
                        builder: (context, snapshot) {
                          final entries =
                              snapshot.data ??
                              const <MedicationCalendarEntry>[];
                          return _CalendarEntriesSection(
                            entries: entries,
                            onMarkTaken: (entry) async {
                              await bootstrap.medicationCommandService
                                  .recordMedicationTaken(
                                    actorType: EventActorType.user,
                                    entry: entry,
                                  );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Recorded ${entry.medicationName} as taken.',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      StreamBuilder<List<MedicationScheduleView>>(
                        stream: bootstrap.medicationRepository
                            .watchActiveSchedules(),
                        builder: (context, snapshot) {
                          final schedules =
                              snapshot.data ?? const <MedicationScheduleView>[];
                          return _ActiveSchedulesSection(
                            onAddMedication: () async {
                              final draft = await showMedicationScheduleEditor(
                                context: context,
                                initialDraft: MedicationScheduleDraft(
                                  medicationName: '',
                                  startDate: _selectedDay,
                                  times: const <String>[],
                                ),
                                submitLabel: 'Add medication',
                                title: 'Add medication',
                              );
                              if (draft == null) {
                                return;
                              }
                              await bootstrap.medicationCommandService
                                  .addSchedule(
                                    actorType: EventActorType.user,
                                    draft: draft,
                                  );
                            },
                            onEditSchedule: (schedule) async {
                              final draft = await showMedicationScheduleEditor(
                                context: context,
                                initialDraft:
                                    MedicationScheduleDraft.fromSchedule(
                                      schedule,
                                    ),
                                submitLabel: 'Save changes',
                                title: 'Edit medication',
                              );
                              if (draft == null) {
                                return;
                              }
                              await bootstrap.medicationCommandService
                                  .updateSchedule(
                                    actorType: EventActorType.user,
                                    draft: draft,
                                    existingSchedule: schedule,
                                  );
                            },
                            onRemoveSchedule: (schedule) async {
                              final shouldRemove =
                                  await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Remove medication?'),
                                        content: Text(
                                          'Stop ${schedule.medicationName} and '
                                          'remove it from active schedules?',
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(false);
                                            },
                                            child: const Text('Keep'),
                                          ),
                                          FilledButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(true);
                                            },
                                            child: const Text('Remove'),
                                          ),
                                        ],
                                      );
                                    },
                                  ) ??
                                  false;
                              if (!shouldRemove) {
                                return;
                              }
                              await bootstrap.medicationCommandService
                                  .removeSchedule(
                                    actorType: EventActorType.user,
                                    existingSchedule: schedule,
                                  );
                            },
                            schedules: schedules,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSchedulesSection extends StatelessWidget {
  const _ActiveSchedulesSection({
    required this.onAddMedication,
    required this.onEditSchedule,
    required this.onRemoveSchedule,
    required this.schedules,
  });

  final Future<void> Function() onAddMedication;
  final Future<void> Function(MedicationScheduleView schedule) onEditSchedule;
  final Future<void> Function(MedicationScheduleView schedule) onRemoveSchedule;
  final List<MedicationScheduleView> schedules;

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
                    'Active medications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onAddMedication,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage confirmed schedules directly here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (schedules.isEmpty)
              Text(
                'No active medications yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ListView.separated(
                itemCount: schedules.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            schedule.medicationName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(schedule.doseScheduleSummary),
                          const SizedBox(height: 4),
                          Text(
                            'Starts ${formatShortDate(schedule.startDate)}'
                            '${schedule.notes == null ? '' : '\n${schedule.notes}'}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () => onEditSchedule(schedule),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () => onRemoveSchedule(schedule),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Remove'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarEntriesSection extends StatelessWidget {
  const _CalendarEntriesSection({
    required this.entries,
    required this.onMarkTaken,
  });

  final List<MedicationCalendarEntry> entries;
  final Future<void> Function(MedicationCalendarEntry entry) onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Today’s doses',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Pending chat drafts stay out of this list until you accept them.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              Text(
                'No confirmed medication times for this day.',
                style: Theme.of(context).textTheme.titleMedium,
              )
            else
              ListView.separated(
                itemCount: entries.length,
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            entry.medicationName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${formatTime(entry.dateTime)} • ${entry.doseLabel}\n'
                            '${entry.notes ?? 'No notes'}',
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              FilledButton.tonalIcon(
                                onPressed: () => onMarkTaken(entry),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Taken'),
                              ),
                              if (entry.threadId
                                  case final threadId?) ...<Widget>[
                                const SizedBox(width: 12),
                                Chip(label: Text(threadId)),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
