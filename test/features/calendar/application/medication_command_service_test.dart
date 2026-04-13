import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

void main() {
  group('MedicationCommandService', () {
    test(
      'addSchedule emits medication registration and schedule add events',
      () async {
        final eventStore = _FakeEventStore();
        final service = MedicationCommandService(eventStore: eventStore);

        await service.addSchedule(
          actorType: EventActorType.user,
          draft: MedicationScheduleDraft(
            doseAmount: '1000',
            doseUnit: 'IU',
            medicationName: 'Vitamin D',
            notes: 'Morning supplement',
            startDate: DateTime(2026, 4, 5),
            times: const <String>['09:00'],
          ),
        );

        expect(
          eventStore.events.map((event) => event.event.type).toList(),
          <String>['medication_registered', 'medication_schedule_added'],
        );
        expect(
          eventStore.events.last.event.payload['medication_name'],
          'Vitamin D',
        );
      },
    );

    test('addSchedule preserves per-time doses in the event payload', () async {
      final eventStore = _FakeEventStore();
      final service = MedicationCommandService(eventStore: eventStore);

      await service.addSchedule(
        actorType: EventActorType.user,
        draft: MedicationScheduleDraft(
          medicationName: 'Tacrolimus',
          startDate: DateTime(2026, 4, 5),
          times: const <String>['07:00', '19:00'],
          doseSchedule: const <MedicationDoseScheduleEntry>[
            MedicationDoseScheduleEntry(
              time: '07:00',
              doseAmount: '1.2',
              doseUnit: 'mg',
            ),
            MedicationDoseScheduleEntry(
              time: '19:00',
              doseAmount: '1.0',
              doseUnit: 'mg',
            ),
          ],
        ),
      );

      expect(
        eventStore.events.last.event.payload['dose_schedule'],
        <Map<String, Object?>>[
          <String, Object?>{
            'time': '07:00',
            'dose_amount': '1.2',
            'dose_unit': 'mg',
          },
          <String, Object?>{
            'time': '19:00',
            'dose_amount': '1.0',
            'dose_unit': 'mg',
          },
        ],
      );
    });

    test(
      'updateSchedule emits medication_schedule_updated for same-name edits',
      () async {
        final eventStore = _FakeEventStore();
        final service = MedicationCommandService(eventStore: eventStore);

        await service.updateSchedule(
          actorType: EventActorType.user,
          draft: MedicationScheduleDraft(
            doseAmount: '750',
            doseUnit: 'mg',
            medicationName: 'Metformin',
            notes: 'Take with breakfast and dinner',
            startDate: DateTime(2026, 4, 6),
            times: const <String>['09:00', '21:00'],
          ),
          existingSchedule: MedicationScheduleView(
            doseAmount: '500',
            doseUnit: 'mg',
            medicationName: 'Metformin',
            scheduleId: 'schedule-1',
            startDate: DateTime(2026, 4, 5),
            times: const <String>['08:00', '20:00'],
          ),
        );

        expect(
          eventStore.events.map((event) => event.event.type).toList(),
          <String>['medication_schedule_updated'],
        );
        expect(eventStore.events.single.event.payload['dose_amount'], '750');
      },
    );

    test(
      'updateSchedule emits stop plus add when medication name changes',
      () async {
        final eventStore = _FakeEventStore();
        final service = MedicationCommandService(eventStore: eventStore);

        await service.updateSchedule(
          actorType: EventActorType.user,
          draft: MedicationScheduleDraft(
            doseAmount: '20',
            doseUnit: 'mg',
            medicationName: 'Omeprazole',
            startDate: DateTime(2026, 4, 7),
            times: const <String>['08:00'],
          ),
          existingSchedule: MedicationScheduleView(
            doseAmount: '500',
            doseUnit: 'mg',
            medicationName: 'Metformin',
            scheduleId: 'schedule-1',
            startDate: DateTime(2026, 4, 5),
            times: const <String>['08:00'],
          ),
        );

        expect(
          eventStore.events.map((event) => event.event.type).toList(),
          <String>[
            'medication_schedule_stopped',
            'medication_registered',
            'medication_schedule_added',
          ],
        );
      },
    );

    test('recordMedicationTaken emits a medication_taken event', () async {
      final eventStore = _FakeEventStore();
      final service = MedicationCommandService(eventStore: eventStore);
      final recordedAt = DateTime(2026, 4, 9, 11, 30);
      final scheduledFor = DateTime(2026, 4, 9, 9, 0);
      final takenAt = DateTime(2026, 4, 9, 9, 3);

      await service.recordMedicationTaken(
        actorType: EventActorType.user,
        entry: MedicationCalendarEntry(
          dateTime: DateTime(2026, 4, 9, 9),
          doseLabel: '1000 IU',
          medicationName: 'Vitamin D',
          scheduleId: 'schedule-1',
          threadId: 'thread-1',
        ),
        recordedAt: recordedAt,
        scheduledFor: scheduledFor,
        takenAt: takenAt,
      );

      expect(
        eventStore.events.map((event) => event.event.type).toList(),
        <String>['medication_taken'],
      );
      expect(eventStore.events.single.occurredAt, recordedAt);
      expect(
        eventStore.events.single.event.payload['recorded_at'],
        '2026-04-09T11:30:00.000',
      );
      expect(
        eventStore.events.single.event.payload['scheduled_for'],
        '2026-04-09T09:00:00.000',
      );
      expect(
        eventStore.events.single.event.payload['taken_at'],
        '2026-04-09T09:03:00.000',
      );
    });

    test('correctMedicationTaken emits a correction event', () async {
      final eventStore = _FakeEventStore();
      final service = MedicationCommandService(eventStore: eventStore);

      await service.correctMedicationTaken(
        actorType: EventActorType.user,
        entry: MedicationCalendarEntry(
          dateTime: DateTime(2026, 4, 9, 9),
          doseLabel: '1000 IU',
          medicationName: 'Vitamin D',
          scheduleId: 'schedule-1',
          threadId: 'thread-1',
        ),
        previousTakenAt: DateTime(2026, 4, 9, 9, 3),
        takenAt: DateTime(2026, 4, 9, 9, 12),
      );

      expect(eventStore.events.single.event.type, 'medication_taken_corrected');
      expect(
        eventStore.events.single.event.payload['previous_scheduled_for'],
        '2026-04-09T09:00:00.000',
      );
      expect(
        eventStore.events.single.event.payload['previous_taken_at'],
        '2026-04-09T09:03:00.000',
      );
      expect(
        eventStore.events.single.event.payload['taken_at'],
        '2026-04-09T09:12:00.000',
      );
    });
  });
}

class _FakeEventStore implements EventStore {
  final List<EventEnvelope<DomainEvent>> events =
      <EventEnvelope<DomainEvent>>[];

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> newEvents) async {
    events.addAll(newEvents);
  }

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    return List<EventEnvelope<DomainEvent>>.unmodifiable(events);
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(
      List<EventEnvelope<DomainEvent>>.unmodifiable(events),
    );
  }
}
