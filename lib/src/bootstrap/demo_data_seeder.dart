import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Summary returned after demo data is written locally.
class DemoSeedSummary {
  /// Creates a seed summary.
  const DemoSeedSummary({
    required this.activeScheduleCount,
    required this.eventCount,
    required this.pendingProposalCount,
  });

  /// Number of active schedules included in the seed.
  final int activeScheduleCount;

  /// Number of total events now stored locally.
  final int eventCount;

  /// Number of pending proposals included in the seed.
  final int pendingProposalCount;
}

/// Writes demo data described by a text seed script using the app's event model.
Future<DemoSeedSummary> seedDemoData({
  required AppDatabase database,
  required EventStore eventStore,
  required ProjectionRunner projectionRunner,
  required String seedScript,
  bool resetExistingData = false,
  DateTime? now,
}) async {
  final existingEvents = await eventStore.loadAll();
  if (existingEvents.isNotEmpty && !resetExistingData) {
    throw StateError(
      'Local data already exists. Re-run the demo seeder with '
      'RESET_DEMO_DATA=true to replace it.',
    );
  }

  if (resetExistingData) {
    await database.delete(database.eventLog).go();
    await projectionRunner.rebuild();
  }

  final seedClock = now ?? DateTime.now();
  final today = DateTime(seedClock.year, seedClock.month, seedClock.day);
  final parsed = _parseSeedScript(seedScript);
  final commandService = MedicationCommandService(eventStore: eventStore);

  var threadCreated = false;
  var threadId = 'thread-current';
  final activeScheduleIdsByMedication = <String, String>{};

  Future<void> ensureThreadStarted() async {
    if (threadCreated) {
      return;
    }
    await eventStore.append(<EventEnvelope<DomainEvent>>[
      EventEnvelope<DomainEvent>(
        eventId: 'seed-event-thread-started-default',
        aggregateType: 'conversation',
        aggregateId: threadId,
        actorType: EventActorType.system,
        correlationId: 'seed-corr-default-thread',
        event: const DomainEvent(
          type: 'thread_started',
          payload: <String, Object?>{
            'thread_id': 'thread-current',
            'title': 'Medication review',
          },
        ),
        occurredAt: _resolveTime(today, '09:00'),
      ),
    ]);
    threadCreated = true;
  }

  recordLoop:
  for (final record in parsed) {
    final fields = record.fields;
    switch (record.kind) {
      case 'THREAD':
        threadId = fields['thread_id'] ?? 'thread-current';
        await eventStore.append(<EventEnvelope<DomainEvent>>[
          EventEnvelope<DomainEvent>(
            eventId: 'seed-event-thread-started-${record.lineNumber}',
            aggregateType: 'conversation',
            aggregateId: threadId,
            actorType: EventActorType.system,
            correlationId: 'seed-corr-thread-${record.lineNumber}',
            event: DomainEvent(
              type: 'thread_started',
              payload: <String, Object?>{
                'thread_id': threadId,
                'title': _requiredField(record, 'title'),
              },
            ),
            occurredAt: _resolveTime(today, fields['at'] ?? '09:00'),
          ),
        ]);
        threadCreated = true;
        continue recordLoop;
      case 'MESSAGE':
        await ensureThreadStarted();
        final actor = fields['actor'] ?? 'user';
        final occurredAt = _resolveTime(today, fields['at'] ?? '10:00');
        if (actor == 'model') {
          await eventStore.append(<EventEnvelope<DomainEvent>>[
            EventEnvelope<DomainEvent>(
              eventId: 'seed-event-model-turn-${record.lineNumber}',
              aggregateType: 'conversation',
              aggregateId: threadId,
              actorType: EventActorType.model,
              correlationId: 'seed-corr-message-${record.lineNumber}',
              event: DomainEvent(
                type: 'model_turn_recorded',
                payload: <String, Object?>{
                  'assistant_text': _requiredField(record, 'text'),
                  'message_id': 'seed-message-${record.lineNumber}',
                  'raw_payload': const <String, Object?>{'seed': true},
                  'thread_id': threadId,
                },
              ),
              occurredAt: occurredAt,
            ),
          ]);
          continue recordLoop;
        }
        await eventStore.append(<EventEnvelope<DomainEvent>>[
          EventEnvelope<DomainEvent>(
            eventId: 'seed-event-message-${record.lineNumber}',
            aggregateType: 'conversation',
            aggregateId: threadId,
            actorType: EventActorType.user,
            correlationId: 'seed-corr-message-${record.lineNumber}',
            event: DomainEvent(
              type: 'message_added',
              payload: <String, Object?>{
                'thread_id': threadId,
                'message_id': 'seed-message-${record.lineNumber}',
                'text': _requiredField(record, 'text'),
              },
            ),
            occurredAt: occurredAt,
          ),
        ]);
        continue recordLoop;
      case 'PROPOSAL':
        await ensureThreadStarted();
        final occurredAt = _resolveTime(today, fields['at'] ?? '10:00');
        final proposalId =
            fields['proposal_id'] ?? 'seed-proposal-${record.lineNumber}';
        final proposalType = fields['type'] ?? 'add_medication_schedule';
        await eventStore.append(<EventEnvelope<DomainEvent>>[
          EventEnvelope<DomainEvent>(
            eventId: 'seed-event-proposal-${record.lineNumber}',
            aggregateType: 'proposal',
            aggregateId: proposalId,
            actorType: EventActorType.model,
            correlationId: 'seed-corr-proposal-${record.lineNumber}',
            event: DomainEvent(
              type: 'proposal_created',
              payload: <String, Object?>{
                'proposal_id': proposalId,
                'thread_id': threadId,
                'summary': _requiredField(record, 'summary'),
                'assistant_text': _requiredField(record, 'assistant_text'),
                'actions': <Map<String, Object?>>[
                  <String, Object?>{
                    'action_id': 'seed-action-${record.lineNumber}',
                    'type': proposalType,
                    'medication_name': fields['medication_name'],
                    'dose_amount': fields['dose_amount'],
                    'dose_unit': fields['dose_unit'],
                    'start_date': _resolveOffsetDate(
                      today,
                      fields['start_offset_days'] ?? '0',
                    ),
                    'dose_schedule': _doseScheduleJson(fields),
                    'times': _times(fields['times']),
                    'notes': fields['notes'],
                    'target_schedule_id': fields['target_schedule_id'],
                    'missing_fields': _csv(fields['missing_fields']),
                  },
                ],
              },
            ),
            occurredAt: occurredAt,
          ),
        ]);
        continue recordLoop;
      case 'SCHEDULE':
        final medicationName = _requiredField(record, 'medication_name');
        final draft = MedicationScheduleDraft(
          doseAmount: fields['dose_amount'],
          doseSchedule: _doseSchedule(fields),
          doseUnit: fields['dose_unit'],
          medicationName: medicationName,
          notes: fields['notes'],
          route: fields['route'],
          startDate: _offsetDate(today, fields['start_offset_days'] ?? '0'),
          times: _times(fields['times']),
        );
        await commandService.addSchedule(
          actorType: EventActorType.user,
          draft: draft,
          threadId: threadId,
        );
        activeScheduleIdsByMedication[medicationName] =
            await _latestScheduleIdForMedication(
              eventStore: eventStore,
              medicationName: medicationName,
            );
        continue recordLoop;
      case 'RETIRED_SCHEDULE':
        final schedule = MedicationScheduleView(
          doseAmount: fields['dose_amount'],
          doseSchedule: _doseSchedule(fields),
          doseUnit: fields['dose_unit'],
          medicationName: _requiredField(record, 'medication_name'),
          notes: fields['notes'],
          route: fields['route'],
          scheduleId: 'seed-retired-schedule-${record.lineNumber}',
          startDate: _offsetDate(today, fields['start_offset_days'] ?? '0'),
          threadId: threadId,
          times: _times(fields['times']),
        );
        await eventStore.append(
          _retiredMedicationSeedEvents(
            record: record,
            removedAt: _offsetDate(today, fields['stop_offset_days'] ?? '0'),
            schedule: schedule,
          ),
        );
        continue recordLoop;
      case 'TAKEN':
        final medicationName = _requiredField(record, 'medication_name');
        final scheduleId =
            activeScheduleIdsByMedication[medicationName] ??
            await _latestScheduleIdForMedication(
              eventStore: eventStore,
              medicationName: medicationName,
            );
        final scheduledFor = _resolveTime(
          today,
          _requiredField(record, 'scheduled_time'),
        );
        final takenAt = _resolveTime(
          today,
          _requiredField(record, 'taken_time'),
        );
        await commandService.recordMedicationTaken(
          actorType: EventActorType.user,
          entry: MedicationCalendarEntry(
            dateTime: scheduledFor,
            doseLabel: fields['dose_label'] ?? 'Dose pending',
            medicationName: medicationName,
            scheduleId: scheduleId,
            threadId: threadId,
          ),
          recordedAt: _resolveTime(
            today,
            fields['recorded_time'] ?? _requiredField(record, 'taken_time'),
          ),
          scheduledFor: scheduledFor,
          takenAt: takenAt,
        );
        continue recordLoop;
      case 'CORRECTED_TAKEN':
        final medicationName = _requiredField(record, 'medication_name');
        final scheduleId =
            activeScheduleIdsByMedication[medicationName] ??
            await _latestScheduleIdForMedication(
              eventStore: eventStore,
              medicationName: medicationName,
            );
        final scheduledFor = _resolveTime(
          today,
          _requiredField(record, 'scheduled_time'),
        );
        await commandService.correctMedicationTaken(
          actorType: EventActorType.user,
          entry: MedicationCalendarEntry(
            dateTime: scheduledFor,
            doseLabel: fields['dose_label'] ?? 'Dose pending',
            medicationName: medicationName,
            scheduleId: scheduleId,
            threadId: threadId,
          ),
          previousTakenAt: _resolveTime(
            today,
            _requiredField(record, 'previous_taken_time'),
          ),
          recordedAt: _resolveTime(
            today,
            fields['recorded_time'] ?? _requiredField(record, 'taken_time'),
          ),
          scheduledFor: scheduledFor,
          takenAt: _resolveTime(today, _requiredField(record, 'taken_time')),
        );
        continue recordLoop;
      default:
        throw StateError(
          'Unsupported seed record kind "${record.kind}" on line '
          '${record.lineNumber}.',
        );
    }
  }

  await projectionRunner.rebuild();
  final seededEvents = await eventStore.loadAll();

  return DemoSeedSummary(
    activeScheduleCount: parsed
        .where((record) => record.kind == 'SCHEDULE')
        .length,
    eventCount: seededEvents.length,
    pendingProposalCount: parsed
        .where((record) => record.kind == 'PROPOSAL')
        .length,
  );
}

