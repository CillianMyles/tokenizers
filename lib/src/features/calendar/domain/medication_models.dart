/// A confirmed medication schedule projection.
class MedicationScheduleView {
  /// Creates a medication schedule view.
  const MedicationScheduleView({
    required this.medicationName,
    required this.scheduleId,
    required this.startDate,
    required this.times,
    this.doseAmount,
    this.doseUnit,
    this.endDate,
    this.notes,
    this.route,
    this.sourceProposalId,
    this.threadId,
  });

  /// Dose amount.
  final String? doseAmount;

  /// Dose unit.
  final String? doseUnit;

  /// Optional end date.
  final DateTime? endDate;

  /// Medication name.
  final String medicationName;

  /// Notes and instructions.
  final String? notes;

  /// Optional route.
  final String? route;

  /// Schedule id.
  final String scheduleId;

  /// The proposal that created this schedule.
  final String? sourceProposalId;

  /// Schedule start date.
  final DateTime startDate;

  /// The originating thread when known.
  final String? threadId;

  /// Fixed times per day in `HH:mm` format.
  final List<String> times;

  /// Whether the schedule remains active.
  bool get isActive => endDate == null;

  /// A human-readable dose label.
  String get doseLabel {
    if (doseAmount == null || doseUnit == null) {
      return 'Dose pending';
    }
    return '$doseAmount $doseUnit';
  }

  /// Returns a modified copy of this schedule.
  MedicationScheduleView copyWith({DateTime? endDate}) {
    return MedicationScheduleView(
      doseAmount: doseAmount,
      doseUnit: doseUnit,
      endDate: endDate ?? this.endDate,
      medicationName: medicationName,
      notes: notes,
      route: route,
      scheduleId: scheduleId,
      sourceProposalId: sourceProposalId,
      startDate: startDate,
      threadId: threadId,
      times: times,
    );
  }
}

/// A confirmed day-level calendar entry derived from a medication schedule.
class MedicationCalendarEntry {
  /// Creates a calendar entry.
  const MedicationCalendarEntry({
    required this.dateTime,
    required this.doseLabel,
    required this.medicationName,
    required this.scheduleId,
    this.notes,
    this.sourceProposalId,
    this.threadId,
  });

  /// When the medication should be taken.
  final DateTime dateTime;

  /// Display-ready dose label.
  final String doseLabel;

  /// Medication name.
  final String medicationName;

  /// Optional notes.
  final String? notes;

  /// Schedule id.
  final String scheduleId;

  /// The source proposal when known.
  final String? sourceProposalId;

  /// The source thread when known.
  final String? threadId;
}
