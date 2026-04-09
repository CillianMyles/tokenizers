import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Emits medication-domain events for direct UI and accepted draft changes.
class MedicationCommandService {
  /// Creates a medication command service.
  MedicationCommandService({required EventStore eventStore})
    : _eventStore = eventStore;

  final EventStore _eventStore;
  int _idCounter = 0;

  /// Adds a new medication schedule.
  Future<void> addSchedule({
    required MedicationScheduleDraft draft,
    required EventActorType actorType,
    String? causationId,
    String? correlationId,
    String? sourceProposalId,
    String? threadId,
  }) async {
    final writeCorrelationId = correlationId ?? _id('corr');
    final occurredAt = DateTime.now();
    final medicationId = _id('medication');
    final scheduleId = _id('schedule');
    await _eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: medicationId,
        actorType: actorType,
        correlationId: writeCorrelationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_registered',
          payload: <String, Object?>{
            'medication_id': medicationId,
            'medication_name': draft.medicationName,
          },
        ),
        occurredAt: occurredAt,
      ),
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: scheduleId,
        actorType: actorType,
        correlationId: writeCorrelationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_schedule_added',
          payload: <String, Object?>{
            'schedule_id': scheduleId,
            'medication_id': medicationId,
            'medication_name': draft.medicationName,
            'dose_amount': draft.doseAmount,
            'dose_unit': draft.doseUnit,
            'end_date': _date(draft.endDate),
            'notes': draft.notes,
            'route': draft.route,
            'source_proposal_id': sourceProposalId,
            'start_date': _date(draft.startDate),
            'thread_id': threadId,
            'dose_schedule': medicationDoseScheduleToJsonList(
              draft.resolvedDoseSchedule,
            ),
            'times': draft.times,
          },
        ),
        occurredAt: occurredAt,
      ),
    ]);
  }

  /// Removes an active medication schedule.
  Future<void> removeSchedule({
    required MedicationScheduleView existingSchedule,
    required EventActorType actorType,
    DateTime? endDate,
    String? causationId,
    String? correlationId,
  }) async {
    final writeCorrelationId = correlationId ?? _id('corr');
    final occurredAt = DateTime.now();
    await _eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: existingSchedule.scheduleId,
        actorType: actorType,
        correlationId: writeCorrelationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_schedule_stopped',
          payload: <String, Object?>{
            'medication_name': existingSchedule.medicationName,
            'schedule_id': existingSchedule.scheduleId,
            'end_date': _date(endDate ?? DateTime.now()),
            'source_proposal_id': existingSchedule.sourceProposalId,
            'thread_id': existingSchedule.threadId,
          },
        ),
        occurredAt: occurredAt,
      ),
    ]);
  }

  /// Updates an active medication schedule.
  Future<void> updateSchedule({
    required MedicationScheduleView existingSchedule,
    required MedicationScheduleDraft draft,
    required EventActorType actorType,
    String? causationId,
    String? correlationId,
    String? sourceProposalId,
  }) async {
    final writeCorrelationId = correlationId ?? _id('corr');
    final normalizedName = draft.medicationName.trim();
    final existingName = existingSchedule.medicationName.trim();
    if (normalizedName != existingName) {
      await removeSchedule(
        existingSchedule: existingSchedule,
        actorType: actorType,
        endDate: draft.startDate,
        causationId: causationId,
        correlationId: writeCorrelationId,
      );
      await addSchedule(
        draft: draft,
        actorType: actorType,
        causationId: causationId,
        correlationId: writeCorrelationId,
        sourceProposalId: sourceProposalId,
        threadId: existingSchedule.threadId,
      );
      return;
    }

    final occurredAt = DateTime.now();
    await _eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: existingSchedule.scheduleId,
        actorType: actorType,
        correlationId: writeCorrelationId,
        causationId: causationId,
        event: DomainEvent(
          type: 'medication_schedule_updated',
          payload: <String, Object?>{
            'schedule_id': existingSchedule.scheduleId,
            'medication_name': draft.medicationName,
            'dose_amount': draft.doseAmount,
            'dose_unit': draft.doseUnit,
            'end_date': _date(draft.endDate),
            'notes': draft.notes,
            'route': draft.route,
            'source_proposal_id':
                sourceProposalId ?? existingSchedule.sourceProposalId,
            'start_date': _date(draft.startDate),
            'thread_id': existingSchedule.threadId,
            'dose_schedule': medicationDoseScheduleToJsonList(
              draft.resolvedDoseSchedule,
            ),
            'times': draft.times,
          },
        ),
        occurredAt: occurredAt,
      ),
    ]);
  }

  /// Records that a medication dose was taken.
  Future<void> recordMedicationTaken({
    required MedicationCalendarEntry entry,
    required EventActorType actorType,
    DateTime? takenAt,
    String? correlationId,
  }) async {
    final writeCorrelationId = correlationId ?? _id('corr');
    final occurredAt = takenAt ?? DateTime.now();
    await _eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: _id('event'),
        aggregateType: 'medication',
        aggregateId: entry.scheduleId,
        actorType: actorType,
        correlationId: writeCorrelationId,
        event: DomainEvent(
          type: 'medication_taken',
          payload: <String, Object?>{
            'medication_name': entry.medicationName,
            'schedule_id': entry.scheduleId,
            'scheduled_for': entry.dateTime.toIso8601String(),
            'source_proposal_id': entry.sourceProposalId,
            'taken_at': occurredAt.toIso8601String(),
            'thread_id': entry.threadId,
          },
        ),
        occurredAt: occurredAt,
      ),
    ]);
  }

  String? _date(DateTime? value) {
    return value?.toIso8601String().split('T').first;
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_idCounter++}';
  }
}
