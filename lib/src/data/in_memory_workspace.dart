import 'dart:async';

import '../core/application/event_store.dart';
import '../core/application/projection_runner.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';
import '../core/model/model_provider.dart';
import '../core/model/model_response_contract.dart';
import '../features/calendar/application/medication_repository.dart';
import '../features/calendar/domain/medication_models.dart';
import '../features/chat/application/conversation_repository.dart';
import '../features/chat/domain/conversation_models.dart';
import '../features/proposals/domain/proposal_models.dart';

/// Rebuilds read models from the in-memory event stream.
class InMemoryWorkspace
    implements ConversationRepository, MedicationRepository, ProjectionRunner {
  /// Creates an in-memory workspace.
  InMemoryWorkspace({required EventStore eventStore})
    : _eventStore = eventStore {
    _subscription = _eventStore.watchAll().listen((events) {
      _state = _ProjectionState.fromEvents(events);
      _controller.add(_state);
    });
  }

  final EventStore _eventStore;
  late final StreamSubscription<List<EventEnvelope<DomainEvent>>> _subscription;
  final StreamController<_ProjectionState> _controller =
      StreamController<_ProjectionState>.broadcast();

  _ProjectionState _state = const _ProjectionState.empty();

  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    return _state.messagesByThread[threadId] ??
        const <ConversationMessageView>[];
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    return _state.pendingProposalsByThread[threadId];
  }

  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    return _state.activeSchedules;
  }

  @override
  Future<void> rebuild() async {
    _state = _ProjectionState.fromEvents(await _eventStore.loadAll());
    _controller.add(_state);
  }

  /// Releases in-memory subscriptions.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) async* {
    yield _state.entriesForDay(day);
    yield* _controller.stream.map((state) => state.entriesForDay(day));
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules() async* {
    yield _state.activeSchedules;
    yield* _controller.stream.map((state) => state.activeSchedules);
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) async* {
    yield _state.messagesByThread[threadId] ??
        const <ConversationMessageView>[];
    yield* _controller.stream.map(
      (state) =>
          state.messagesByThread[threadId] ?? const <ConversationMessageView>[],
    );
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) async* {
    yield _state.pendingProposalsByThread[threadId];
    yield* _controller.stream.map(
      (state) => state.pendingProposalsByThread[threadId],
    );
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() async* {
    yield _state.threads;
    yield* _controller.stream.map((state) => state.threads);
  }
}

/// A deterministic stand-in for the eventual Gemini model provider.
class DemoModelProvider implements ModelProvider {
  /// Creates a demo model provider.
  DemoModelProvider({required this.referenceDate});

