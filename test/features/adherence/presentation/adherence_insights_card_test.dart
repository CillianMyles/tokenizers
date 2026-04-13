import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/features/adherence/domain/adherence_models.dart';
import 'package:tokenizers/src/features/adherence/presentation/adherence_insights_card.dart';

void main() {
  testWidgets('renders overall summary, heatmap, and medication rows', (
    tester,
  ) async {
    final summary = AdherenceSummary(
      totalScheduledDoses: 35,
      totalTakenDoses: 31,
      lookbackDays: 7,
      dailyBreakdown: <AdherenceDayStats>[
        AdherenceDayStats(
          date: DateTime(2026, 4, 7),
          scheduledDoses: 5,
          takenDoses: 5,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 8),
          scheduledDoses: 5,
          takenDoses: 5,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 9),
          scheduledDoses: 5,
          takenDoses: 4,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 10),
          scheduledDoses: 5,
          takenDoses: 5,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 11),
          scheduledDoses: 5,
          takenDoses: 4,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 12),
          scheduledDoses: 5,
          takenDoses: 5,
        ),
        AdherenceDayStats(
          date: DateTime(2026, 4, 13),
          scheduledDoses: 5,
          takenDoses: 3,
        ),
      ],
      byMedication: <MedicationAdherenceStats>[
        MedicationAdherenceStats(
          medicationName: 'Tacrolimus',
          scheduledDoses: 14,
          takenDoses: 14,
          currentStreak: 7,
        ),
        MedicationAdherenceStats(
          medicationName: 'Metformin',
          scheduledDoses: 14,
          takenDoses: 12,
          currentStreak: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: AdherenceInsightsCard(summary: summary),
          ),
        ),
      ),
    );

    expect(find.text('Adherence insights'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('89% overall • 31 of 35 doses'), findsOneWidget);
    expect(find.text('Week at a glance'), findsOneWidget);
    expect(find.text('By medication'), findsOneWidget);
    expect(find.text('Tacrolimus'), findsOneWidget);
    expect(find.text('14 of 14 doses'), findsOneWidget);
    expect(find.text('Metformin'), findsOneWidget);
    expect(find.text('12 of 14 doses'), findsOneWidget);
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('3/5'), findsOneWidget);
  });

  testWidgets('shows streak badges whenever the current streak is non-zero', (
    tester,
  ) async {
    const summary = AdherenceSummary(
      totalScheduledDoses: 14,
      totalTakenDoses: 12,
      lookbackDays: 7,
      byMedication: <MedicationAdherenceStats>[
        MedicationAdherenceStats(
          medicationName: 'Metformin',
          scheduledDoses: 14,
          takenDoses: 12,
          currentStreak: 3,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: SingleChildScrollView(
            child: AdherenceInsightsCard(summary: summary),
          ),
        ),
      ),
    );

    expect(find.text('3-day streak'), findsOneWidget);
    expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
  });

  testWidgets('hides when summary is empty', (tester) async {
    const summary = AdherenceSummary(
      totalScheduledDoses: 0,
      totalTakenDoses: 0,
      lookbackDays: 7,
      byMedication: <MedicationAdherenceStats>[],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: AdherenceInsightsCard(summary: summary)),
      ),
    );

    expect(find.text('Adherence insights'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });
}
