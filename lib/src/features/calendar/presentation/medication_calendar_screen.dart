import 'package:flutter/material.dart';

import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Medication Calendar',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Only confirmed schedules appear here. Pending proposals stay out of the calendar until approval.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.subtract(
                      const Duration(days: 1),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left),
                label: const Text('Previous'),
              ),
              const SizedBox(width: 12),
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _selectedDay = DateTime(2026, 4, 5);
                  });
                },
                child: Text(formatLongDate(_selectedDay)),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedDay = _selectedDay.add(const Duration(days: 1));
                  });
                },
                icon: const Icon(Icons.chevron_right),
                label: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<MedicationCalendarEntry>>(
              stream: bootstrap.medicationRepository.watchCalendarEntriesForDay(
                _selectedDay,
              ),
              builder: (context, snapshot) {
                final entries =
                    snapshot.data ?? const <MedicationCalendarEntry>[];
                if (entries.isEmpty) {
                  return const _EmptyCalendarState();
                }
                return ListView.separated(
                  itemCount: entries.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(20),
                        title: Text(entry.medicationName),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${formatTime(entry.dateTime)} • ${entry.doseLabel}\n'
                            '${entry.notes ?? 'No notes'}',
                          ),
                        ),
                        trailing: entry.threadId == null
                            ? null
                            : Chip(label: Text(entry.threadId!)),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No confirmed medication times for this day.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
