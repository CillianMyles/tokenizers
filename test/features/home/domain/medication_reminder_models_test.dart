import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/home/domain/medication_reminder_models.dart';

void main() {
  group('buildMedicationReminders', () {
    test('classifies reminders by due state and taken state', () {
      final reminders = buildMedicationReminders(
        entries: <MedicationCalendarEntry>[
          MedicationCalendarEntry(
            dateTime: DateTime(2026, 4, 9, 8, 0),
            doseLabel: '500 mg',
            medicationName: 'Metformin',
            scheduleId: 'schedule-1',
          ),
          MedicationCalendarEntry(
            dateTime: DateTime(2026, 4, 9, 9, 0),
            doseLabel: '1000 IU',
            medicationName: 'Vitamin D',
            scheduleId: 'schedule-2',
          ),
          MedicationCalendarEntry(
            dateTime: DateTime(2026, 4, 9, 12, 0),
            doseLabel: '250 mg',
            medicationName: 'Magnesium',
            scheduleId: 'schedule-3',
          ),
        ],
        events: <EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-1',
            eventType: 'medication_taken',
            occurredAt: DateTime(2026, 4, 9, 8, 5),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_name': 'Metformin',
              'scheduled_for': '2026-04-09T08:00:00.000',
              'taken_at': '2026-04-09T08:05:00.000',
            },
          ),
        ],
        now: DateTime(2026, 4, 9, 9, 10),
      );

      expect(reminders[0].status, MedicationReminderStatus.dueNow);
      expect(reminders[0].entry.medicationName, 'Vitamin D');
      expect(reminders[1].status, MedicationReminderStatus.upcoming);
      expect(reminders[2].status, MedicationReminderStatus.taken);
      expect(reminders[2].takenAt, DateTime(2026, 4, 9, 8, 5));
    });

    test('uses corrected taken events as the latest adherence state', () {
      final reminders = buildMedicationReminders(
        entries: <MedicationCalendarEntry>[
          MedicationCalendarEntry(
            dateTime: DateTime(2026, 4, 9, 8, 0),
            doseLabel: '500 mg',
            medicationName: 'Metformin',
            scheduleId: 'schedule-1',
          ),
        ],
        events: <EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-1',
            eventType: 'medication_taken',
            occurredAt: DateTime(2026, 4, 9, 8, 5),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_name': 'Metformin',
              'scheduled_for': '2026-04-09T08:00:00.000',
              'taken_at': '2026-04-09T08:05:00.000',
            },
          ),
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-2',
            eventType: 'medication_taken_corrected',
            occurredAt: DateTime(2026, 4, 9, 8, 10),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_name': 'Metformin',
              'scheduled_for': '2026-04-09T08:00:00.000',
              'taken_at': '2026-04-09T08:12:00.000',
            },
          ),
        ],
        now: DateTime(2026, 4, 9, 9, 10),
      );

      expect(reminders.single.status, MedicationReminderStatus.taken);
      expect(reminders.single.takenAt, DateTime(2026, 4, 9, 8, 12));
    });
  });
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: 'medication',
    aggregateId: aggregateId,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}
