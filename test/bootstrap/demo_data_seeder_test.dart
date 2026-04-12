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
}

Future<String> _loadDemoSeedScript() {
  return File('assets/demo/demo_seed.txt').readAsString();
}
