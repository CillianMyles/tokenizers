import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';

/// A mutable-friendly medication schedule draft used by forms and commands.
class MedicationScheduleDraft {
  /// Creates a medication schedule draft.
  const MedicationScheduleDraft({
    required this.medicationName,
    required this.startDate,
    required this.times,
    this.doseAmount,
    this.doseUnit,
    this.endDate,
    this.notes,
    this.route,
  });

  /// Optional dose amount.
  final String? doseAmount;

  /// Optional dose unit.
  final String? doseUnit;

  /// Optional end date.
  final DateTime? endDate;

  /// Medication name.
  final String medicationName;

  /// Optional notes.
  final String? notes;

  /// Optional route.
  final String? route;

  /// Start date.
  final DateTime startDate;

  /// Fixed times per day in `HH:mm` format.
  final List<String> times;

  /// Creates a draft from a projected proposal action.
  factory MedicationScheduleDraft.fromProposalAction(
    ProposalActionView action,
  ) {
    return MedicationScheduleDraft(
      doseAmount: action.doseAmount,
      doseUnit: action.doseUnit,
      endDate: action.endDate,
      medicationName: action.medicationName ?? '',
      notes: action.notes,
      route: action.route,
      startDate: action.startDate ?? DateTime.now(),
      times: action.times,
    );
  }

  /// Creates a draft from an existing confirmed schedule.
  factory MedicationScheduleDraft.fromSchedule(
    MedicationScheduleView schedule,
  ) {
    return MedicationScheduleDraft(
      doseAmount: schedule.doseAmount,
      doseUnit: schedule.doseUnit,
      endDate: schedule.endDate,
      medicationName: schedule.medicationName,
      notes: schedule.notes,
      route: schedule.route,
      startDate: schedule.startDate,
      times: schedule.times,
    );
  }

  /// Whether the draft contains the minimum data needed to save a schedule.
  bool get isValid => medicationName.trim().isNotEmpty && times.isNotEmpty;

  /// Returns a copy with selected fields changed.
  MedicationScheduleDraft copyWith({
    String? doseAmount,
    String? doseUnit,
    DateTime? endDate,
    bool clearEndDate = false,
    String? medicationName,
    String? notes,
    String? route,
    DateTime? startDate,
    List<String>? times,
  }) {
    return MedicationScheduleDraft(
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      medicationName: medicationName ?? this.medicationName,
      notes: notes ?? this.notes,
      route: route ?? this.route,
      startDate: startDate ?? this.startDate,
      times: times ?? this.times,
    );
  }
}

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
  MedicationScheduleView copyWith({
    String? doseAmount,
    String? doseUnit,
    DateTime? endDate,
    bool clearEndDate = false,
    String? medicationName,
    String? notes,
    String? route,
    DateTime? startDate,
    List<String>? times,
  }) {
    return MedicationScheduleView(
      doseAmount: doseAmount ?? this.doseAmount,
      doseUnit: doseUnit ?? this.doseUnit,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      medicationName: medicationName ?? this.medicationName,
      notes: notes ?? this.notes,
      route: route ?? this.route,
      scheduleId: scheduleId,
      sourceProposalId: sourceProposalId,
      startDate: startDate ?? this.startDate,
      threadId: threadId,
      times: times ?? this.times,
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