class _SeedRecord {
  const _SeedRecord({
    required this.fields,
    required this.kind,
    required this.lineNumber,
  });

  final Map<String, String> fields;
  final String kind;
  final int lineNumber;
}

List<_SeedRecord> _parseSeedScript(String source) {
  final records = <_SeedRecord>[];
  final lines = source.split('\n');

  for (var index = 0; index < lines.length; index++) {
    final rawLine = lines[index].trim();
    if (rawLine.isEmpty || rawLine.startsWith('#')) {
      continue;
    }

    final segments = rawLine.split('|');
    final kind = segments.first.trim().toUpperCase();
    final fields = <String, String>{};

    for (final segment in segments.skip(1)) {
      final separator = segment.indexOf('=');
      if (separator <= 0 || separator == segment.length - 1) {
        throw FormatException(
          'Invalid seed field "$segment" on line ${index + 1}. '
          'Expected key=value.',
        );
      }
      final key = segment.substring(0, separator).trim();
      final value = segment.substring(separator + 1).trim();
      fields[key] = value;
    }

    records.add(_SeedRecord(fields: fields, kind: kind, lineNumber: index + 1));
  }

  return records;
}

String _requiredField(_SeedRecord record, String key) {
  final value = record.fields[key];
  if (value == null || value.isEmpty) {
    throw FormatException(
      'Missing required field "$key" for ${record.kind} on '
      'line ${record.lineNumber}.',
    );
  }
  return value;
}

