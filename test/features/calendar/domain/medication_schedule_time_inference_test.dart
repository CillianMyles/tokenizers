import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/medication_schedule_preferences.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_schedule_time_inference.dart';

void main() {
  group('medication schedule time inference', () {
    test('infers morning and evening for twice-daily text', () {
      expect(
        inferMedicationDayParts('Take magnesium 250 mg twice daily'),
        <MedicationDayPart>[
          MedicationDayPart.morning,
          MedicationDayPart.evening,
        ],
      );
    });

    test('aligns guessed times with nearby existing schedule times', () {
      final activeSchedules = <MedicationScheduleView>[
        MedicationScheduleView(
          medicationName: 'Tacrolimus',
          scheduleId: 'schedule-1',
          startDate: DateTime(2026, 4, 5),
          times: const <String>['08:00', '20:00'],
        ),
      ];

      final guessed = guessMedicationTimes(
        activeSchedules: activeSchedules,
        dayParts: const <MedicationDayPart>[
          MedicationDayPart.morning,
          MedicationDayPart.evening,
        ],
        preferences: const MedicationSchedulePreferences(),
      );

      expect(guessed, <String>['08:00', '20:00']);
    });

    test('upgrades a time-only missing-info action with guessed times', () {
      final activeSchedules = <MedicationScheduleView>[
        MedicationScheduleView(
          medicationName: 'Tacrolimus',
          scheduleId: 'schedule-1',
          startDate: DateTime(2026, 4, 5),
          times: const <String>['08:00', '20:00'],
        ),
      ];

      final action = applyMedicationTimeFallback(
        activeSchedules: activeSchedules,
        action: const ModelProposalAction(
          actionId: 'action-1',
          doseAmount: '250',
          doseUnit: 'mg',
          medicationName: 'Magnesium',
          missingFields: <String>['time'],
          type: ModelProposalActionType.requestMissingInfo,
        ),
        preferences: const MedicationSchedulePreferences(),
        userText: 'Add magnesium 250 mg twice daily',
      );

      expect(action.type, ModelProposalActionType.addMedicationSchedule);
      expect(action.times, <String>['08:00', '20:00']);
      expect(action.missingFields, isEmpty);
    });
  });
}
