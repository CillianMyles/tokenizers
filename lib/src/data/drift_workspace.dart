import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/application/event_store.dart';
import '../core/application/projection_runner.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';
import '../features/calendar/application/medication_repository.dart';
import '../features/calendar/domain/medication_models.dart';
import '../features/chat/application/conversation_repository.dart';
import '../features/chat/domain/conversation_models.dart';
import '../features/proposals/domain/proposal_models.dart';
import 'app_database.dart';
import 'projection_state.dart';

/// Drift-backed repositories and projection runner.
class DriftWorkspace
    implements ConversationRepository, MedicationRepository, ProjectionRunner {
  /// Creates a Drift workspace.
  DriftWorkspace({
    required AppDatabase database,
    required EventStore eventStore,
  }) : _database = database,
       _eventStore = eventStore {
    _subscription = _eventStore.watchAll().listen((_) {
      unawaited(_requestRebuild());
    });
  }

  final AppDatabase _database;
  final EventStore _eventStore;
  late final StreamSubscription<List<EventEnvelope<DomainEvent>>> _subscription;
  bool _rebuildQueued = false;
  bool _rebuildRunning = false;

  /// Releases background resources.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _database.close();
  }

  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    final query = _database.select(_database.messagesTable)
      ..where((table) => table.threadId.equals(threadId))
      ..orderBy(<OrderingTerm Function($MessagesTableTable)>[
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    final rows = await query.get();
    return rows.map(_messageFromRow).toList(growable: false);
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    final proposalRow = await _pendingProposalQuery(threadId).getSingleOrNull();
    if (proposalRow == null) {
      return null;
    }
    return _proposalFromRow(proposalRow);
  }

  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    final query = _database.select(_database.medicationSchedulesTable)
      ..where((table) => table.isActive.equals(true))
      ..orderBy(<OrderingTerm Function($MedicationSchedulesTableTable)>[
        (table) => OrderingTerm.asc(table.medicationName),
      ]);
    final rows = await query.get();
    return rows.map(_scheduleFromRow).toList(growable: false);
  }

  @override
  Future<void> rebuild() async {
    final state = ProjectionState.fromEvents(await _eventStore.loadAll());
    await _database.transaction(() async {
      await _database.delete(_database.conversationThreadsTable).go();
      await _database.delete(_database.messagesTable).go();
      await _database.delete(_database.proposalsTable).go();
      await _database.delete(_database.proposalActionsTable).go();
      await _database.delete(_database.medicationsTable).go();
      await _database.delete(_database.medicationScheduleTimesTable).go();
      await _database.delete(_database.medicationSchedulesTable).go();

      await _database.batch((batch) {
        batch.insertAll(
          _database.conversationThreadsTable,
          state.threads.map((thread) {
            return ConversationThreadsTableCompanion.insert(
              lastMessagePreview: thread.lastMessagePreview,
              lastUpdatedAt: thread.lastUpdatedAt,
              pendingProposalCount: thread.pendingProposalCount,
              threadId: thread.threadId,
              title: thread.title,
            );
          }).toList(),
        );

        final messageRows = <MessagesTableCompanion>[];
        for (final threadMessages in state.messagesByThread.values) {
          for (final message in threadMessages) {
            messageRows.add(
              MessagesTableCompanion.insert(
                actor: message.actor.name,
                body: message.text,
                createdAt: message.createdAt,
                messageId: message.messageId,
                threadId: message.threadId,
              ),
            );
          }
        }
        batch.insertAll(_database.messagesTable, messageRows);

        batch.insertAll(
          _database.proposalsTable,
          state.proposalsById.values.map((proposal) {
            return ProposalsTableCompanion.insert(
              assistantText: proposal.assistantText,
              createdAt: proposal.createdAt,
              proposalId: proposal.proposalId,
              status: proposal.status.name,
              summary: proposal.summary,
              threadId: proposal.threadId,
            );
          }).toList(),
        );

        final actionRows = <ProposalActionsTableCompanion>[];
        for (final proposal in state.proposalsById.values) {
          for (final action in proposal.actions) {
            actionRows.add(
              ProposalActionsTableCompanion.insert(
                actionId: action.actionId,
                doseAmount: Value(action.doseAmount),
                doseUnit: Value(action.doseUnit),
                endDate: Value(_dateText(action.endDate)),
                medicationName: Value(action.medicationName),
                missingFieldsJson: jsonEncode(action.missingFields),
                notes: Value(action.notes),
                proposalId: proposal.proposalId,
                route: Value(action.route),
                startDate: Value(_dateText(action.startDate)),
                targetScheduleId: Value(action.targetScheduleId),
                timesJson: jsonEncode(action.times),
                type: action.type.wireValue,
              ),
            );
          }
        }
        batch.insertAll(_database.proposalActionsTable, actionRows);

        batch.insertAll(
          _database.medicationsTable,
          state.medicationsById.entries.map((entry) {
            return MedicationsTableCompanion.insert(
              medicationId: entry.key,
              medicationName: entry.value,
            );
          }).toList(),
        );

        batch.insertAll(
          _database.medicationSchedulesTable,
          state.schedulesById.values.map((schedule) {
            return MedicationSchedulesTableCompanion.insert(
              doseAmount: Value(schedule.doseAmount),
              doseUnit: Value(schedule.doseUnit),
              endDate: Value(_dateText(schedule.endDate)),
              isActive: schedule.isActive,
              medicationName: schedule.medicationName,
              notes: Value(schedule.notes),
              route: Value(schedule.route),
              scheduleId: schedule.scheduleId,
              sourceProposalId: Value(schedule.sourceProposalId),
              startDate: _dateText(schedule.startDate)!,
              threadId: Value(schedule.threadId),
              timesJson: jsonEncode(schedule.times),
            );
          }).toList(),
        );

        final timeRows = <MedicationScheduleTimesTableCompanion>[];
        for (final schedule in state.schedulesById.values) {
          for (final time in schedule.times) {
            timeRows.add(
              MedicationScheduleTimesTableCompanion.insert(
                scheduleId: schedule.scheduleId,
                timeOfDay: time,
              ),
            );
          }
        }
        batch.insertAll(_database.medicationScheduleTimesTable, timeRows);
      });
    });
  }

  Future<void> _requestRebuild() async {
    _rebuildQueued = true;
    if (_rebuildRunning) {
      return;
    }

    _rebuildRunning = true;
    try {
      while (_rebuildQueued) {
        _rebuildQueued = false;
        await rebuild();
      }
    } finally {
      _rebuildRunning = false;
    }
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) {
    final dayText = _dateText(day)!;
    final joinQuery =
        _database.select(_database.medicationScheduleTimesTable).join(<Join>[
            innerJoin(
              _database.medicationSchedulesTable,
              _database.medicationSchedulesTable.scheduleId.equalsExp(
                _database.medicationScheduleTimesTable.scheduleId,
              ),
            ),
          ])
          ..where(
            _database.medicationSchedulesTable.isActive.equals(true) &
                _database.medicationSchedulesTable.startDate
                    .isSmallerOrEqualValue(dayText) &
                (_database.medicationSchedulesTable.endDate.isNull() |
                    _database.medicationSchedulesTable.endDate
                        .isBiggerOrEqualValue(dayText)),
          )
          ..orderBy(<OrderingTerm>[
            OrderingTerm.asc(_database.medicationScheduleTimesTable.timeOfDay),
            OrderingTerm.asc(_database.medicationSchedulesTable.medicationName),
          ]);

    return joinQuery.watch().map((rows) {
      return rows
          .map((row) {
            final schedule = row.readTable(_database.medicationSchedulesTable);
            final time = row.readTable(_database.medicationScheduleTimesTable);
            final parts = time.timeOfDay.split(':');
            return MedicationCalendarEntry(
              dateTime: DateTime(
                day.year,
                day.month,
                day.day,
                int.parse(parts[0]),
                int.parse(parts[1]),
              ),
              doseLabel: _doseLabel(schedule.doseAmount, schedule.doseUnit),
              medicationName: schedule.medicationName,
              notes: schedule.notes,
              scheduleId: schedule.scheduleId,
              sourceProposalId: schedule.sourceProposalId,
              threadId: schedule.threadId,
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules() {
    final query = _database.select(_database.medicationSchedulesTable)
      ..where((table) => table.isActive.equals(true))
      ..orderBy(<OrderingTerm Function($MedicationSchedulesTableTable)>[
        (table) => OrderingTerm.asc(table.medicationName),
      ]);
    return query.watch().map(
      (rows) => rows.map(_scheduleFromRow).toList(growable: false),
    );
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) {
    final query = _database.select(_database.messagesTable)
      ..where((table) => table.threadId.equals(threadId))
      ..orderBy(<OrderingTerm Function($MessagesTableTable)>[
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_messageFromRow).toList(growable: false),
    );
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) {
    return _pendingProposalQuery(threadId).watchSingleOrNull().asyncMap(
      (row) => row == null ? null : _proposalFromRow(row),
    );
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() {
    final query = _database.select(_database.conversationThreadsTable)
      ..orderBy(<OrderingTerm Function($ConversationThreadsTableTable)>[
        (table) => OrderingTerm.desc(table.lastUpdatedAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_threadFromRow).toList(growable: false),
    );
  }

  ConversationMessageView _messageFromRow(MessagesTableData row) {
    return ConversationMessageView(
      actor: switch (row.actor) {
        'model' => ConversationActor.model,
        'system' => ConversationActor.system,
        _ => ConversationActor.user,
      },
      createdAt: row.createdAt,
      messageId: row.messageId,
      text: row.body,
      threadId: row.threadId,
    );
  }

  ConversationThreadView _threadFromRow(ConversationThreadsTableData row) {
    return ConversationThreadView(
      lastMessagePreview: row.lastMessagePreview,
      lastUpdatedAt: row.lastUpdatedAt,
      pendingProposalCount: row.pendingProposalCount,
      threadId: row.threadId,
      title: row.title,
    );
  }

  MedicationScheduleView _scheduleFromRow(MedicationSchedulesTableData row) {
    return MedicationScheduleView(
      doseAmount: row.doseAmount,
      doseUnit: row.doseUnit,
      endDate: _tryDate(row.endDate),
      medicationName: row.medicationName,
      notes: row.notes,
      route: row.route,
      scheduleId: row.scheduleId,
      sourceProposalId: row.sourceProposalId,
      startDate: DateTime.parse(row.startDate),
      threadId: row.threadId,
      times: _stringList(row.timesJson),
    );
  }

  SimpleSelectStatement<$ProposalsTableTable, ProposalsTableData>
  _pendingProposalQuery(String threadId) {
    return _database.select(_database.proposalsTable)
      ..where(
        (table) =>
            table.threadId.equals(threadId) & table.status.equals('pending'),
      )
      ..orderBy(<OrderingTerm Function($ProposalsTableTable)>[
        (table) => OrderingTerm.desc(table.createdAt),
      ])
      ..limit(1);
  }

  Future<ProposalView> _proposalFromRow(ProposalsTableData row) async {
    final actionQuery = _database.select(_database.proposalActionsTable)
      ..where((table) => table.proposalId.equals(row.proposalId))
      ..orderBy(<OrderingTerm Function($ProposalActionsTableTable)>[
        (table) => OrderingTerm.asc(table.actionId),
      ]);
    final actionRows = await actionQuery.get();
    return ProposalView(
      actions: actionRows.map(_proposalActionFromRow).toList(growable: false),
      assistantText: row.assistantText,
      createdAt: row.createdAt,
      proposalId: row.proposalId,
      status: ProposalStatus.values.firstWhere(
        (status) => status.name == row.status,
      ),
      summary: row.summary,
      threadId: row.threadId,
    );
  }

  ProposalActionView _proposalActionFromRow(ProposalActionsTableData row) {
    return ProposalActionView(
      actionId: row.actionId,
      doseAmount: row.doseAmount,
      doseUnit: row.doseUnit,
      endDate: _tryDate(row.endDate),
      medicationName: row.medicationName,
      missingFields: _stringList(row.missingFieldsJson),
      notes: row.notes,
      route: row.route,
      startDate: _tryDate(row.startDate),
      targetScheduleId: row.targetScheduleId,
      times: _stringList(row.timesJson),
      type: ProposalActionType.values.firstWhere(
        (type) => type.wireValue == row.type,
      ),
    );
  }

  String _doseLabel(String? doseAmount, String? doseUnit) {
    if (doseAmount == null || doseUnit == null) {
      return 'Dose pending';
    }
    return '$doseAmount $doseUnit';
  }

  String? _dateText(DateTime? value) {
    return value?.toIso8601String().split('T').first;
  }

  DateTime? _tryDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }

  List<String> _stringList(String encoded) {
    return (jsonDecode(encoded) as List<Object?>).whereType<String>().toList();
  }
}