List<String> _csv(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return const <String>[];
  }
  return raw
      .split(',')
      .map((value) => value.trim())
      .where((value) {
        return value.isNotEmpty;
      })
      .toList(growable: false);
}

List<String> _times(String? raw) => _csv(raw);

List<MedicationDoseScheduleEntry> _doseSchedule(Map<String, String> fields) {
  final raw = fields['dose_schedule'];
  if (raw == null || raw.trim().isEmpty) {
    return const <MedicationDoseScheduleEntry>[];
  }

  return raw
      .split(';')
      .map((item) {
        final parts = item.split(',').map((value) => value.trim()).toList();
        if (parts.length != 3) {
          throw FormatException(
            'Invalid dose_schedule item "$item". Expected time,dose_amount,dose_unit.',
          );
        }
        return MedicationDoseScheduleEntry(
          time: parts[0],
          doseAmount: parts[1].isEmpty ? null : parts[1],
          doseUnit: parts[2].isEmpty ? null : parts[2],
        );
      })
      .toList(growable: false);
}

List<Map<String, Object?>> _doseScheduleJson(Map<String, String> fields) {
  return medicationDoseScheduleToJsonList(_doseSchedule(fields));
}

DateTime _offsetDate(DateTime today, String offsetDays) {
  return today.add(Duration(days: int.parse(offsetDays)));
}

