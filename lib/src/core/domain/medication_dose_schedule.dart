/// A single timed dose within a daily medication schedule.
class MedicationDoseScheduleEntry {
  /// Creates a timed dose entry.
  const MedicationDoseScheduleEntry({
    required this.time,
    this.doseAmount,
    this.doseUnit,
  });

  /// Optional dose amount for this time.
  final String? doseAmount;

  /// Optional dose unit for this time.
  final String? doseUnit;

  /// Time of day in `HH:mm` format.
  final String time;

  /// Human-readable dose label for this time.
  String get doseLabel => formatMedicationDoseLabel(doseAmount, doseUnit);

  /// Serializes the entry for event payloads and JSON storage.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'dose_amount': doseAmount,
      'dose_unit': doseUnit,
      'time': time,
    };
  }
}

/// Formats a readable medication dose label from amount and unit.
String formatMedicationDoseLabel(String? doseAmount, String? doseUnit) {
  if (doseAmount == null || doseUnit == null) {
    return 'Dose pending';
  }
  return '$doseAmount $doseUnit';
}

/// Normalizes a time string into local `HH:mm` when possible.
String normalizeMedicationTimeString(String raw) {
  final trimmed = raw.trim();
  final timeOnlyMatch = RegExp(r'(?:^|T)(\d{1,2}):(\d{2})').firstMatch(trimmed);
  if (timeOnlyMatch != null) {
    final hour = timeOnlyMatch.group(1)!.padLeft(2, '0');
    final minute = timeOnlyMatch.group(2)!;
    return '$hour:$minute';
  }
  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  return trimmed;
}

/// Resolves a backward-compatible timed dose list from shared-dose data.
List<MedicationDoseScheduleEntry> resolveMedicationDoseSchedule({
  List<MedicationDoseScheduleEntry> doseSchedule =
      const <MedicationDoseScheduleEntry>[],
  String? fallbackDoseAmount,
  String? fallbackDoseUnit,
  List<String> fallbackTimes = const <String>[],
}) {
  final entries = doseSchedule.isNotEmpty
      ? doseSchedule
            .map(
              (entry) => MedicationDoseScheduleEntry(
                doseAmount: entry.doseAmount,
                doseUnit: entry.doseUnit,
                time: normalizeMedicationTimeString(entry.time),
              ),
            )
            .toList(growable: false)
      : fallbackTimes
            .map(
              (time) => MedicationDoseScheduleEntry(
                doseAmount: fallbackDoseAmount,
                doseUnit: fallbackDoseUnit,
                time: normalizeMedicationTimeString(time),
              ),
            )
            .toList(growable: false);
  entries.sort((left, right) => left.time.compareTo(right.time));
  return List<MedicationDoseScheduleEntry>.unmodifiable(entries);
}

/// Parses either legacy string times or rich timed-dose objects.
List<MedicationDoseScheduleEntry> medicationDoseScheduleFromJsonList(
  Object? raw, {
  String? fallbackDoseAmount,
  String? fallbackDoseUnit,
  List<String> fallbackTimes = const <String>[],
}) {
  final entries = <MedicationDoseScheduleEntry>[];
  if (raw case final List<Object?> values) {
    for (final value in values) {
      if (value case final String time) {
        entries.add(
          MedicationDoseScheduleEntry(
            doseAmount: fallbackDoseAmount,
            doseUnit: fallbackDoseUnit,
            time: normalizeMedicationTimeString(time),
          ),
        );
        continue;
      }
      if (value case final Map<Object?, Object?> json) {
        final typed = json.cast<String, Object?>();
        final time = typed['time'] as String?;
        if (time == null || time.isEmpty) {
          continue;
        }
        entries.add(
          MedicationDoseScheduleEntry(
            doseAmount: typed['dose_amount'] as String? ?? fallbackDoseAmount,
            doseUnit: typed['dose_unit'] as String? ?? fallbackDoseUnit,
            time: normalizeMedicationTimeString(time),
          ),
        );
      }
    }
  }

  return resolveMedicationDoseSchedule(
    doseSchedule: entries,
    fallbackDoseAmount: fallbackDoseAmount,
    fallbackDoseUnit: fallbackDoseUnit,
    fallbackTimes: fallbackTimes,
  );
}

/// Encodes a timed dose list for JSON/event payload storage.
List<Map<String, Object?>> medicationDoseScheduleToJsonList(
  List<MedicationDoseScheduleEntry> entries,
) {
  return entries.map((entry) => entry.toJson()).toList(growable: false);
}

/// Extracts normalized `HH:mm` times from a timed dose list.
List<String> medicationDoseScheduleTimes(
  List<MedicationDoseScheduleEntry> entries,
) {
  return entries
      .map((entry) => normalizeMedicationTimeString(entry.time))
      .toList(growable: false);
}

/// Returns whether the timed dose list varies across the day.
bool hasVariableMedicationDoses(List<MedicationDoseScheduleEntry> entries) {
  if (entries.isEmpty) {
    return false;
  }
  final first = entries.first;
  return entries.any((entry) {
    return entry.doseAmount != first.doseAmount ||
        entry.doseUnit != first.doseUnit;
  });
}

/// Produces a compact `HH:mm • dose` summary.
String summarizeMedicationDoseSchedule(
  List<MedicationDoseScheduleEntry> entries,
) {
  return entries
      .map(
        (entry) =>
            '${normalizeMedicationTimeString(entry.time)} • ${entry.doseLabel}',
      )
      .join(', ');
}
