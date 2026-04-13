import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/features/adherence/domain/adherence_calculator.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

void main() {
  final today = DateTime(2026, 4, 13, 12);

  MedicationScheduleView schedule({
    required String id,
    required String name,
    required List<String> times,
    required DateTime startDate,
    String? doseAmount,
    String? doseUnit,
    DateTime? endDate,
  }) {
    return MedicationScheduleView(
      scheduleId: id,
      medicationName: name,
      times: times,
      startDate: startDate,
      doseAmount: doseAmount,
      doseUnit: doseUnit,
      endDate: endDate,
      doseSchedule: times
          .map(
            (time) => MedicationDoseScheduleEntry(
              time: time,
              doseAmount: doseAmount,
              doseUnit: doseUnit,
            ),
          )
          .toList(),
    );
  }

  EventEnvelope<DomainEvent> takenEvent({
    required String scheduleId,
    required DateTime scheduledFor,
    String type = 'medication_taken',
  }) {
    return EventEnvelope<DomainEvent>(
      eventId: 'event-$scheduleId-${scheduledFor.toIso8601String()}-$type',
      aggregateType: 'medication',
      aggregateId: scheduleId,
      actorType: EventActorType.user,
      event: DomainEvent(
        type: type,
        payload: <String, Object?>{
          'schedule_id': scheduleId,
          'scheduled_for': scheduledFor.toIso8601String(),
          'taken_at': scheduledFor
              .add(const Duration(minutes: 5))
              .toIso8601String(),
          'medication_name': 'Test',
        },
      ),
      occurredAt: scheduledFor.add(const Duration(minutes: 5)),
    );
  }

  test('returns empty summary when no schedules exist', () {
    final result = calculateAdherence(
      schedules: const <MedicationScheduleView>[],
      events: const <EventEnvelope<DomainEvent>>[],
      today: today,
    );

    expect(result.isEmpty, isTrue);
    expect(result.overallRate, 0);
    expect(result.byMedication, isEmpty);
    expect(result.dailyBreakdown, hasLength(7));
  });

  test('includes today but ignores upcoming doses', () {
    final med = schedule(
      id: 'sched-1',
      name: 'Metformin',
      times: const <String>['08:00', '20:00'],
      startDate: DateTime(2026, 3, 1),
    );
    final events = <EventEnvelope<DomainEvent>>[];

    for (var offset = 6; offset >= 1; offset--) {
      final day = DateTime(today.year, today.month, today.day - offset);
      events.add(
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(day.year, day.month, day.day, 8),
        ),
      );
      events.add(
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(day.year, day.month, day.day, 20),
        ),
      );
    }
    events.add(
      takenEvent(
        scheduleId: med.scheduleId,
        scheduledFor: DateTime(today.year, today.month, today.day, 8),
      ),
    );

    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[med],
      events: events,
      today: today,
    );

    expect(result.totalScheduledDoses, 13);
    expect(result.totalTakenDoses, 13);
    expect(result.overallRate, 1.0);
    expect(result.byMedication.single.currentStreak, 7);
    expect(result.dailyBreakdown.last.scheduledDoses, 1);
    expect(result.dailyBreakdown.last.takenDoses, 1);
  });

  test('counts the current streak even when earlier days were missed', () {
    final med = schedule(
      id: 'sched-1',
      name: 'Vitamin D',
      times: const <String>['09:00'],
      startDate: DateTime(2026, 3, 1),
    );
    final events = <EventEnvelope<DomainEvent>>[];

    for (final offset in <int>[0, 1, 2, 4, 5, 6]) {
      final day = DateTime(today.year, today.month, today.day - offset);
      events.add(
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(day.year, day.month, day.day, 9),
        ),
      );
    }

    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[med],
      events: events,
      today: today,
    );

    expect(result.totalScheduledDoses, 7);
    expect(result.totalTakenDoses, 6);
    expect(result.byMedication.single.currentStreak, 3);
  });

  test('aggregates multiple schedules under one medication name', () {
    final morning = schedule(
      id: 'sched-am',
      name: 'Metformin',
      times: const <String>['08:00'],
      startDate: DateTime(2026, 3, 1),
    );
    final evening = schedule(
      id: 'sched-pm',
      name: 'Metformin',
      times: const <String>['20:00'],
      startDate: DateTime(2026, 3, 1),
    );

    final endOfDay = DateTime(2026, 4, 13, 23, 59);
    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[morning, evening],
      events: <EventEnvelope<DomainEvent>>[
        takenEvent(
          scheduleId: morning.scheduleId,
          scheduledFor: DateTime(2026, 4, 13, 8),
        ),
        takenEvent(
          scheduleId: evening.scheduleId,
          scheduledFor: DateTime(2026, 4, 13, 20),
        ),
      ],
      today: endOfDay,
      lookbackDays: 1,
    );

    expect(result.byMedication, hasLength(1));
    expect(result.byMedication.single.medicationName, 'Metformin');
    expect(result.byMedication.single.scheduledDoses, 2);
    expect(result.byMedication.single.takenDoses, 2);
    expect(result.byMedication.single.currentStreak, 1);
  });

  test('includes recently stopped medications that overlap the window', () {
    final med = schedule(
      id: 'sched-stop',
      name: 'Omeprazole',
      times: const <String>['08:00'],
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 4, 12),
    );

    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[med],
      events: <EventEnvelope<DomainEvent>>[
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(2026, 4, 11, 8),
        ),
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(2026, 4, 12, 8),
        ),
      ],
      today: today,
      lookbackDays: 3,
    );

    expect(result.byMedication, hasLength(1));
    expect(result.byMedication.single.medicationName, 'Omeprazole');
    expect(result.totalScheduledDoses, 2);
    expect(result.totalTakenDoses, 2);
    expect(result.byMedication.single.currentStreak, 2);
  });

  test('counts medication_taken_corrected events as taken', () {
    final med = schedule(
      id: 'sched-1',
      name: 'Corrected',
      times: const <String>['08:00'],
      startDate: DateTime(2026, 3, 1),
    );

    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[med],
      events: <EventEnvelope<DomainEvent>>[
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(2026, 4, 13, 8),
          type: 'medication_taken_corrected',
        ),
      ],
      today: today,
      lookbackDays: 1,
    );

    expect(result.totalTakenDoses, 1);
    expect(result.totalScheduledDoses, 1);
  });

  test('does not count superseded scheduled slots after a correction', () {
    final med = schedule(
      id: 'sched-1',
      name: 'Vitamin D',
      times: const <String>['09:00', '21:00'],
      startDate: DateTime(2026, 3, 1),
    );

    final result = calculateAdherence(
      schedules: <MedicationScheduleView>[med],
      events: <EventEnvelope<DomainEvent>>[
        takenEvent(
          scheduleId: med.scheduleId,
          scheduledFor: DateTime(2026, 4, 13, 9),
        ),
        EventEnvelope<DomainEvent>(
          eventId: 'event-corrected',
          aggregateType: 'medication',
          aggregateId: med.scheduleId,
          actorType: EventActorType.user,
          event: DomainEvent(
            type: 'medication_taken_corrected',
            payload: <String, Object?>{
              'previous_scheduled_for': DateTime(
                2026,
                4,
                13,
                9,
              ).toIso8601String(),
              'previous_taken_at': DateTime(
                2026,
                4,
                13,
                9,
                5,
              ).toIso8601String(),
              'schedule_id': med.scheduleId,
              'scheduled_for': DateTime(2026, 4, 13, 21).toIso8601String(),
              'taken_at': DateTime(2026, 4, 13, 21, 10).toIso8601String(),
            },
          ),
          occurredAt: DateTime(2026, 4, 13, 21, 10),
        ),
      ],
      today: DateTime(2026, 4, 13, 23, 59),
      lookbackDays: 1,
    );

    expect(result.totalScheduledDoses, 2);
    expect(result.totalTakenDoses, 1);
    expect(result.byMedication.single.currentStreak, 0);
  });
}
