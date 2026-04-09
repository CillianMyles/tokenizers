import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
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
