import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/application/event_store.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';
import 'app_database.dart';

/// Drift-backed event store for native platforms.
class DriftEventStore implements EventStore {
  /// Creates a Drift event store.
  const DriftEventStore({required AppDatabase database}) : _database = database;

  final AppDatabase _database;

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events) async {
    await _database.batch((batch) {
      batch.insertAll(
        _database.eventLog,
        events.map((event) {
          return EventLogCompanion.insert(
            actorType: _actorType(event.actorType),
            aggregateId: event.aggregateId,
            aggregateType: event.aggregateType,
            causationId: Value(event.causationId),
            correlationId: Value(event.correlationId),
            eventId: event.eventId,
            eventType: event.event.type,
            occurredAt: event.occurredAt,
            payloadJson: jsonEncode(event.event.payload),
          );
        }).toList(),
      );
    });
  }

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    final query = _orderedEventLogQuery();
    final rows = await query.get();
    return rows.map(_fromRow).toList();
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    final query = _orderedEventLogQuery();
    return query.watch().map(
      (rows) => rows.map(_fromRow).toList(growable: false),
    );
  }

  SimpleSelectStatement<$EventLogTable, EventLogData> _orderedEventLogQuery() {
    return _database.select(_database.eventLog)
      ..orderBy(<OrderingTerm Function($EventLogTable)>[
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.eventId),
      ]);
  }

  EventEnvelope<DomainEvent> _fromRow(EventLogData row) {
    return EventEnvelope<DomainEvent>(
      eventId: row.eventId,
      aggregateType: row.aggregateType,
      aggregateId: row.aggregateId,
      event: DomainEvent(
        type: row.eventType,
        payload: (jsonDecode(row.payloadJson) as Map).cast<String, Object?>(),
      ),
      occurredAt: row.occurredAt,
      causationId: row.causationId,
      correlationId: row.correlationId,
      actorType: switch (row.actorType) {
        'user' => EventActorType.user,
        'model' => EventActorType.model,
        _ => EventActorType.system,
      },
    );
  }

  String _actorType(EventActorType actorType) {
    return switch (actorType) {
      EventActorType.user => 'user',
      EventActorType.model => 'model',
      EventActorType.system => 'system',
    };
  }
}
