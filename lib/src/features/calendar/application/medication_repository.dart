import '../domain/medication_models.dart';

/// Reads projected medication schedules and calendar entries.
abstract interface class MedicationRepository {
  /// Loads active schedules.
  Future<List<MedicationScheduleView>> getActiveSchedules();

  /// Watches active schedules.
  Stream<List<MedicationScheduleView>> watchActiveSchedules();

  /// Watches confirmed calendar entries for a specific day.
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  );
}
