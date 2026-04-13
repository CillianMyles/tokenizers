import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';

/// The model-owned medication proposal action type.
enum ModelProposalActionType {
  addMedicationSchedule,
  requestMissingInfo,
  stopMedicationSchedule,
  updateMedicationSchedule,
}

/// A proposed medication action returned by a model provider.
class ModelProposalAction {
  /// Creates a model proposal action.
  const ModelProposalAction({
    required this.actionId,
    required this.type,
    this.doseSchedule = const <MedicationDoseScheduleEntry>[],
    this.doseAmount,
    this.doseUnit,
    this.endDate,
    this.medicationName,
    this.missingFields = const <String>[],
    this.notes,
    this.route,
    this.startDate,
    this.targetScheduleId,
    this.times = const <String>[],
  });

  /// Stable action id.
  final String actionId;

  /// Proposed action type.
  final ModelProposalActionType type;

  /// Optional per-time doses.
  final List<MedicationDoseScheduleEntry> doseSchedule;

  /// Dose amount, when present.
  final String? doseAmount;

  /// Dose unit, when present.
  final String? doseUnit;

  /// Optional end date.
  final DateTime? endDate;

  /// Medication name, when present.
  final String? medicationName;

  /// Missing fields required before confirmation.
  final List<String> missingFields;

  /// Optional notes.
  final String? notes;

  /// Optional route.
  final String? route;

  /// Start date for the schedule.
  final DateTime? startDate;

  /// Target schedule when modifying an existing schedule.
  final String? targetScheduleId;

  /// Fixed times per day in `HH:mm` format.
  final List<String> times;

  /// Timed dose entries resolved from either legacy or rich schedule data.
  List<MedicationDoseScheduleEntry> get resolvedDoseSchedule {
    return resolveMedicationDoseSchedule(
      doseSchedule: doseSchedule,
      fallbackDoseAmount: doseAmount,
      fallbackDoseUnit: doseUnit,
      fallbackTimes: times,
    );
  }

  /// Resolved times derived from the effective timed dose entries.
  List<String> get resolvedTimes =>
      medicationDoseScheduleTimes(resolvedDoseSchedule);
}

/// The app-owned response contract returned by a model provider.
class ModelResponseContract {
  /// Creates a model response contract.
  const ModelResponseContract({
    required this.actions,
    required this.assistantText,
    required this.rawPayload,
    this.version = 'v0',
  });

  /// Structured proposed actions.
  final List<ModelProposalAction> actions;

  /// Conversational assistant text for the user.
  final String assistantText;

  /// Raw model payload preserved for audit and debugging.
  final Map<String, Object?> rawPayload;

  /// Schema version for the response contract.
  final String version;
}
