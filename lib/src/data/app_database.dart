import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart';

part 'app_database.g.dart';

/// Immutable event log table.
class EventLog extends Table {
  /// Event id.
  TextColumn get eventId => text()();

  /// Aggregate type.
  TextColumn get aggregateType => text()();

  /// Aggregate id.
  TextColumn get aggregateId => text()();

  /// Event type.
  TextColumn get eventType => text()();

  /// Event occurrence time.
  DateTimeColumn get occurredAt => dateTime()();

  /// Optional causation id.
  TextColumn get causationId => text().nullable()();

  /// Optional correlation id.
  TextColumn get correlationId => text().nullable()();

  /// Actor type.
  TextColumn get actorType => text()();

  /// JSON payload.
  TextColumn get payloadJson => text()();

  @override
  String get tableName => 'event_log';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{eventId};
}

/// Conversation thread projection table.
class ConversationThreadsTable extends Table {
  /// Thread id.
  TextColumn get threadId => text()();

  /// Thread title.
  TextColumn get title => text()();

  /// Latest preview text.
  TextColumn get lastMessagePreview => text()();

  /// Last updated time.
  DateTimeColumn get lastUpdatedAt => dateTime()();

  /// Number of pending proposals.
  IntColumn get pendingProposalCount => integer()();

  @override
  String get tableName => 'conversation_threads_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{threadId};
}

/// Message projection table.
class MessagesTable extends Table {
  /// Message id.
  TextColumn get messageId => text()();

  /// Parent thread.
  TextColumn get threadId => text()();

  /// Actor value.
  TextColumn get actor => text()();

  /// Message body.
  TextColumn get body => text()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime()();

  @override
  String get tableName => 'messages_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{messageId};
}

/// Proposal projection table.
class ProposalsTable extends Table {
  /// Proposal id.
  TextColumn get proposalId => text()();

  /// Thread id.
  TextColumn get threadId => text()();

  /// Proposal summary.
  TextColumn get summary => text()();

  /// Assistant text.
  TextColumn get assistantText => text()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime()();

  /// Proposal status.
  TextColumn get status => text()();

  @override
  String get tableName => 'proposals_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{proposalId};
}

/// Proposal action projection table.
class ProposalActionsTable extends Table {
  /// Action id.
  TextColumn get actionId => text()();

  /// Parent proposal id.
  TextColumn get proposalId => text()();

  /// Action type.
  TextColumn get type => text()();

  /// Optional medication name.
  TextColumn get medicationName => text().nullable()();

  /// Optional dose amount.
  TextColumn get doseAmount => text().nullable()();

  /// Optional dose unit.
  TextColumn get doseUnit => text().nullable()();

  /// Optional route.
  TextColumn get route => text().nullable()();

  /// Optional start date.
  TextColumn get startDate => text().nullable()();

  /// Optional end date.
  TextColumn get endDate => text().nullable()();

  /// Encoded times list.
  TextColumn get timesJson => text()();

  /// Optional notes.
  TextColumn get notes => text().nullable()();

  /// Optional target schedule id.
  TextColumn get targetScheduleId => text().nullable()();

  /// Encoded missing fields list.
  TextColumn get missingFieldsJson => text()();

  @override
  String get tableName => 'proposal_actions_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{actionId};
}

/// Medication projection table.
class MedicationsTable extends Table {
  /// Medication id.
  TextColumn get medicationId => text()();

  /// Medication name.
  TextColumn get medicationName => text()();

  @override
  String get tableName => 'medications_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{medicationId};
}

/// Medication schedule projection table.
class MedicationSchedulesTable extends Table {
  /// Schedule id.
  TextColumn get scheduleId => text()();

  /// Medication name.
  TextColumn get medicationName => text()();

  /// Optional dose amount.
  TextColumn get doseAmount => text().nullable()();

  /// Optional dose unit.
  TextColumn get doseUnit => text().nullable()();

  /// Optional route.
  TextColumn get route => text().nullable()();

  /// Start date.
  TextColumn get startDate => text()();

  /// Optional end date.
  TextColumn get endDate => text().nullable()();

  /// Encoded times list.
  TextColumn get timesJson => text()();

  /// Optional notes.
  TextColumn get notes => text().nullable()();

  /// Source proposal id.
  TextColumn get sourceProposalId => text().nullable()();

  /// Source thread id.
  TextColumn get threadId => text().nullable()();

  /// Active flag.
  BoolColumn get isActive => boolean()();

  @override
  String get tableName => 'medication_schedules_view';

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{scheduleId};
}

/// Time-of-day projection rows for medication schedules.
class MedicationScheduleTimesTable extends Table {
  /// Synthetic id.
  IntColumn get id => integer().autoIncrement()();

  /// Parent schedule id.
  TextColumn get scheduleId => text()();

  /// Time in `HH:mm`.
  TextColumn get timeOfDay => text()();

  @override
  String get tableName => 'medication_schedule_times_view';
}

@DriftDatabase(
  tables: <Type>[
    EventLog,
    ConversationThreadsTable,
    MessagesTable,
    ProposalsTable,
    ProposalActionsTable,
    MedicationsTable,
    MedicationSchedulesTable,
    MedicationScheduleTimesTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Opens the application database.
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'tokenizers_v0',
    native: DriftNativeOptions(
      shareAcrossIsolates: true,
      setup: _configureNativeDatabase,
    ),
  );
}

void _configureNativeDatabase(CommonDatabase database) {
  database.execute('pragma journal_mode = WAL;');
}
