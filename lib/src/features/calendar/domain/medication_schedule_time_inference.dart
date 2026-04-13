import 'package:tokenizers/src/core/domain/medication_schedule_preferences.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

enum MedicationDayPart { morning, lunch, evening }

/// Applies a best-effort timing fallback for parsed model actions.
ModelProposalAction applyMedicationTimeFallback({
  required List<MedicationScheduleView> activeSchedules,
  required ModelProposalAction action,
  required MedicationSchedulePreferences preferences,
  required String userText,
}) {
  final resolvedTimes = action.resolvedTimes;
  if (resolvedTimes.isNotEmpty) {
    return _copyAction(action, times: resolvedTimes);
  }

  final requestedDayParts = inferMedicationDayParts(userText);
  if (requestedDayParts.isEmpty ||
      !_supportsTimeInference(action) ||
      !_hasEnoughActionContext(action)) {
    return action;
  }

  if (action.type == ModelProposalActionType.requestMissingInfo &&
      !_isOnlyTimeMissing(action.missingFields)) {
    return action;
  }

  final guessedTimes = guessMedicationTimes(
    activeSchedules: activeSchedules,
    dayParts: requestedDayParts,
    preferences: preferences,
  );
  if (guessedTimes.isEmpty) {
    return action;
  }

  return _copyAction(
    action,
    times: guessedTimes,
    type: switch (action.type) {
      ModelProposalActionType.requestMissingInfo =>
        action.targetScheduleId == null
            ? ModelProposalActionType.addMedicationSchedule
            : ModelProposalActionType.updateMedicationSchedule,
      _ => action.type,
    },
    missingFields: const <String>[],
  );
}

/// Infers medication day parts from user text.
List<MedicationDayPart> inferMedicationDayParts(String userText) {
  final normalized = userText.toLowerCase();
  final explicitDayParts = <MedicationDayPart>[
    if (_matches(normalized, r'\b(morning|breakfast)\b'))
      MedicationDayPart.morning,
    if (_matches(normalized, r'\b(lunch|midday|noon)\b'))
      MedicationDayPart.lunch,
    if (_matches(normalized, r'\b(evening|night|dinner|bedtime|bed time)\b'))
      MedicationDayPart.evening,
  ];
  if (explicitDayParts.isNotEmpty) {
    return explicitDayParts;
  }

  final doseCount = inferDailyDoseCount(normalized);
  return switch (doseCount) {
    1 => const <MedicationDayPart>[MedicationDayPart.morning],
    2 => const <MedicationDayPart>[
      MedicationDayPart.morning,
      MedicationDayPart.evening,
    ],
    3 => const <MedicationDayPart>[
      MedicationDayPart.morning,
      MedicationDayPart.lunch,
      MedicationDayPart.evening,
    ],
    _ => const <MedicationDayPart>[],
  };
}

/// Infers a simple daily dose count from user text when stated explicitly.
int? inferDailyDoseCount(String userText) {
  final normalized = userText.toLowerCase();
  if (_matches(
    normalized,
    r'\b(twice (daily|a day)|two times? (daily|a day)|2x (daily|a day)|bid|every 12 hours?)\b',
  )) {
    return 2;
  }
  if (_matches(
    normalized,
    r'\b(three times? (daily|a day)|3x (daily|a day)|tid|every 8 hours?)\b',
  )) {
    return 3;
  }
  if (_matches(
    normalized,
    r'\b(once (daily|a day)|daily|every day|once per day|qd)\b',
  )) {
    return 1;
  }
  return null;
}

/// Guesses concrete times for common medication day parts.
List<String> guessMedicationTimes({
  required List<MedicationScheduleView> activeSchedules,
  required List<MedicationDayPart> dayParts,
  required MedicationSchedulePreferences preferences,
}) {
  final usedTimes = <String>{};
  final guesses = <String>[];
  for (final dayPart in dayParts) {
    final anchor = switch (dayPart) {
      MedicationDayPart.morning => preferences.morningTime,
      MedicationDayPart.lunch => preferences.lunchTime,
      MedicationDayPart.evening => preferences.eveningTime,
    };
    final aligned = _alignToExistingSchedules(
      activeSchedules: activeSchedules,
      anchor: anchor,
      usedTimes: usedTimes,
    );
    guesses.add(aligned);
    usedTimes.add(aligned);
  }
  return List<String>.unmodifiable(guesses);
}

String _alignToExistingSchedules({
  required List<MedicationScheduleView> activeSchedules,
  required String anchor,
  required Set<String> usedTimes,
}) {
  final anchorMinutes = _minutesSinceMidnight(anchor);
  final scores = <String, int>{};

  for (final schedule in activeSchedules) {
    for (final time in schedule.resolvedTimes) {
      if (usedTimes.contains(time)) {
        continue;
      }
      final difference = (_minutesSinceMidnight(time) - anchorMinutes).abs();
      if (difference > 180) {
        continue;
      }
      scores.update(time, (score) => score + 1, ifAbsent: () => 1);
    }
  }

  if (scores.isEmpty) {
    return anchor;
  }

  final candidates = scores.keys.toList(growable: false)
    ..sort((left, right) {
      final scoreCompare = scores[right]!.compareTo(scores[left]!);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      final leftDifference = (_minutesSinceMidnight(left) - anchorMinutes)
          .abs();
      final rightDifference = (_minutesSinceMidnight(right) - anchorMinutes)
          .abs();
      final differenceCompare = leftDifference.compareTo(rightDifference);
      if (differenceCompare != 0) {
        return differenceCompare;
      }
      return left.compareTo(right);
    });
  return candidates.first;
}

bool _hasEnoughActionContext(ModelProposalAction action) {
  return (action.medicationName ?? '').trim().isNotEmpty;
}

bool _isOnlyTimeMissing(List<String> missingFields) {
  if (missingFields.isEmpty) {
    return false;
  }
  return missingFields.every((field) {
    final normalized = field.toLowerCase();
    return normalized.contains('time');
  });
}

bool _matches(String input, String pattern) {
  return RegExp(pattern, caseSensitive: false).hasMatch(input);
}

int _minutesSinceMidnight(String time) {
  final parts = time.split(':');
  return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
}

bool _supportsTimeInference(ModelProposalAction action) {
  return switch (action.type) {
    ModelProposalActionType.addMedicationSchedule => true,
    ModelProposalActionType.requestMissingInfo => true,
    ModelProposalActionType.stopMedicationSchedule => false,
    ModelProposalActionType.updateMedicationSchedule => true,
  };
}

ModelProposalAction _copyAction(
  ModelProposalAction action, {
  List<String>? missingFields,
  List<String>? times,
  ModelProposalActionType? type,
}) {
  return ModelProposalAction(
    actionId: action.actionId,
    doseAmount: action.doseAmount,
    doseSchedule: action.doseSchedule,
    doseUnit: action.doseUnit,
    endDate: action.endDate,
    medicationName: action.medicationName,
    missingFields: missingFields ?? action.missingFields,
    notes: action.notes,
    route: action.route,
    startDate: action.startDate,
    targetScheduleId: action.targetScheduleId,
    times: times ?? action.times,
    type: type ?? action.type,
  );
}
