import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// Pure read-model state rebuilt from the event log.
class ProjectionState {
  /// Creates a projection state.
  const ProjectionState({
    required this.activeSchedules,
    required this.medicationsById,
    required this.messagesByThread,
    required this.pendingProposalsByThread,
    required this.proposalsById,
    required this.schedulesById,
    required this.threads,
  });

  /// Empty projection state.
  const ProjectionState.empty()
    : activeSchedules = const <MedicationScheduleView>[],
      medicationsById = const <String, String>{},
      messagesByThread = const <String, List<ConversationMessageView>>{},
      pendingProposalsByThread = const <String, ProposalView?>{},
      proposalsById = const <String, ProposalView>{},
      schedulesById = const <String, MedicationScheduleView>{},
      threads = const <ConversationThreadView>[];

  /// Active schedules derived from the event log.
  final List<MedicationScheduleView> activeSchedules;

  /// Registered medication names keyed by medication id.
  final Map<String, String> medicationsById;

  /// Messages grouped by thread.
  final Map<String, List<ConversationMessageView>> messagesByThread;

  /// Pending proposals keyed by thread id.
  final Map<String, ProposalView?> pendingProposalsByThread;

  /// All proposals keyed by proposal id.
  final Map<String, ProposalView> proposalsById;

  /// Schedules keyed by schedule id.
  final Map<String, MedicationScheduleView> schedulesById;

  /// Thread summaries.
  final List<ConversationThreadView> threads;

  /// Derives calendar entries for a day from active schedules.
  List<MedicationCalendarEntry> entriesForDay(DateTime day) {
    final selectedDay = DateTime(day.year, day.month, day.day);
    final entries = <MedicationCalendarEntry>[];
    for (final schedule in activeSchedules) {
      final start = DateTime(
        schedule.startDate.year,
        schedule.startDate.month,
        schedule.startDate.day,
      );
      final end = schedule.endDate == null
          ? null
          : DateTime(
              schedule.endDate!.year,
              schedule.endDate!.month,
              schedule.endDate!.day,
            );
      if (selectedDay.isBefore(start)) {
        continue;
      }
      if (end != null && selectedDay.isAfter(end)) {
        continue;
      }
      for (final time in schedule.times) {
        final parts = time.split(':');
        entries.add(
          MedicationCalendarEntry(
            dateTime: DateTime(
              day.year,
              day.month,
              day.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            ),
            doseLabel: schedule.doseLabel,
            medicationName: schedule.medicationName,
            notes: schedule.notes,
            scheduleId: schedule.scheduleId,
            sourceProposalId: schedule.sourceProposalId,
            threadId: schedule.threadId,
          ),
        );
      }
    }
    entries.sort((left, right) => left.dateTime.compareTo(right.dateTime));
    return entries;
  }

