import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/bootstrap/demo_data_seeder.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/drift_workspace.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

void main() {
  test(
    'seedDemoData writes active schedules, history, and a pending proposal',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );

      final summary = await seedDemoData(
        database: database,
        eventStore: eventStore,
        projectionRunner: workspace,
        seedScript: await _loadDemoSeedScript(),
        now: DateTime(2026, 4, 9, 12),
      );

      final schedules = await workspace.getActiveSchedules();
      final proposal = await workspace.getPendingProposal('thread-current');
      final messages = await workspace.getMessages('thread-current');
      final events = await eventStore.loadAll();

      expect(summary.activeScheduleCount, 3);
      expect(summary.pendingProposalCount, 1);
      expect(summary.eventCount, events.length);
      expect(
        schedules.map((schedule) => schedule.medicationName).toSet(),
        <String>{'Metformin', 'Vitamin D', 'Tacrolimus'},
      );
      expect(proposal, isNotNull);
      expect(proposal?.status, isNot(ProposalStatus.confirmed));
      expect(proposal?.actions.single.medicationName, 'Magnesium glycinate');
      expect(messages, hasLength(2));
      expect(
        events.any((event) => event.event.type == 'medication_taken'),
        isTrue,
      );
      expect(
        events.any((event) => event.event.type == 'medication_taken_corrected'),
        isTrue,
      );

      await workspace.dispose();
    },
  );

  test(
    'seedDemoData refuses to overwrite existing data without reset',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );

      await seedDemoData(
        database: database,
        eventStore: eventStore,
        projectionRunner: workspace,
        seedScript: await _loadDemoSeedScript(),
        now: DateTime(2026, 4, 9, 12),
      );

      final seedScript = await _loadDemoSeedScript();
      expect(
        () => seedDemoData(
          database: database,
          eventStore: eventStore,
          projectionRunner: workspace,
          seedScript: seedScript,
          now: DateTime(2026, 4, 9, 12),
        ),
        throwsStateError,
      );

      await workspace.dispose();
    },
  );

  test(
    'seedDemoData validates the script before wiping existing data on reset',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );

      await seedDemoData(
        database: database,
        eventStore: eventStore,
        projectionRunner: workspace,
        seedScript: await _loadDemoSeedScript(),
        now: DateTime(2026, 4, 9, 12),
      );

      final eventCountBefore = (await eventStore.loadAll()).length;

      expect(
        () => seedDemoData(
          database: database,
          eventStore: eventStore,
          projectionRunner: workspace,
          seedScript: 'BROKEN|foo=bar',
          resetExistingData: true,
          now: DateTime(2026, 4, 9, 12),
        ),
        throwsStateError,
      );

      expect((await eventStore.loadAll()).length, eventCountBefore);

      await workspace.dispose();
    },
  );

  test(
    'seedDemoData creates historical taken events via date_offset_days',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final eventStore = DriftEventStore(database: database);
      final workspace = DriftWorkspace(
        database: database,
        eventStore: eventStore,
      );

      final seedNow = DateTime(2026, 4, 9, 12);
      await seedDemoData(
        database: database,
        eventStore: eventStore,
        projectionRunner: workspace,
        seedScript: await _loadDemoSeedScript(),
        now: seedNow,
      );

      final events = await eventStore.loadAll();
      final takenEvents = events.where((event) {
        return event.event.type == 'medication_taken';
      }).toList();

      // Historical TAKEN records span multiple days.
      final takenDates = takenEvents
          .map((event) {
            final raw = event.event.payload['scheduled_for'] as String;
            return DateTime.parse(raw);
          })
          .map((dt) => DateTime(dt.year, dt.month, dt.day))
          .toSet();

      // Should have at least today and several past days.
      expect(takenDates.length, greaterThan(1));

      // Verify a specific offset: day -7 from seed date (April 2).
      final expectedDay = DateTime(2026, 4, 2);
      expect(takenDates.contains(expectedDay), isTrue);

      await workspace.dispose();
    },
  );

  test('seedDemoData preserves deterministic schedule timestamps', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final eventStore = DriftEventStore(database: database);
    final workspace = DriftWorkspace(
      database: database,
      eventStore: eventStore,
    );

    await seedDemoData(
      database: database,
      eventStore: eventStore,
      projectionRunner: workspace,
      seedScript: await _loadDemoSeedScript(),
      now: DateTime(2026, 4, 9, 12),
    );

    final events = await eventStore.loadAll();
    final metforminScheduleAdded = events.firstWhere((event) {
      return event.event.type == 'medication_schedule_added' &&
          event.event.payload['medication_name'] == 'Metformin';
    });

    expect(
      DateTime(
        metforminScheduleAdded.occurredAt.toLocal().year,
        metforminScheduleAdded.occurredAt.toLocal().month,
        metforminScheduleAdded.occurredAt.toLocal().day,
      ),
      DateTime(2026, 3, 10),
    );

    await workspace.dispose();
  });
}

Future<String> _loadDemoSeedScript() {
  return File('assets/demo/demo_seed.txt').readAsString();
}
