import 'domain_event.dart';

/// A stable aggregate identifier.
typedef AggregateId = String;

/// A stable correlation identifier.
typedef CorrelationId = String;

/// Identifies who produced an event.
enum EventActorType { user, model, system }

/// Wraps a domain event with event-store metadata.
class EventEnvelope<T extends DomainEvent> {
  /// Creates an event envelope.
  const EventEnvelope({
    required this.eventId,
    required this.aggregateType,
    required this.aggregateId,
    required this.event,
    required this.occurredAt,
    this.causationId,
    this.correlationId,
    this.actorType = EventActorType.system,
  });

  /// The immutable event id.
  final String eventId;

  /// The aggregate type.
  final String aggregateType;

  /// The aggregate id.
  final AggregateId aggregateId;

  /// The stored domain event.
  final T event;

  /// When the event occurred.
  final DateTime occurredAt;

  /// The event that caused this event, when available.
  final String? causationId;

  /// The correlation id shared across a workflow.
  final CorrelationId? correlationId;

  /// The logical actor that created the event.
  final EventActorType actorType;
}