  /// Replays the event log into a projection state.
  static ProjectionState fromEvents(List<EventEnvelope<DomainEvent>> events) {
    final threadTitles = <String, String>{};
    final threadUpdatedAt = <String, DateTime>{};
    final threadSnippets = <String, String>{};
    final messagesByThread = <String, List<ConversationMessageView>>{};
    final proposalsById = <String, ProposalView>{};
    final medicationNames = <String, String>{};
    final schedulesById = <String, MedicationScheduleView>{};

    for (final envelope in events) {
      final payload = envelope.event.payload;
      switch (envelope.event.type) {
        case 'thread_started':
          final threadId = payload['thread_id']! as String;
          threadTitles[threadId] = payload['title']! as String;
          threadUpdatedAt[threadId] = envelope.occurredAt;
          break;
        case 'message_added':
          final threadId = payload['thread_id']! as String;
          final text = payload['text']! as String;
          messagesByThread
              .putIfAbsent(threadId, () => <ConversationMessageView>[])
              .add(
                ConversationMessageView(
                  actor: ConversationActor.user,
                  createdAt: envelope.occurredAt,
                  messageId: payload['message_id']! as String,
                  text: text,
                  threadId: threadId,
                ),
              );
          threadUpdatedAt[threadId] = envelope.occurredAt;
          threadSnippets[threadId] = text;
          break;
        case 'model_turn_recorded':
          final threadId = payload['thread_id']! as String;
          final text = payload['assistant_text']! as String;
          messagesByThread
              .putIfAbsent(threadId, () => <ConversationMessageView>[])
              .add(
                ConversationMessageView(
                  actor: ConversationActor.model,
                  createdAt: envelope.occurredAt,
                  messageId: payload['message_id']! as String,
                  text: text,
                  threadId: threadId,
                ),
              );
          threadUpdatedAt[threadId] = envelope.occurredAt;
          threadSnippets[threadId] = text;
          break;
        case 'proposal_created':
          final proposalId = payload['proposal_id']! as String;
          proposalsById[proposalId] = ProposalView(
            actions:
                ((payload['actions'] ?? const <Object?>[]) as List<Object?>)
                    .whereType<Map<String, Object?>>()
                    .map(proposalActionFromJson)
                    .toList(),
            assistantText: payload['assistant_text']! as String,
            createdAt: envelope.occurredAt,
            proposalId: proposalId,
            status: ProposalStatus.pending,
            summary: payload['summary']! as String,
            threadId: payload['thread_id']! as String,
          );
          break;
        case 'proposal_confirmed':
          final proposalId = payload['proposal_id']! as String;
          final existing = proposalsById[proposalId];
          if (existing != null) {
            proposalsById[proposalId] = existing.copyWith(
              status: ProposalStatus.confirmed,
            );
          }
          break;
        case 'proposal_cancelled':
          final proposalId = payload['proposal_id']! as String;
          final existing = proposalsById[proposalId];
          if (existing != null) {
            proposalsById[proposalId] = existing.copyWith(
              status: ProposalStatus.cancelled,
            );
          }
          break;
        case 'proposal_superseded':
          final proposalId = payload['proposal_id']! as String;
          final existing = proposalsById[proposalId];
          if (existing != null) {
            proposalsById[proposalId] = existing.copyWith(
              status: ProposalStatus.superseded,
            );
          }
          break;
        case 'medication_registered':
          final medicationId = payload['medication_id']! as String;
          medicationNames[medicationId] = payload['medication_name']! as String;
          break;
        case 'medication_schedule_added':
          final medicationId = payload['medication_id']! as String;
          final medicationName =
              (payload['medication_name'] as String?) ??
              medicationNames[medicationId] ??
              'Unknown medication';
          final scheduleId = payload['schedule_id']! as String;
          schedulesById[scheduleId] = MedicationScheduleView(
            doseAmount: payload['dose_amount'] as String?,
            doseUnit: payload['dose_unit'] as String?,
            endDate: _tryParseDate(payload['end_date']),
            medicationName: medicationName,
            notes: payload['notes'] as String?,
            route: payload['route'] as String?,
            scheduleId: scheduleId,
            sourceProposalId: payload['source_proposal_id'] as String?,
            startDate: _parseDateOrFallback(
              payload['start_date'],
              envelope.occurredAt,
            ),
            threadId: payload['thread_id'] as String?,
            times: ((payload['times'] ?? const <Object?>[]) as List<Object?>)
                .whereType<String>()
                .toList(),
          );
          break;
        case 'medication_schedule_stopped':
          final scheduleId = payload['schedule_id']! as String;
          final existing = schedulesById[scheduleId];
          if (existing != null) {
            schedulesById[scheduleId] = existing.copyWith(
              endDate: _parseDateOrFallback(
                payload['end_date'],
                envelope.occurredAt,
              ),
            );
          }
          break;
        default:
          break;
      }
    }

    final pendingByThread = <String, ProposalView?>{};
    final pendingCounts = <String, int>{};
    for (final proposal in proposalsById.values) {
      if (proposal.status == ProposalStatus.pending) {
        pendingByThread[proposal.threadId] = proposal;
        pendingCounts.update(
          proposal.threadId,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final threads =
        threadTitles.entries.map((entry) {
          final threadId = entry.key;
          return ConversationThreadView(
            lastMessagePreview: threadSnippets[threadId] ?? 'No messages yet.',
            lastUpdatedAt: threadUpdatedAt[threadId] ?? DateTime(1970),
            pendingProposalCount: pendingCounts[threadId] ?? 0,
            threadId: threadId,
            title: entry.value,
          );
        }).toList()..sort(
          (left, right) => right.lastUpdatedAt.compareTo(left.lastUpdatedAt),
        );

    final activeSchedules =
        schedulesById.values.where((schedule) => schedule.isActive).toList()
          ..sort(
            (left, right) =>
                left.medicationName.compareTo(right.medicationName),
          );

    return ProjectionState(
      activeSchedules: activeSchedules,
      medicationsById: medicationNames,
      messagesByThread: messagesByThread.map(
        (key, value) =>
            MapEntry(key, List<ConversationMessageView>.unmodifiable(value)),
      ),
      pendingProposalsByThread: pendingByThread,
      proposalsById: proposalsById,
      schedulesById: schedulesById,
      threads: threads,
    );
  }

  static DateTime _parseDateOrFallback(Object? value, DateTime fallback) {
    final parsed = _tryParseDate(value);
    if (parsed != null) {
      return parsed;
    }
    return DateTime(fallback.year, fallback.month, fallback.day);
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}

/// Deserializes a stored proposal action payload.
ProposalActionView proposalActionFromJson(Map<String, Object?> json) {
  return ProposalActionView(
    actionId: json['action_id']! as String,
    doseAmount: json['dose_amount'] as String?,
    doseUnit: json['dose_unit'] as String?,
    endDate: _tryParseDate(json['end_date']),
    medicationName: json['medication_name'] as String?,
    missingFields:
        ((json['missing_fields'] ?? const <Object?>[]) as List<Object?>)
            .whereType<String>()
            .toList(),
    notes: json['notes'] as String?,
    route: json['route'] as String?,
    startDate: _tryParseDate(json['start_date']),
    targetScheduleId: json['target_schedule_id'] as String?,
    times: ((json['times'] ?? const <Object?>[]) as List<Object?>)
        .whereType<String>()
        .toList(),
    type: ProposalActionType.values.firstWhere(
      (type) => type.wireValue == json['type'],
    ),
  );
}

DateTime? _tryParseDate(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value);
}
