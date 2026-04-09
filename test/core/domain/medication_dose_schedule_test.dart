import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';

void main() {
  group('resolveMedicationDoseSchedule', () {
    test('normalizes existing doseSchedule times to HH:mm', () {
      final resolved = resolveMedicationDoseSchedule(
        doseSchedule: const <MedicationDoseScheduleEntry>[
          MedicationDoseScheduleEntry(
            doseAmount: '1.2',
            doseUnit: 'mg',
            time: '2026-04-09T19:00:00.000',
          ),
        ],
      );

      expect(resolved.single.time, '19:00');
      expect(summarizeMedicationDoseSchedule(resolved), '19:00 • 1.2 mg');
    });
  });
}
