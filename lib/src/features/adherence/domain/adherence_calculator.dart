import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/features/adherence/domain/adherence_models.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';

/// Calculates adherence statistics from schedules and events.
///
/// The lookback window covers the current day and the preceding
/// `lookbackDays - 1` days. For the current day, only doses scheduled up to
/// [today] are counted so upcoming doses do not lower the score prematurely.
AdherenceSummary calculateAdherence({
  required List<MedicationScheduleView> schedules,
  required List<EventEnvelope<DomainEvent>> events,
  required DateTime today,
  int lookbackDays = 7,
}) {
  if (lookbackDays <= 0) {
    return const AdherenceSummary(
      totalScheduledDoses: 0,
      totalTakenDoses: 0,
      byMedication: <MedicationAdherenceStats>[],
      lookbackDays: 0,
    );
  }

  final todayDate = _dateOnly(today);
  final firstDay = todayDate.subtract(Duration(days: lookbackDays - 1));
  final windowDays = List<DateTime>.generate(
    lookbackDays,
    (index) => firstDay.add(Duration(days: index)),
    growable: false,
  );
  final takenKeys = _takenDoseKeys(events);
  final overallDaily = List<_DailyAccumulator>.generate(
    lookbackDays,
    (_) => _DailyAccumulator(),
    growable: false,
  );
  final byMedication = <String, _MedicationAccumulator>{};

  for (final schedule in schedules) {
    final medicationName = schedule.medicationName.trim();
    if (medicationName.isEmpty) {
      continue;
    }
    final startDate = _dateOnly(schedule.startDate);
    final endDate = schedule.endDate == null
        ? null
        : _dateOnly(schedule.endDate!);
    final medication = byMedication.putIfAbsent(
      medicationName,
      () => _MedicationAccumulator(
        medicationName: medicationName,
        lookbackDays: lookbackDays,
      ),
    );

    for (var index = 0; index < windowDays.length; index++) {
      final day = windowDays[index];
      if (day.isBefore(startDate)) {
        continue;
      }
      if (endDate != null && day.isAfter(endDate)) {
        continue;
      }

      final medicationDaily = medication.daily[index];
      final overallDay = overallDaily[index];

      for (final dose in schedule.resolvedDoseSchedule) {
        final scheduledFor = _scheduledFor(day, dose.time);
        if (scheduledFor == null) {
          continue;
        }
        if (_isUpcomingToday(scheduledFor: scheduledFor, now: today)) {
          continue;
        }

        medicationDaily.scheduledDoses++;
        medication.scheduledDoses++;
        overallDay.scheduledDoses++;

        final key = _doseKey(
          scheduleId: schedule.scheduleId,
          scheduledFor: scheduledFor,
        );
        if (!takenKeys.contains(key)) {
          continue;
        }

        medicationDaily.takenDoses++;
        medication.takenDoses++;
        overallDay.takenDoses++;
      }
    }
  }

  final statsList =
      byMedication.values
          .map(
            (medication) => MedicationAdherenceStats(
              medicationName: medication.medicationName,
              scheduledDoses: medication.scheduledDoses,
              takenDoses: medication.takenDoses,
              currentStreak: _currentStreak(medication.daily),
            ),
          )
          .where((stats) => stats.scheduledDoses > 0)
          .toList(growable: false)
        ..sort(
          (left, right) => left.medicationName.compareTo(right.medicationName),
        );

  final totalScheduledDoses = overallDaily.fold<int>(
    0,
    (sum, day) => sum + day.scheduledDoses,
  );
  final totalTakenDoses = overallDaily.fold<int>(
    0,
    (sum, day) => sum + day.takenDoses,
  );
  final dailyBreakdown = List<AdherenceDayStats>.generate(
    lookbackDays,
    (index) => AdherenceDayStats(
      date: windowDays[index],
      scheduledDoses: overallDaily[index].scheduledDoses,
      takenDoses: overallDaily[index].takenDoses,
    ),
    growable: false,
  );

  return AdherenceSummary(
    totalScheduledDoses: totalScheduledDoses,
    totalTakenDoses: totalTakenDoses,
    byMedication: statsList,
    dailyBreakdown: dailyBreakdown,
    lookbackDays: lookbackDays,
  );
}

Set<String> _takenDoseKeys(List<EventEnvelope<DomainEvent>> events) {
  final keys = <String>{};
  for (final envelope in events) {
    final type = envelope.event.type;
    if (type != 'medication_taken' && type != 'medication_taken_corrected') {
      continue;
    }
    final payload = envelope.event.payload;
    final scheduleId = payload['schedule_id'] as String?;
    final scheduledForRaw = payload['scheduled_for'] as String?;
    if (scheduleId == null || scheduledForRaw == null) {
      continue;
    }
    final scheduledFor = DateTime.tryParse(scheduledForRaw);
    if (scheduledFor == null) {
      continue;
    }
    keys.add(_doseKey(scheduleId: scheduleId, scheduledFor: scheduledFor));
  }
  return keys;
}

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

int _currentStreak(List<_DailyAccumulator> daily) {
  var streak = 0;
  for (var index = daily.length - 1; index >= 0; index--) {
    final day = daily[index];
    if (day.scheduledDoses == 0) {
      continue;
    }
    if (day.takenDoses == day.scheduledDoses) {
      streak++;
      continue;
    }
    break;
  }
  return streak;
}

String _doseKey({required String scheduleId, required DateTime scheduledFor}) {
  final normalized = DateTime(
    scheduledFor.year,
    scheduledFor.month,
    scheduledFor.day,
    scheduledFor.hour,
    scheduledFor.minute,
  );
  return '$scheduleId@${normalized.toIso8601String()}';
}

bool _isUpcomingToday({required DateTime scheduledFor, required DateTime now}) {
  return _dateOnly(scheduledFor) == _dateOnly(now) && scheduledFor.isAfter(now);
}

DateTime? _scheduledFor(DateTime day, String time) {
  final parts = time.split(':');
  if (parts.length != 2) {
    return null;
  }
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

class _DailyAccumulator {
  int scheduledDoses = 0;
  int takenDoses = 0;
}

class _MedicationAccumulator {
  _MedicationAccumulator({
    required this.medicationName,
    required int lookbackDays,
  }) : daily = List<_DailyAccumulator>.generate(
         lookbackDays,
         (_) => _DailyAccumulator(),
         growable: false,
       );

  final List<_DailyAccumulator> daily;
  final String medicationName;
  int scheduledDoses = 0;
  int takenDoses = 0;
}
