/// Adherence stats for a single day in the lookback window.
class AdherenceDayStats {
  /// Creates daily adherence stats.
  const AdherenceDayStats({
    required this.date,
    required this.scheduledDoses,
    required this.takenDoses,
  });

  /// Calendar day represented by this summary.
  final DateTime date;

  /// Number of doses scheduled for the day.
  final int scheduledDoses;

  /// Number of doses recorded as taken for the day.
  final int takenDoses;

  /// Whether no doses are scheduled for this day.
  bool get isEmpty => scheduledDoses == 0;

  /// Whether every scheduled dose has been recorded as taken.
  bool get isPerfect => scheduledDoses > 0 && takenDoses == scheduledDoses;

  /// Ratio of taken to scheduled doses, from 0.0 to 1.0.
  double get adherenceRate =>
      scheduledDoses == 0 ? 0 : takenDoses / scheduledDoses;
}

/// Adherence stats for a single medication over a date range.
class MedicationAdherenceStats {
  /// Creates adherence stats for one medication.
  const MedicationAdherenceStats({
    required this.medicationName,
    required this.scheduledDoses,
    required this.takenDoses,
    required this.currentStreak,
  });

  /// Medication name.
  final String medicationName;

  /// Number of doses scheduled in the lookback window.
  final int scheduledDoses;

  /// Number of doses recorded as taken in the lookback window.
  final int takenDoses;

  /// Consecutive completed days with all doses taken, counting
  /// backward from yesterday.
  final int currentStreak;

  /// Ratio of taken to scheduled doses, from 0.0 to 1.0.
  double get adherenceRate =>
      scheduledDoses == 0 ? 0 : takenDoses / scheduledDoses;
}

/// Overall adherence summary across all active medications.
class AdherenceSummary {
  /// Creates an adherence summary.
  const AdherenceSummary({
    required this.totalScheduledDoses,
    required this.totalTakenDoses,
    required this.byMedication,
    this.dailyBreakdown = const <AdherenceDayStats>[],
    required this.lookbackDays,
  });

  /// Total scheduled doses across all medications in the window.
  final int totalScheduledDoses;

  /// Total taken doses across all medications in the window.
  final int totalTakenDoses;

  /// Per-medication breakdown, sorted by name.
  final List<MedicationAdherenceStats> byMedication;

  /// Daily adherence breakdown for the lookback window, oldest first.
  final List<AdherenceDayStats> dailyBreakdown;

  /// Number of completed days included in the calculation.
  final int lookbackDays;

  /// Overall adherence ratio from 0.0 to 1.0.
  double get overallRate =>
      totalScheduledDoses == 0 ? 0 : totalTakenDoses / totalScheduledDoses;

  /// Whether there are no scheduled doses in the window.
  bool get isEmpty => totalScheduledDoses == 0;
}
