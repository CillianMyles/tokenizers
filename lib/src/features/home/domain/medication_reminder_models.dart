import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Visual status for a medication reminder on the Home surface.
enum MedicationReminderStatus { overdue, dueNow, upcoming, taken }

/// A single reminder derived from today's medication schedule entries.
class MedicationReminderView {
  /// Creates a reminder view.
  const MedicationReminderView({
    required this.entry,
    required this.status,
    this.takenAt,
  });

  /// Source medication entry.
  final MedicationCalendarEntry entry;

  /// Reminder status.
  final MedicationReminderStatus status;

  /// When the dose was recorded as taken, if known.
  final DateTime? takenAt;
}

/// Builds reminder cards for a day's entries based on recorded adherence.
List<MedicationReminderView> buildMedicationReminders({
  required List<MedicationCalendarEntry> entries,
  required List<EventEnvelope<DomainEvent>> events,
  required DateTime now,
}) {
  final takenByKey = <String, DateTime>{};
  for (final event in events) {
    if (event.event.type != 'medication_taken' &&
        event.event.type != 'medication_taken_corrected') {
      continue;
    }
    final payload = event.event.payload;
    final scheduleId = payload['schedule_id'] as String?;
    final scheduledFor = _parseScheduledFor(payload['scheduled_for']);
    if (scheduleId == null || scheduledFor == null) {
      continue;
    }
    final key = _entryKey(
      scheduleId: scheduleId,
      scheduledFor: DateTime(
        scheduledFor.year,
        scheduledFor.month,
        scheduledFor.day,
        scheduledFor.hour,
        scheduledFor.minute,
      ),
    );
    final takenAt = _parseDateTime(payload['taken_at']) ?? event.occurredAt;
    takenByKey[key] = takenAt;
  }

  final reminders =
      entries
          .map((entry) {
            final scheduledFor = DateTime(
              entry.dateTime.year,
              entry.dateTime.month,
              entry.dateTime.day,
              entry.dateTime.hour,
              entry.dateTime.minute,
            );
            final key = _entryKey(
              scheduleId: entry.scheduleId,
              scheduledFor: scheduledFor,
            );
            final takenAt = takenByKey[key];
            final status = _statusForReminder(
              scheduledFor: scheduledFor,
              takenAt: takenAt,
              now: now,
            );
            return MedicationReminderView(
              entry: entry,
              status: status,
              takenAt: takenAt,
            );
          })
          .toList(growable: false)
        ..sort((left, right) {
          final statusCompare = _statusPriority(
            left.status,
          ).compareTo(_statusPriority(right.status));
          if (statusCompare != 0) {
            return statusCompare;
          }
          return left.entry.dateTime.compareTo(right.entry.dateTime);
        });

  return reminders;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

DateTime? _parseScheduledFor(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  if (value.contains('T')) {
    return DateTime.tryParse(value);
  }
  final parts = value.split(':');
  if (parts.length != 2) {
    return null;
  }
  final now = DateTime.now();
  return DateTime(
    now.year,
    now.month,
    now.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

String _entryKey({required String scheduleId, required DateTime scheduledFor}) {
  return '$scheduleId@${scheduledFor.toIso8601String()}';
}

int _statusPriority(MedicationReminderStatus status) {
  return switch (status) {
    MedicationReminderStatus.overdue => 0,
    MedicationReminderStatus.dueNow => 1,
    MedicationReminderStatus.upcoming => 2,
    MedicationReminderStatus.taken => 3,
  };
}

MedicationReminderStatus _statusForReminder({
  required DateTime scheduledFor,
  required DateTime? takenAt,
  required DateTime now,
}) {
  if (takenAt != null) {
    return MedicationReminderStatus.taken;
  }

  final difference = scheduledFor.difference(now);
  if (difference.inMinutes > 30) {
    return MedicationReminderStatus.upcoming;
  }
  if (difference.inMinutes >= -30) {
    return MedicationReminderStatus.dueNow;
  }
  return MedicationReminderStatus.overdue;
}
