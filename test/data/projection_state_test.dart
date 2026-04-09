import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/data/projection_state.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

void main() {
  group('ProjectionState.fromEvents', () {
    test('keeps new proposals pending until confirmation', () {
      final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-1',
          eventType: 'thread_started',
          occurredAt: DateTime(2026, 4, 5, 8),
          payload: const <String, Object?>{
            'thread_id': 'thread-1',
            'title': 'Morning capture',
          },
        ),
        _event(
          actorType: EventActorType.model,
          aggregateId: 'proposal-1',
          eventId: 'event-2',
          eventType: 'proposal_created',
          occurredAt: DateTime(2026, 4, 5, 8, 1),
          payload: const <String, Object?>{
            'proposal_id': 'proposal-1',
            'thread_id': 'thread-1',
            'summary': 'Add ibuprofen 200 mg at 08:00.',
            'assistant_text': 'Review the ibuprofen schedule.',
            'actions': <Map<String, Object?>>[
              <String, Object?>{
                'action_id': 'action-1',
                'type': 'add_medication_schedule',
                'medication_name': 'Ibuprofen',
                'dose_amount': '200',
                'dose_unit': 'mg',
                'start_date': '2026-04-05',
                'times': <String>['08:00'],
              },
            ],
          },
        ),
      ]);

      final thread = state.threads.single;
      final pending = state.pendingProposalsByThread['thread-1'];

      expect(thread.pendingProposalCount, 1);
      expect(pending?.proposalId, 'proposal-1');
      expect(state.activeSchedules, isEmpty);
    });

    test('projects confirmed schedules into day entries', () {
      final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-1',
          eventType: 'thread_started',
          occurredAt: DateTime(2026, 4, 5, 8),
          payload: const <String, Object?>{
            'thread_id': 'thread-1',
            'title': 'Morning capture',
          },
        ),
        _event(
          actorType: EventActorType.model,
          aggregateId: 'proposal-1',
          eventId: 'event-2',
          eventType: 'proposal_created',
          occurredAt: DateTime(2026, 4, 5, 8, 1),
          payload: const <String, Object?>{
            'proposal_id': 'proposal-1',
            'thread_id': 'thread-1',
            'summary': 'Add metformin 500 mg twice daily.',
            'assistant_text': 'Review the metformin schedule.',
            'actions': <Map<String, Object?>>[
              <String, Object?>{
                'action_id': 'action-1',
                'type': 'add_medication_schedule',
                'medication_name': 'Metformin',
                'dose_amount': '500',
                'dose_unit': 'mg',
                'start_date': '2026-04-05',
                'times': <String>['08:00', '20:00'],
              },
            ],
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'proposal-1',
          eventId: 'event-3',
          eventType: 'proposal_confirmed',
          occurredAt: DateTime(2026, 4, 5, 8, 2),
          payload: const <String, Object?>{
            'proposal_id': 'proposal-1',
            'thread_id': 'thread-1',
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'medication-1',
          eventId: 'event-4',
          eventType: 'medication_registered',
          occurredAt: DateTime(2026, 4, 5, 8, 2, 1),
          payload: const <String, Object?>{
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-1',
          eventId: 'event-5',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime(2026, 4, 5, 8, 2, 1),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
            'dose_amount': '500',
            'dose_unit': 'mg',
            'start_date': '2026-04-05',
            'times': <String>['08:00', '20:00'],
            'thread_id': 'thread-1',
            'source_proposal_id': 'proposal-1',
          },
        ),
      ]);

      final entries = state.entriesForDay(DateTime(2026, 4, 5));

      expect(state.pendingProposalsByThread['thread-1'], isNull);
      expect(state.activeSchedules.single.medicationName, 'Metformin');
      expect(entries.map((entry) => entry.doseLabel), <String>[
        '500 mg',
        '500 mg',
      ]);
      expect(entries.map((entry) => entry.dateTime.hour), <int>[8, 20]);
    });

    test(
      'stores accepted proposal actions when confirmation payload edits them',
      () {
        final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'proposal-1',
            eventId: 'event-1',
            eventType: 'proposal_created',
            occurredAt: DateTime(2026, 4, 5, 8, 1),
            actorType: EventActorType.model,
            payload: const <String, Object?>{
              'proposal_id': 'proposal-1',
              'thread_id': 'thread-1',
              'summary': 'Add ibuprofen 200 mg at 08:00.',
              'assistant_text': 'Review the ibuprofen schedule.',
              'actions': <Map<String, Object?>>[
                <String, Object?>{
                  'action_id': 'action-1',
                  'type': 'add_medication_schedule',
                  'medication_name': 'Ibuprofen',
                  'dose_amount': '200',
                  'dose_unit': 'mg',
                  'start_date': '2026-04-05',
                  'times': <String>['08:00'],
                },
              ],
            },
          ),
          _event(
            aggregateId: 'proposal-1',
            eventId: 'event-2',
            eventType: 'proposal_confirmed',
            occurredAt: DateTime(2026, 4, 5, 8, 2),
            actorType: EventActorType.user,
            payload: const <String, Object?>{
              'proposal_id': 'proposal-1',
              'thread_id': 'thread-1',
              'accepted_summary': 'Add Ibuprofen 400 mg',
              'accepted_actions': <Map<String, Object?>>[
                <String, Object?>{
                  'action_id': 'action-1',
                  'type': 'add_medication_schedule',
                  'medication_name': 'Ibuprofen',
                  'dose_amount': '400',
                  'dose_unit': 'mg',
                  'start_date': '2026-04-06',
                  'times': <String>['09:00'],
                },
              ],
            },
          ),
        ]);

        final proposal = state.proposalsById['proposal-1'];

        expect(proposal?.status, ProposalStatus.confirmed);
        expect(proposal?.summary, 'Add Ibuprofen 400 mg');
        expect(proposal?.actions.single.doseAmount, '400');
        expect(proposal?.actions.single.times, <String>['09:00']);
      },
    );

    test('removes stopped schedules from active projections', () {
      final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
        _event(
          actorType: EventActorType.user,
          aggregateId: 'medication-1',
          eventId: 'event-1',
          eventType: 'medication_registered',
          occurredAt: DateTime(2026, 4, 5, 8),
          payload: const <String, Object?>{
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-1',
          eventId: 'event-2',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime(2026, 4, 5, 8, 1),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
            'dose_amount': '500',
            'dose_unit': 'mg',
            'start_date': '2026-04-05',
            'times': <String>['08:00'],
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-1',
          eventId: 'event-3',
          eventType: 'medication_schedule_stopped',
          occurredAt: DateTime(2026, 4, 6, 9),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'end_date': '2026-04-06',
          },
        ),
      ]);

      expect(state.schedulesById['schedule-1']?.endDate, DateTime(2026, 4, 6));
      expect(state.activeSchedules, isEmpty);
    });

    test('applies medication_schedule_updated to active schedules', () {
      final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
        _event(
          actorType: EventActorType.user,
          aggregateId: 'medication-1',
          eventId: 'event-1',
          eventType: 'medication_registered',
          occurredAt: DateTime(2026, 4, 5, 8),
          payload: const <String, Object?>{
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-1',
          eventId: 'event-2',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime(2026, 4, 5, 8, 1),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_id': 'medication-1',
            'medication_name': 'Metformin',
            'dose_amount': '500',
            'dose_unit': 'mg',
            'start_date': '2026-04-05',
            'times': <String>['08:00'],
          },
        ),
        _event(
          actorType: EventActorType.user,
          aggregateId: 'schedule-1',
          eventId: 'event-3',
          eventType: 'medication_schedule_updated',
          occurredAt: DateTime(2026, 4, 6, 9),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Metformin',
            'dose_amount': '750',
            'dose_unit': 'mg',
            'start_date': '2026-04-06',
            'times': <String>['09:00', '21:00'],
            'notes': 'Updated after breakfast and dinner.',
          },
        ),
      ]);

      expect(state.activeSchedules.single.doseAmount, '750');
      expect(state.activeSchedules.single.startDate, DateTime(2026, 4, 6));
      expect(state.activeSchedules.single.times, <String>['09:00', '21:00']);
      expect(
        state.activeSchedules.single.notes,
        'Updated after breakfast and dinner.',
      );
    });

    test(
      'falls back to the event date when a schedule start date is missing',
      () {
        final state = ProjectionState.fromEvents(<EventEnvelope<DomainEvent>>[
          _event(
            actorType: EventActorType.user,
            aggregateId: 'medication-1',
            eventId: 'event-1',
            eventType: 'medication_registered',
            occurredAt: DateTime(2026, 4, 6, 9, 45),
            payload: const <String, Object?>{
              'medication_id': 'medication-1',
              'medication_name': 'Magnesium',
            },
          ),
          _event(
            actorType: EventActorType.user,
            aggregateId: 'schedule-1',
            eventId: 'event-2',
            eventType: 'medication_schedule_added',
            occurredAt: DateTime(2026, 4, 6, 9, 46),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_id': 'medication-1',
              'medication_name': 'Magnesium',
              'dose_amount': '250',
              'dose_unit': 'mg',
              'start_date': '',
              'times': <String>['21:00'],
            },
          ),
        ]);

        expect(
          state.schedulesById['schedule-1']?.startDate,
          DateTime(2026, 4, 6),
        );
        expect(state.activeSchedules.single.medicationName, 'Magnesium');
      },
    );
  });
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
  EventActorType actorType = EventActorType.system,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: eventType.startsWith('medication_')
        ? 'medication'
        : eventType.startsWith('proposal_')
        ? 'proposal'
        : 'conversation',
    aggregateId: aggregateId,
    actorType: actorType,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}