String _resolveOffsetDate(DateTime today, String offsetDays) {
  return _dateText(_offsetDate(today, offsetDays));
}

DateTime _resolveTime(DateTime today, String raw) {
  final parts = raw.split(':');
  if (parts.length < 2 || parts.length > 3) {
    throw FormatException(
      'Invalid time "$raw". Expected HH:mm or HH:mm:ss in the seed file.',
    );
  }
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  final second = parts.length == 3 ? int.parse(parts[2]) : 0;
  return DateTime(today.year, today.month, today.day, hour, minute, second);
}

List<EventEnvelope<DomainEvent>> _retiredMedicationSeedEvents({
  required _SeedRecord record,
  required DateTime removedAt,
  required MedicationScheduleView schedule,
}) {
  return <EventEnvelope<DomainEvent>>[
    EventEnvelope<DomainEvent>(
      eventId: 'seed-event-retired-registered-${record.lineNumber}',
      aggregateType: 'medication',
      aggregateId: 'seed-retired-medication-${record.lineNumber}',
      actorType: EventActorType.user,
      correlationId: 'seed-corr-retired-${record.lineNumber}',
      event: DomainEvent(
        type: 'medication_registered',
        payload: <String, Object?>{
          'medication_id': 'seed-retired-medication-${record.lineNumber}',
          'medication_name': schedule.medicationName,
        },
      ),
      occurredAt: schedule.startDate,
    ),
    EventEnvelope<DomainEvent>(
      eventId: 'seed-event-retired-added-${record.lineNumber}',
      aggregateType: 'medication',
      aggregateId: schedule.scheduleId,
      actorType: EventActorType.user,
      correlationId: 'seed-corr-retired-${record.lineNumber}',
      event: DomainEvent(
        type: 'medication_schedule_added',
        payload: <String, Object?>{
          'schedule_id': schedule.scheduleId,
          'medication_id': 'seed-retired-medication-${record.lineNumber}',
          'medication_name': schedule.medicationName,
          'dose_amount': schedule.doseAmount,
          'dose_unit': schedule.doseUnit,
          'end_date': null,
          'notes': schedule.notes,
          'route': schedule.route,
          'source_proposal_id': null,
          'start_date': _dateText(schedule.startDate),
          'thread_id': schedule.threadId,
          'dose_schedule': medicationDoseScheduleToJsonList(
            schedule.resolvedDoseSchedule,
          ),
          'times': schedule.times,
        },
      ),
      occurredAt: schedule.startDate,
    ),
    EventEnvelope<DomainEvent>(
      eventId: 'seed-event-retired-stopped-${record.lineNumber}',
      aggregateType: 'medication',
      aggregateId: schedule.scheduleId,
      actorType: EventActorType.user,
      correlationId: 'seed-corr-retired-${record.lineNumber}',
      event: DomainEvent(
        type: 'medication_schedule_stopped',
        payload: <String, Object?>{
          'medication_name': schedule.medicationName,
          'schedule_id': schedule.scheduleId,
          'end_date': _dateText(removedAt),
          'source_proposal_id': schedule.sourceProposalId,
          'thread_id': schedule.threadId,
        },
      ),
      occurredAt: removedAt,
    ),
  ];
}

String _dateText(DateTime value) {
  return value.toIso8601String().split('T').first;
}

Future<String> _latestScheduleIdForMedication({
  required EventStore eventStore,
  required String medicationName,
}) async {
  final events = await eventStore.loadAll();
  final latest = events.lastWhere((event) {
    return event.event.type == 'medication_schedule_added' &&
        event.event.payload['medication_name'] == medicationName;
  });
  return latest.event.payload['schedule_id']! as String;
}
