import 'package:flutter/material.dart';

import 'package:tokenizers/src/core/presentation/date_formatters.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// A user-confirmed adherence record before it is written to the event log.
class MedicationTakenDraft {
  /// Creates a medication taken draft.
  const MedicationTakenDraft({
    required this.scheduledFor,
    required this.takenAt,
  });

  /// The scheduled dose time being marked as taken.
  final DateTime scheduledFor;

  /// The actual time the medication was taken.
  final DateTime takenAt;
}

/// Opens a sheet for choosing which dose was taken and when it was taken.
Future<MedicationTakenDraft?> showMedicationTakenEditor({
  required BuildContext context,
  required MedicationCalendarEntry entry,
  required List<MedicationCalendarEntry> scheduleEntries,
}) {
  final sameScheduleEntries =
      scheduleEntries
          .where((candidate) => candidate.scheduleId == entry.scheduleId)
          .toList(growable: false)
        ..sort((left, right) => left.dateTime.compareTo(right.dateTime));

  final width = MediaQuery.sizeOf(context).width;
  if (width < 720) {
    return showModalBottomSheet<MedicationTakenDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _MedicationTakenEditorSurface(
          initialEntry: entry,
          scheduleEntries: sameScheduleEntries,
        );
      },
    );
  }

  return showDialog<MedicationTakenDraft>(
    context: context,
    builder: (context) {
      return Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _MedicationTakenEditorSurface(
            initialEntry: entry,
            scheduleEntries: sameScheduleEntries,
          ),
        ),
      );
    },
  );
}

class _MedicationTakenEditorSurface extends StatefulWidget {
  const _MedicationTakenEditorSurface({
    required this.initialEntry,
    required this.scheduleEntries,
  });

  final MedicationCalendarEntry initialEntry;
  final List<MedicationCalendarEntry> scheduleEntries;

  @override
  State<_MedicationTakenEditorSurface> createState() =>
      _MedicationTakenEditorSurfaceState();
}

class _MedicationTakenEditorSurfaceState
    extends State<_MedicationTakenEditorSurface> {
  late MedicationCalendarEntry _selectedEntry;
  late DateTime _takenAt;

  @override
  void initState() {
    super.initState();
    _selectedEntry = widget.initialEntry;
    final now = DateTime.now();
    final isSameDay =
        now.year == widget.initialEntry.dateTime.year &&
        now.month == widget.initialEntry.dateTime.month &&
        now.day == widget.initialEntry.dateTime.day;
    _takenAt = isSameDay ? now : widget.initialEntry.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Record taken', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              widget.initialEntry.medicationName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              formatLongDate(widget.initialEntry.dateTime),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Scheduled dose',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.scheduleEntries
                  .map((candidate) {
                    return ChoiceChip(
                      label: Text(
                        '${formatTime(candidate.dateTime)} • ${candidate.doseLabel}',
                      ),
                      selected:
                          candidate.scheduleId == _selectedEntry.scheduleId &&
                          candidate.dateTime == _selectedEntry.dateTime,
                      onSelected: (_) {
                        setState(() {
                          _selectedEntry = candidate;
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 20),
            Text('Taken at', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTakenTime(context),
                    icon: const Icon(Icons.schedule_outlined),
                    label: Text(formatTime(_takenAt)),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _takenAt = _selectedEntry.dateTime;
                    });
                  },
                  child: const Text('Use scheduled time'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This will record ${_selectedEntry.medicationName} for '
              '${formatTime(_selectedEntry.dateTime)} as taken at '
              '${formatTime(_takenAt)}.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        MedicationTakenDraft(
                          scheduledFor: _selectedEntry.dateTime,
                          takenAt: _takenAt,
                        ),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTakenTime(BuildContext context) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _takenAt.hour, minute: _takenAt.minute),
    );
    if (selectedTime == null) {
      return;
    }
    setState(() {
      _takenAt = DateTime(
        _selectedEntry.dateTime.year,
        _selectedEntry.dateTime.month,
        _selectedEntry.dateTime.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    });
  }
}
