import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';

/// The high-level category for an activity timeline item.
enum HistoryTimelineItemKind {
  chat,
  proposal,
  medication,
  adherence,
  reminder,
  system,
}

/// A single activity shown in the history timeline.
class HistoryTimelineItem {
  /// Creates a history timeline item.
  const HistoryTimelineItem({
    required this.description,
    required this.kind,
    required this.occurredAt,
    required this.title,
    this.threadId,
  });

  /// Secondary detail text.
  final String description;

  /// The item category.
  final HistoryTimelineItemKind kind;

  /// When the activity occurred.
  final DateTime occurredAt;

  /// Optional thread id for drill-in.
  final String? threadId;

  /// Primary label.
  final String title;
}

/// Activity items grouped by day.
class HistoryTimelineDayGroup {
  /// Creates a grouped timeline section.
  const HistoryTimelineDayGroup({required this.day, required this.items});

  /// Normalized day.
  final DateTime day;

  /// Items for the day.
  final List<HistoryTimelineItem> items;
}

/// Builds a day-grouped activity timeline from the event log.
List<HistoryTimelineDayGroup> buildHistoryTimeline(
  List<EventEnvelope<DomainEvent>> events,
) {
  final items =
      events
          .map(historyTimelineItemFromEvent)
          .whereType<HistoryTimelineItem>()
          .toList()
        ..sort((left, right) => right.occurredAt.compareTo(left.occurredAt));

  final groups = <HistoryTimelineDayGroup>[];
  for (final item in items) {
    final day = DateTime(
      item.occurredAt.year,
      item.occurredAt.month,
      item.occurredAt.day,
    );
    if (groups.isEmpty || groups.last.day != day) {
      groups.add(
        HistoryTimelineDayGroup(day: day, items: <HistoryTimelineItem>[item]),
      );
      continue;
    }
    groups.last.items.add(item);
  }
  return groups;
}

/// Maps a raw domain event into a user-visible timeline item.
HistoryTimelineItem? historyTimelineItemFromEvent(
  EventEnvelope<DomainEvent> event,
) {
  final payload = event.event.payload;
  final threadId = payload['thread_id'] as String?;
  return switch (event.event.type) {
    'thread_started' => HistoryTimelineItem(
      description: payload['title'] as String? ?? 'Conversation',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      threadId: payload['thread_id'] as String?,
      title: 'Conversation started',
    ),
    'message_added' => HistoryTimelineItem(
      description: payload['text'] as String? ?? 'Message sent.',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Message sent',
    ),
    'model_turn_recorded' => HistoryTimelineItem(
      description:
          payload['assistant_text'] as String? ?? 'Assistant created a reply.',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Assistant replied',
    ),
    'proposal_created' => HistoryTimelineItem(
      description: payload['summary'] as String? ?? 'Pending draft created.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Draft created',
    ),
    'proposal_confirmed' => HistoryTimelineItem(
      description:
          payload['accepted_summary'] as String? ??
          'Medication changes were accepted.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Draft accepted',
    ),
    'proposal_cancelled' => HistoryTimelineItem(
      description: 'Pending draft was discarded.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Draft cancelled',
    ),
    'proposal_superseded' => HistoryTimelineItem(
      description: 'Pending draft was replaced by a newer one.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Draft replaced',
    ),
    'medication_schedule_added' => HistoryTimelineItem(
      description: _scheduleSummary(payload),
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Medication added',
    ),
    'medication_schedule_updated' => HistoryTimelineItem(
      description: _scheduleSummary(payload),
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Medication updated',
    ),
    'medication_schedule_stopped' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ??
          'Medication schedule was removed.',
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Medication removed',
    ),
    'medication_taken' => HistoryTimelineItem(
      description: _takenSummary(payload),
      kind: HistoryTimelineItemKind.adherence,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Medication taken',
    ),
    'medication_reminder_scheduled' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ??
          'Medication reminder queued.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Reminder scheduled',
    ),
    'medication_reminder_sent' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ??
          'Medication reminder was delivered.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Reminder sent',
    ),
    'medication_reminder_acknowledged' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ?? 'Reminder was acknowledged.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Reminder acknowledged',
    ),
    'medication_reminder_skipped' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ?? 'Reminder was skipped.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      threadId: threadId,
      title: 'Reminder skipped',
    ),
    _ => null,
  };
}

String _scheduleSummary(Map<String, Object?> payload) {
  final medicationName = payload['medication_name'] as String?;
  final doseAmount = payload['dose_amount'] as String?;
  final doseUnit = payload['dose_unit'] as String?;
  final times = ((payload['times'] ?? const <Object?>[]) as List<Object?>)
      .whereType<String>()
      .toList();

  final parts = <String>[
    medicationName ?? 'Medication',
    if (doseAmount != null && doseUnit != null) '$doseAmount $doseUnit',
    if (times.isNotEmpty) times.join(', '),
  ];
  return parts.join(' • ');
}

String _takenSummary(Map<String, Object?> payload) {
  final medicationName = payload['medication_name'] as String?;
  final scheduledFor = payload['scheduled_for'] as String?;
  final takenAt = payload['taken_at'] as String?;
  final parts = <String>[
    medicationName ?? 'Medication',
    if (scheduledFor != null && scheduledFor.isNotEmpty)
      'scheduled $scheduledFor',
    if (takenAt != null && takenAt.isNotEmpty) 'taken $takenAt',
  ];
  return parts.join(' • ');
}
