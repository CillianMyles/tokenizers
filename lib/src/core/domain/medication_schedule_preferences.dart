import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';

const _timePattern = r'^\d{2}:\d{2}$';

/// User-configurable default times for common medication day parts.
class MedicationSchedulePreferences {
  /// Creates medication schedule time preferences.
  const MedicationSchedulePreferences({
    this.eveningTime = defaultEveningTime,
    this.lunchTime = defaultLunchTime,
    this.morningTime = defaultMorningTime,
  });

  /// Default morning anchor time.
  static const String defaultMorningTime = '09:00';

  /// Default lunch anchor time.
  static const String defaultLunchTime = '13:00';

  /// Default evening anchor time.
  static const String defaultEveningTime = '19:00';

  /// Evening anchor time in `HH:mm`.
  final String eveningTime;

  /// Lunch anchor time in `HH:mm`.
  final String lunchTime;

  /// Morning anchor time in `HH:mm`.
  final String morningTime;

  /// Returns a normalized copy with any invalid values reset to defaults.
  MedicationSchedulePreferences normalized() {
    return MedicationSchedulePreferences(
      eveningTime: normalizeMedicationPreferenceTime(
        eveningTime,
        fallback: defaultEveningTime,
      ),
      lunchTime: normalizeMedicationPreferenceTime(
        lunchTime,
        fallback: defaultLunchTime,
      ),
      morningTime: normalizeMedicationPreferenceTime(
        morningTime,
        fallback: defaultMorningTime,
      ),
    );
  }

  /// Returns a copy with selected values replaced.
  MedicationSchedulePreferences copyWith({
    String? eveningTime,
    String? lunchTime,
    String? morningTime,
  }) {
    return MedicationSchedulePreferences(
      eveningTime: eveningTime ?? this.eveningTime,
      lunchTime: lunchTime ?? this.lunchTime,
      morningTime: morningTime ?? this.morningTime,
    );
  }
}

/// Normalizes a stored preference time into `HH:mm` or falls back.
String normalizeMedicationPreferenceTime(
  String value, {
  required String fallback,
}) {
  final normalized = normalizeMedicationTimeString(value);
  if (RegExp(_timePattern).hasMatch(normalized)) {
    return normalized;
  }
  return fallback;
}
