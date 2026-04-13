import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/history/domain/history_timeline_models.dart';

void main() {
  group('buildHistoryTimeline', () {
    test('groups items by day and orders newest first', () {
      final groups = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-1',
          eventType: 'message_added',
          occurredAt: DateTime(2026, 4, 8, 9),
          payload: const <String, Object?>{
            'thread_id': 'thread-1',
            'message_id': 'message-1',
            'text': 'Add magnesium tonight.',
          },
        ),
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-2',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime(2026, 4, 9, 8),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Magnesium',
            'dose_amount': '250',
            'dose_unit': 'mg',
            'times': <String>['21:00'],
          },
        ),
      ]);

      expect(groups.length, 2);
      expect(groups.first.day, DateTime(2026, 4, 9));
      expect(groups.first.items.single.title, 'Magnesium added');
      expect(groups.first.items.single.description, '21:00 • 250 mg');
      expect(groups.last.items.single.title, 'Message sent');
    });

    test(
      'prefers concrete medication changes ahead of proposal meta events',
      () {
        final groups = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'proposal-1',
            eventId: 'event-1',
            eventType: 'proposal_confirmed',
            occurredAt: DateTime(2026, 4, 9, 23, 49),
            payload: const <String, Object?>{
              'proposal_id': 'proposal-1',
              'thread_id': 'thread-1',
            },
          ),
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-2',
            eventType: 'medication_schedule_added',
            occurredAt: DateTime(2026, 4, 9, 23, 49),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_name': 'Tacrolimus',
              'dose_schedule': <Map<String, Object?>>[
                <String, Object?>{
                  'time': '07:00:00.000000000Z',
                  'dose_amount': '1.2',
                  'dose_unit': 'mg',
                },
              ],
            },
          ),
        ]);

        expect(groups.single.items, hasLength(1));
        expect(groups.single.items.first.title, 'Tacrolimus added');
        expect(groups.single.items.first.description, '07:00 • 1.2 mg');
      },
    );

    test('hides draft-introducing assistant replies from the feed', () {
      final groups = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          correlationId: 'corr-1',
          eventId: 'event-1',
          eventType: 'model_turn_recorded',
          occurredAt: DateTime(2026, 4, 9, 23, 47),
          payload: const <String, Object?>{
            'assistant_text': 'I drafted a proposal.',
            'message_id': 'message-1',
            'thread_id': 'thread-1',
          },
        ),
        _event(
          aggregateId: 'proposal-1',
          correlationId: 'corr-1',
          eventId: 'event-2',
          eventType: 'proposal_created',
          occurredAt: DateTime(2026, 4, 9, 23, 47),
          payload: const <String, Object?>{
            'proposal_id': 'proposal-1',
            'summary': 'Add Tacrolimus',
            'thread_id': 'thread-1',
          },
        ),
      ]);

      expect(groups, isEmpty);
    });

    test('keeps standalone assistant replies when there is no draft', () {
      final item = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          correlationId: 'corr-1',
          eventId: 'event-1',
          eventType: 'model_turn_recorded',
          occurredAt: DateTime(2026, 4, 9, 23, 47),
          payload: const <String, Object?>{
            'assistant_text': 'I need the exact dose before I can draft it.',
            'message_id': 'message-1',
            'thread_id': 'thread-1',
          },
        ),
      ]).single.items.single;

      expect(item.title, 'Assistant replied');
      expect(item.description, 'I need the exact dose before I can draft it.');
    });

    test('maps medication_taken as adherence activity', () {
      final item = historyTimelineItemFromEvent(
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-1',
          eventType: 'medication_taken',
          occurredAt: DateTime(2026, 4, 9, 9, 5),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
            'scheduled_for': '09:00',
            'taken_at': '09:05',
            'thread_id': 'thread-1',
          },
        ),
      );

      expect(item, isNotNull);
      expect(item?.kind, HistoryTimelineItemKind.adherence);
      expect(item?.title, 'Medication taken');
      expect(item?.description, 'Vitamin D • scheduled 09:00');
      expect(item?.occurredAt, DateTime(2026, 4, 9, 9, 5));
    });

    test('maps medication_taken_corrected as editable adherence activity', () {
      final item = historyTimelineItemFromEvent(
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-1',
          eventType: 'medication_taken_corrected',
          occurredAt: DateTime(2026, 4, 9, 9, 12),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
            'scheduled_for': '2026-04-09T09:00:00.000',
            'taken_at': '2026-04-09T09:12:00.000',
            'thread_id': 'thread-1',
          },
        ),
      );

      expect(item?.kind, HistoryTimelineItemKind.adherence);
      expect(item?.title, 'Medication taken');
      expect(item?.adherenceAction?.scheduleId, 'schedule-1');
      expect(item?.adherenceAction?.takenAt, DateTime(2026, 4, 9, 9, 12));
      expect(item?.occurredAt, DateTime(2026, 4, 9, 9, 12));
    });

    test('keeps only the latest adherence item per scheduled dose', () {
      final groups = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-1',
          eventType: 'medication_taken',
          occurredAt: DateTime(2026, 4, 9, 9, 5),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
            'scheduled_for': '2026-04-09T09:00:00.000',
            'taken_at': '2026-04-09T09:05:00.000',
          },
        ),
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-2',
          eventType: 'medication_taken_corrected',
          occurredAt: DateTime(2026, 4, 9, 9, 12),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
            'scheduled_for': '2026-04-09T09:00:00.000',
            'taken_at': '2026-04-09T09:12:00.000',
          },
        ),
      ]);

      expect(groups.single.items, hasLength(1));
      expect(groups.single.items.single.title, 'Medication taken');
      expect(
        groups.single.items.single.description,
        'Vitamin D • scheduled 09:00',
      );
      expect(
        groups.single.items.single.occurredAt,
        DateTime(2026, 4, 9, 9, 12),
      );
    });

    test(
      'removes the superseded adherence item when correction changes slot',
      () {
        final groups = buildHistoryTimeline(<EventEnvelope<DomainEvent>>[
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-1',
            eventType: 'medication_taken',
            occurredAt: DateTime(2026, 4, 9, 9, 5),
            payload: const <String, Object?>{
              'schedule_id': 'schedule-1',
              'medication_name': 'Vitamin D',
              'scheduled_for': '2026-04-09T09:00:00.000',
              'taken_at': '2026-04-09T09:05:00.000',
            },
          ),
          _event(
            aggregateId: 'schedule-1',
            eventId: 'event-2',
            eventType: 'medication_taken_corrected',
            occurredAt: DateTime(2026, 4, 9, 21, 12),
            payload: const <String, Object?>{
              'previous_scheduled_for': '2026-04-09T09:00:00.000',
              'previous_taken_at': '2026-04-09T09:05:00.000',
              'schedule_id': 'schedule-1',
              'medication_name': 'Vitamin D',
              'scheduled_for': '2026-04-09T21:00:00.000',
              'taken_at': '2026-04-09T21:12:00.000',
            },
          ),
        ]);

        expect(groups.single.items, hasLength(1));
        expect(
          groups.single.items.single.description,
          'Vitamin D • scheduled 21:00',
        );
        expect(
          groups.single.items.single.occurredAt,
          DateTime(2026, 4, 9, 21, 12),
        );
      },
    );

    test('shows logged time when it differs from the taken time', () {
      final item = historyTimelineItemFromEvent(
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-1',
          eventType: 'medication_taken_corrected',
          occurredAt: DateTime(2026, 4, 9, 23, 41),
          payload: const <String, Object?>{
            'recorded_at': '2026-04-09T23:41:00.000',
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
            'scheduled_for': '2026-04-09T09:00:00.000',
            'taken_at': '2026-04-09T09:12:00.000',
          },
        ),
      );

      expect(
        item?.description,
        'Vitamin D • scheduled 09:00 • logged Apr 9, 2026 23:41',
      );
      expect(item?.occurredAt, DateTime(2026, 4, 9, 9, 12));
    });

    test('keeps reminder event shapes mappable when they are introduced', () {
      final item = historyTimelineItemFromEvent(
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-1',
          eventType: 'medication_reminder_sent',
          occurredAt: DateTime(2026, 4, 9, 8, 55),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Vitamin D',
          },
        ),
      );

      expect(item?.kind, HistoryTimelineItemKind.reminder);
      expect(item?.title, 'Reminder sent');
    });
  });
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  String? correlationId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: eventType.startsWith('medication_')
        ? 'medication'
        : eventType.startsWith('proposal_')
        ? 'proposal'
        : 'conversation',
    aggregateId: aggregateId,
    correlationId: correlationId,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}