  final DateTime referenceDate;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
  }) async {
    final normalized = userText.toLowerCase();
    final matchedSchedule = _findMatchingSchedule(activeSchedules, normalized);

    if (normalized.contains('stop') && matchedSchedule != null) {
      final medicationName = matchedSchedule.medicationName;
      return ModelResponseContract(
        assistantText:
            'I created a stop proposal for $medicationName. Review it before it changes your schedule.',
        rawPayload: <String, Object?>{
          'provider': 'demo',
          'kind': 'stop_medication_schedule',
        },
        actions: <ModelProposalAction>[
          ModelProposalAction(
            actionId: _id('action'),
            type: ModelProposalActionType.stopMedicationSchedule,
            medicationName: medicationName,
            notes: 'Stop the current active schedule.',
            startDate: referenceDate,
            targetScheduleId: matchedSchedule.scheduleId,
          ),
        ],
      );
    }

    final medicationName = _extractMedicationName(normalized, activeSchedules);
    final doseMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(mg|ml|iu|tablet|tablets|capsule|capsules)',
    ).firstMatch(normalized);
    final times = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
    ).allMatches(normalized).map(_normalizeTime).toList();

    final missingFields = <String>[
      if (medicationName == null) 'medicine name',
      if (doseMatch == null) 'dose',
      if (times.isEmpty) 'time',
    ];

    if (missingFields.isNotEmpty) {
      return ModelResponseContract(
        assistantText:
            'I need a little more detail before I can draft a safe medication proposal.',
        rawPayload: <String, Object?>{
          'provider': 'demo',
          'kind': 'request_missing_info',
          'missing_fields': missingFields,
        },
        actions: <ModelProposalAction>[
          ModelProposalAction(
            actionId: _id('action'),
            type: ModelProposalActionType.requestMissingInfo,
            medicationName: medicationName,
            missingFields: missingFields,
          ),
        ],
      );
    }

    final startDate = normalized.contains('tomorrow')
        ? referenceDate.add(const Duration(days: 1))
        : referenceDate;
    final doseAmount = doseMatch!.group(1)!;
    final doseUnit = doseMatch.group(2)!.toUpperCase() == 'IU'
        ? 'IU'
        : doseMatch.group(2)!.toLowerCase();

    return ModelResponseContract(
      assistantText:
          'I drafted a pending $medicationName schedule. Confirm it before it appears on the calendar.',
      rawPayload: <String, Object?>{
        'provider': 'demo',
        'kind': 'add_medication_schedule',
      },
      actions: <ModelProposalAction>[
        ModelProposalAction(
          actionId: _id('action'),
          type: ModelProposalActionType.addMedicationSchedule,
          doseAmount: doseAmount,
          doseUnit: doseUnit,
          medicationName: medicationName,
          notes: normalized.contains('with food') ? 'Take with food.' : null,
          startDate: DateTime(startDate.year, startDate.month, startDate.day),
          times: times,
        ),
      ],
    );
  }

  String? _extractMedicationName(
    String normalized,
    List<MedicationScheduleView> activeSchedules,
  ) {
    const builtInNames = <String>[
      'amoxicillin',
      'ibuprofen',
      'metformin',
      'vitamin d',
      'vitamin b12',
    ];

    for (final schedule in activeSchedules) {
      final lower = schedule.medicationName.toLowerCase();
      if (normalized.contains(lower)) {
        return schedule.medicationName;
      }
    }

    for (final name in builtInNames) {
      if (normalized.contains(name)) {
        return name
            .split(' ')
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }
    }
    return null;
  }

  MedicationScheduleView? _findMatchingSchedule(
    List<MedicationScheduleView> activeSchedules,
    String normalized,
  ) {
    for (final schedule in activeSchedules) {
      if (normalized.contains(schedule.medicationName.toLowerCase())) {
        return schedule;
      }
    }
    return null;
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _normalizeTime(RegExpMatch match) {
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final meridiem = match.group(3)!;

    if (meridiem == 'pm' && hour != 12) {
      hour += 12;
    }
    if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}

class _ProjectionState {
  const _ProjectionState({
    required this.activeSchedules,
    required this.messagesByThread,
    required this.pendingProposalsByThread,
    required this.schedulesById,
    required this.threads,
  });

  const _ProjectionState.empty()
    : activeSchedules = const <MedicationScheduleView>[],
      messagesByThread = const <String, List<ConversationMessageView>>{},
      pendingProposalsByThread = const <String, ProposalView?>{},
      schedulesById = const <String, MedicationScheduleView>{},
      threads = const <ConversationThreadView>[];

  final List<MedicationScheduleView> activeSchedules;
  final Map<String, List<ConversationMessageView>> messagesByThread;
  final Map<String, ProposalView?> pendingProposalsByThread;
  final Map<String, MedicationScheduleView> schedulesById;
  final List<ConversationThreadView> threads;

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

  static _ProjectionState fromEvents(List<EventEnvelope<DomainEvent>> events) {
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
                    .map(_proposalActionFromJson)
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
            startDate: _parseDate(payload['start_date']! as String),
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
              endDate: _parseDate(payload['end_date']! as String),
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

    return _ProjectionState(
      activeSchedules: activeSchedules,
      messagesByThread: messagesByThread.map(
        (key, value) =>
            MapEntry(key, List<ConversationMessageView>.unmodifiable(value)),
      ),
      pendingProposalsByThread: pendingByThread,
      schedulesById: schedulesById,
      threads: threads,
    );
  }

  static DateTime _parseDate(String value) {
    return DateTime.parse(value);
  }

  static DateTime? _tryParseDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }

  static ProposalActionView _proposalActionFromJson(Map<String, Object?> json) {
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
}
