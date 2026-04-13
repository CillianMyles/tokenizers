import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';

/// The current resolved state of a logged medication dose.
class ResolvedMedicationTakenEvent {
  /// Creates a resolved medication adherence event.
  const ResolvedMedicationTakenEvent({
    required this.eventId,
    required this.scheduleId,
    required this.scheduledFor,
    required this.takenAt,
  });

  /// The event id for the latest event representing this dose.
  final String eventId;

  /// The schedule id for the medication dose.
  final String scheduleId;

  /// The resolved scheduled slot for this dose.
  final DateTime scheduledFor;

  /// The resolved taken time for this dose.
  final DateTime takenAt;
}

/// Resolves the current taken-dose state from adherence events.
///
/// Corrections supersede the previously logged slot when
/// `previous_scheduled_for` is present. For older events that do not include
/// it, the resolver falls back to matching `previous_taken_at`.
Map<String, ResolvedMedicationTakenEvent> resolveMedicationTakenByDoseKey(
  List<EventEnvelope<DomainEvent>> events,
) {
  final indexedEvents =
      events.indexed
          .where((entry) => _isAdherenceEvent(entry.$2))
          .toList(growable: false)
        ..sort((left, right) {
          final occurredCompare = left.$2.occurredAt.compareTo(
            right.$2.occurredAt,
          );
          if (occurredCompare != 0) {
            return occurredCompare;
          }
          final typeCompare = _eventPriority(
            left.$2.event.type,
          ).compareTo(_eventPriority(right.$2.event.type));
          if (typeCompare != 0) {
            return typeCompare;
          }
          return left.$1.compareTo(right.$1);
        });

  final activeByKey = <String, ResolvedMedicationTakenEvent>{};
  for (final (_, envelope) in indexedEvents) {
    final payload = envelope.event.payload;
    final scheduleId = payload['schedule_id'] as String?;
    final scheduledFor = _parseDateTime(payload['scheduled_for']);
    if (scheduleId == null || scheduledFor == null) {
      continue;
    }

    if (envelope.event.type == 'medication_taken_corrected') {
      final previousScheduledFor = _parseDateTime(
        payload['previous_scheduled_for'],
      );
      if (previousScheduledFor != null) {
        activeByKey.remove(
          medicationDoseKey(
            scheduleId: scheduleId,
            scheduledFor: previousScheduledFor,
          ),
        );
      } else {
        final previousTakenAt = _parseDateTime(payload['previous_taken_at']);
        if (previousTakenAt != null) {
          final previousKey = _findKeyByPreviousTakenAt(
            activeByKey: activeByKey,
            previousTakenAt: previousTakenAt,
            scheduleId: scheduleId,
          );
          if (previousKey != null) {
            activeByKey.remove(previousKey);
          }
        }
      }
    }

    final takenAt = _parseDateTime(payload['taken_at']) ?? envelope.occurredAt;
    activeByKey[medicationDoseKey(
      scheduleId: scheduleId,
      scheduledFor: scheduledFor,
    )] = ResolvedMedicationTakenEvent(
      eventId: envelope.eventId,
      scheduleId: scheduleId,
      scheduledFor: scheduledFor,
      takenAt: takenAt,
    );
  }
  return activeByKey;
}

/// Returns the ids of adherence events that remain current after corrections.
Set<String> latestMedicationTakenEventIds(
  List<EventEnvelope<DomainEvent>> events,
) {
  return resolveMedicationTakenByDoseKey(
    events,
  ).values.map((event) => event.eventId).toSet();
}

/// Normalized key for a scheduled medication dose.
String medicationDoseKey({
  required String scheduleId,
  required DateTime scheduledFor,
}) {
  final normalized = DateTime(
    scheduledFor.year,
    scheduledFor.month,
    scheduledFor.day,
    scheduledFor.hour,
    scheduledFor.minute,
  );
  return '$scheduleId@${normalized.toIso8601String()}';
}

String? _findKeyByPreviousTakenAt({
  required Map<String, ResolvedMedicationTakenEvent> activeByKey,
  required DateTime previousTakenAt,
  required String scheduleId,
}) {
  for (final entry in activeByKey.entries) {
    if (entry.value.scheduleId != scheduleId) {
      continue;
    }
    if (_isSameMinute(entry.value.takenAt, previousTakenAt)) {
      return entry.key;
    }
  }
  return null;
}

bool _isAdherenceEvent(EventEnvelope<DomainEvent> event) {
  return event.event.type == 'medication_taken' ||
      event.event.type == 'medication_taken_corrected';
}

bool _isSameMinute(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day &&
      left.hour == right.hour &&
      left.minute == right.minute;
}

DateTime? _parseDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

int _eventPriority(String eventType) {
  return switch (eventType) {
    'medication_taken' => 0,
    'medication_taken_corrected' => 1,
    _ => 2,
  };
}
