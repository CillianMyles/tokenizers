import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
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
  });

  /// Secondary detail text.
  final String description;

  /// The item category.
  final HistoryTimelineItemKind kind;

  /// When the activity occurred.
  final DateTime occurredAt;

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
        ..sort((left, right) {
          final timeCompare = right.occurredAt.compareTo(left.occurredAt);
          if (timeCompare != 0) {
            return timeCompare;
          }
          return _kindSortOrder(
            left.kind,
          ).compareTo(_kindSortOrder(right.kind));
        });

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
  return switch (event.event.type) {
    'thread_started' => HistoryTimelineItem(
      description: payload['title'] as String? ?? 'Assistant activity',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      title: 'Assistant session started',
    ),
    'message_added' => HistoryTimelineItem(
      description: payload['text'] as String? ?? 'Message sent.',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      title: 'Message sent',
    ),
    'model_turn_recorded' => HistoryTimelineItem(
      description:
          payload['assistant_text'] as String? ?? 'Assistant created a reply.',
      kind: HistoryTimelineItemKind.chat,
      occurredAt: event.occurredAt,
      title: 'Assistant replied',
    ),
    'proposal_created' => HistoryTimelineItem(
      description: payload['summary'] as String? ?? 'Pending draft created.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      title: 'Draft created',
    ),
    'proposal_confirmed' => HistoryTimelineItem(
      description:
          payload['accepted_summary'] as String? ??
          'Medication changes were accepted.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      title: 'Draft accepted',
    ),
    'proposal_cancelled' => HistoryTimelineItem(
      description: 'Pending draft was discarded.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      title: 'Draft cancelled',
    ),
    'proposal_superseded' => HistoryTimelineItem(
      description: 'Pending draft was replaced by a newer one.',
      kind: HistoryTimelineItemKind.proposal,
      occurredAt: event.occurredAt,
      title: 'Draft replaced',
    ),
    'medication_schedule_added' => HistoryTimelineItem(
      description: _scheduleDetails(payload),
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      title: _medicationActionTitle(payload, 'added'),
    ),
    'medication_schedule_updated' => HistoryTimelineItem(
      description: _scheduleDetails(payload),
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      title: _medicationActionTitle(payload, 'updated'),
    ),
    'medication_schedule_stopped' => HistoryTimelineItem(
      description: 'Schedule removed.',
      kind: HistoryTimelineItemKind.medication,
      occurredAt: event.occurredAt,
      title: _medicationActionTitle(payload, 'removed'),
    ),
    'medication_taken' => HistoryTimelineItem(
      description: _takenSummary(payload),
      kind: HistoryTimelineItemKind.adherence,
      occurredAt: event.occurredAt,
      title: 'Medication taken',
    ),
    'medication_reminder_scheduled' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ??
          'Medication reminder queued.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      title: 'Reminder scheduled',
    ),
    'medication_reminder_sent' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ??
          'Medication reminder was delivered.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      title: 'Reminder sent',
    ),
    'medication_reminder_acknowledged' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ?? 'Reminder was acknowledged.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      title: 'Reminder acknowledged',
    ),
    'medication_reminder_skipped' => HistoryTimelineItem(
      description:
          payload['medication_name'] as String? ?? 'Reminder was skipped.',
      kind: HistoryTimelineItemKind.reminder,
      occurredAt: event.occurredAt,
      title: 'Reminder skipped',
    ),
    _ => null,
  };
}

String _medicationActionTitle(Map<String, Object?> payload, String action) {
  final medicationName = payload['medication_name'] as String?;
  return '${medicationName ?? 'Medication'} $action';
}

String _scheduleDetails(Map<String, Object?> payload) {
  final doseSchedule = medicationDoseScheduleFromJsonList(
    payload['dose_schedule'],
    fallbackDoseAmount: payload['dose_amount'] as String?,
    fallbackDoseUnit: payload['dose_unit'] as String?,
    fallbackTimes: ((payload['times'] ?? const <Object?>[]) as List<Object?>)
        .whereType<String>()
        .toList(),
  );

  final parts = <String>[
    if (doseSchedule.isNotEmpty) summarizeMedicationDoseSchedule(doseSchedule),
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
      'scheduled ${_displayTime(scheduledFor)}',
    if (takenAt != null && takenAt.isNotEmpty) 'taken ${_displayTime(takenAt)}',
  ];
  return parts.join(' • ');
}

String _displayTime(String raw) {
  return normalizeMedicationTimeString(raw);
}

int _kindSortOrder(HistoryTimelineItemKind kind) {
  return switch (kind) {
    HistoryTimelineItemKind.medication => 0,
    HistoryTimelineItemKind.adherence => 1,
    HistoryTimelineItemKind.reminder => 2,
    HistoryTimelineItemKind.proposal => 3,
    HistoryTimelineItemKind.chat => 4,
    HistoryTimelineItemKind.system => 5,
  };
}
