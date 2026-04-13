import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';

/// The projected proposal status.
enum ProposalStatus { pending, confirmed, cancelled, superseded }

/// Proposal action types supported in v0.
enum ProposalActionType {
  addMedicationSchedule('add_medication_schedule'),
  requestMissingInfo('request_missing_info'),
  stopMedicationSchedule('stop_medication_schedule'),
  updateMedicationSchedule('update_medication_schedule');

  const ProposalActionType(this.wireValue);

  /// Wire-format value stored in the event log.
  final String wireValue;
}

/// A projected proposal action.
class ProposalActionView {
  /// Creates a proposal action view.
  const ProposalActionView({
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

  /// Action id.
  final String actionId;

  /// Optional per-time doses.
  final List<MedicationDoseScheduleEntry> doseSchedule;

  /// Dose amount.
  final String? doseAmount;

  /// Dose unit.
  final String? doseUnit;

  /// Optional end date.
  final DateTime? endDate;

  /// Medication name.
  final String? medicationName;

  /// Required missing fields for follow-up.
  final List<String> missingFields;

  /// Notes and instructions.
  final String? notes;

  /// Optional route.
  final String? route;

  /// Optional start date.
  final DateTime? startDate;

  /// Existing schedule being changed.
  final String? targetScheduleId;

  /// Fixed times per day.
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

  /// Supported proposal action type.
  final ProposalActionType type;

  /// A compact summary of the action.
  String get summary {
    return switch (type) {
      ProposalActionType.addMedicationSchedule =>
        'Add ${medicationName ?? 'medication'}'
            '${resolvedDoseSchedule.isEmpty ? '' : ' • ${summarizeMedicationDoseSchedule(resolvedDoseSchedule)}'}',
      ProposalActionType.requestMissingInfo =>
        'Missing: ${missingFields.map(humanReadableFieldLabel).join(', ')}',
      ProposalActionType.stopMedicationSchedule =>
        'Stop ${medicationName ?? 'active schedule'}',
      ProposalActionType.updateMedicationSchedule =>
        'Update ${medicationName ?? 'schedule'}',
    };
  }
}

/// Maps a raw missing-field identifier to a human-readable label.
String humanReadableFieldLabel(String field) {
  return switch (field) {
    'start_date' => 'Start date',
    'end_date' => 'End date',
    'time' || 'times' => 'Dosing times',
    'dose_amount' => 'Dose amount',
    'dose_unit' => 'Dose unit',
    'medication_name' => 'Medication name',
    'route' => 'Route',
    'dose_schedule' => 'Dose schedule',
    'notes' => 'Notes',
    _ => _capitalize(field.replaceAll('_', ' ')),
  };
}

String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// A projected medication proposal.
class ProposalView {
  /// Creates a proposal view.
  const ProposalView({
    required this.actions,
    required this.assistantText,
    required this.createdAt,
    required this.proposalId,
    required this.status,
    required this.summary,
    required this.threadId,
  });

  /// Structured proposed actions.
  final List<ProposalActionView> actions;

  /// Assistant text for the user.
  final String assistantText;

  /// Proposal creation time.
  final DateTime createdAt;

  /// Proposal id.
  final String proposalId;

  /// Current proposal status.
  final ProposalStatus status;

  /// Summary text.
  final String summary;

  /// Parent thread id.
  final String threadId;

  /// Whether the proposal can safely be confirmed.
  bool get isConfirmable =>
      actions.isNotEmpty &&
      actions.every(
        (action) => action.type != ProposalActionType.requestMissingInfo,
      );

  /// Returns a modified copy of the proposal.
  ProposalView copyWith({
    List<ProposalActionView>? actions,
    ProposalStatus? status,
    String? summary,
  }) {
    return ProposalView(
      actions: actions ?? this.actions,
      assistantText: assistantText,
      createdAt: createdAt,
      proposalId: proposalId,
      status: status ?? this.status,
      summary: summary ?? this.summary,
      threadId: threadId,
    );
  }
}
