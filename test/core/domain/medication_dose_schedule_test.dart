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

    test('normalizes time-only ISO-like strings to HH:mm', () {
      final resolved = resolveMedicationDoseSchedule(
        doseSchedule: const <MedicationDoseScheduleEntry>[
          MedicationDoseScheduleEntry(
            doseAmount: '1.0',
            doseUnit: 'mg',
            time: '07:00:00.000000000Z',
          ),
        ],
      );

      expect(resolved.single.time, '07:00');
      expect(summarizeMedicationDoseSchedule(resolved), '07:00 • 1.0 mg');
    });
  });
}
