/// A domain event stored in the immutable event log.
class DomainEvent {
  /// Creates a domain event.
  const DomainEvent({required this.type, required this.payload});

  /// The logical event type, such as `proposal_created`.
  final String type;

  /// The event payload encoded as app-owned data.
  final Map<String, Object?> payload;
}
