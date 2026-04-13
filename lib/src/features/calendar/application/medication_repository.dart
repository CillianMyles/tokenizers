import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Reads projected medication schedules and calendar entries.
abstract interface class MedicationRepository {
  /// Loads schedules active today.
  Future<List<MedicationScheduleView>> getActiveSchedules();

  /// Loads confirmed schedules that are current or start in the future.
  Future<List<MedicationScheduleView>> getCurrentAndUpcomingSchedules();

  /// Watches schedules that are active on the given [day].
  Stream<List<MedicationScheduleView>> watchActiveSchedules(DateTime day);

  /// Watches confirmed calendar entries for a specific day.
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  );
}
