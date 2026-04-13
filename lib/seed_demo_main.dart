import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tokenizers/env/env.dart';
import 'package:tokenizers/src/bootstrap/demo_data_seeder.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/data/drift_event_store.dart';
import 'package:tokenizers/src/data/drift_workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  final database = AppDatabase();
  final eventStore = DriftEventStore(database: database);
  final workspace = DriftWorkspace(database: database, eventStore: eventStore);
  final seedScript = await rootBundle.loadString('assets/demo/demo_seed.txt');

  runApp(
    _SeedDemoApp(
      seedFuture: seedDemoData(
        database: database,
        eventStore: eventStore,
        projectionRunner: workspace,
        seedScript: seedScript,
        resetExistingData: const bool.fromEnvironment('RESET_DEMO_DATA'),
      ),
    ),
  );
}

class _SeedDemoApp extends StatelessWidget {
  const _SeedDemoApp({required this.seedFuture});

  final Future<DemoSeedSummary> seedFuture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<DemoSeedSummary>(
                future: seedFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData && !snapshot.hasError) {
                    return const _StatusCard(
                      title: 'Seeding Demo Data',
                      body: 'Writing demo events to local storage...',
                    );
                  }

                  if (snapshot.hasError) {
                    return _StatusCard(
                      title: 'Seed Failed',
                      body:
                          '${snapshot.error}\n\n'
                          'If you want to replace existing local data, rerun:\n'
                          'flutter run -t lib/seed_demo_main.dart '
                          '--dart-define=RESET_DEMO_DATA=true',
                    );
                  }

                  final summary = snapshot.data!;
                  return _StatusCard(
                    title: 'Seed Complete',
                    body:
                        'Seeded ${summary.activeScheduleCount} active schedules, '
                        '${summary.pendingProposalCount} pending proposal, and '
                        '${summary.eventCount} total events.\n\n'
                        'Close this app and launch the normal app entrypoint to '
                        'use the seeded data.',
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            SelectableText(body),
          ],
        ),
      ),
    );
  }
}
