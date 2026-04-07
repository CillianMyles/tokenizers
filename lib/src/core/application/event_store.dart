import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';

/// Writes and reads immutable event envelopes.
abstract interface class EventStore {
  /// Appends events to the store in order.
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events);

  /// Loads every event in the store.
  Future<List<EventEnvelope<DomainEvent>>> loadAll();

  /// Watches the full event stream.
  Stream<List<EventEnvelope<DomainEvent>>> watchAll();
}
