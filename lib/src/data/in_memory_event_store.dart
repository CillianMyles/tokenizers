import 'dart:async';

import '../core/application/event_store.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';

/// An in-memory event store used while the v0 architecture is taking shape.
class InMemoryEventStore implements EventStore {
  final List<EventEnvelope<DomainEvent>> _events =
      <EventEnvelope<DomainEvent>>[];
  final StreamController<List<EventEnvelope<DomainEvent>>> _controller =
      StreamController<List<EventEnvelope<DomainEvent>>>.broadcast();

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events) async {
    _events.addAll(events);
    _controller.add(List<EventEnvelope<DomainEvent>>.unmodifiable(_events));
  }

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    return List<EventEnvelope<DomainEvent>>.unmodifiable(_events);
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() async* {
    yield List<EventEnvelope<DomainEvent>>.unmodifiable(_events);
    yield* _controller.stream;
  }
}
