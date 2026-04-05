import '../core/model/model_provider.dart';
import '../core/model/model_response_contract.dart';
import '../features/calendar/domain/medication_models.dart';
import '../features/chat/domain/conversation_models.dart';

/// A deterministic stand-in for the eventual Gemini model provider.
class DemoModelProvider implements ModelProvider {
  /// Creates a demo model provider.
  DemoModelProvider({required this.referenceDate});

  final DateTime referenceDate;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
  }) async {
    final normalized = userText.toLowerCase();
    final matchedSchedule = _findMatchingSchedule(activeSchedules, normalized);

    if (normalized.contains('stop') && matchedSchedule != null) {
      final medicationName = matchedSchedule.medicationName;
      return ModelResponseContract(
        assistantText:
            'I created a stop proposal for $medicationName. Review it before it changes your schedule.',
        rawPayload: <String, Object?>{
          'provider': 'demo',
          'kind': 'stop_medication_schedule',
        },
        actions: <ModelProposalAction>[
          ModelProposalAction(
            actionId: _id('action'),
            type: ModelProposalActionType.stopMedicationSchedule,
            medicationName: medicationName,
            notes: 'Stop the current active schedule.',
            startDate: referenceDate,
            targetScheduleId: matchedSchedule.scheduleId,
          ),
        ],
      );
    }

    final medicationName = _extractMedicationName(normalized, activeSchedules);
    final doseMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(mg|ml|iu|tablet|tablets|capsule|capsules)',
    ).firstMatch(normalized);
    final times = RegExp(
      r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)',
    ).allMatches(normalized).map(_normalizeTime).toList();

    final missingFields = <String>[
      if (medicationName == null) 'medicine name',
      if (doseMatch == null) 'dose',
      if (times.isEmpty) 'time',
    ];

    if (missingFields.isNotEmpty) {
      return ModelResponseContract(
        assistantText:
            'I need a little more detail before I can draft a safe medication proposal.',
        rawPayload: <String, Object?>{
          'provider': 'demo',
          'kind': 'request_missing_info',
          'missing_fields': missingFields,
        },
        actions: <ModelProposalAction>[
          ModelProposalAction(
            actionId: _id('action'),
            type: ModelProposalActionType.requestMissingInfo,
            medicationName: medicationName,
            missingFields: missingFields,
          ),
        ],
      );
    }

    final startDate = normalized.contains('tomorrow')
        ? referenceDate.add(const Duration(days: 1))
        : referenceDate;
    final doseAmount = doseMatch!.group(1)!;
    final doseUnit = doseMatch.group(2)!.toUpperCase() == 'IU'
        ? 'IU'
        : doseMatch.group(2)!.toLowerCase();

    return ModelResponseContract(
      assistantText:
          'I drafted a pending $medicationName schedule. Confirm it before it appears on the calendar.',
      rawPayload: <String, Object?>{
        'provider': 'demo',
        'kind': 'add_medication_schedule',
      },
      actions: <ModelProposalAction>[
        ModelProposalAction(
          actionId: _id('action'),
          type: ModelProposalActionType.addMedicationSchedule,
          doseAmount: doseAmount,
          doseUnit: doseUnit,
          medicationName: medicationName,
          notes: normalized.contains('with food') ? 'Take with food.' : null,
          startDate: DateTime(startDate.year, startDate.month, startDate.day),
          times: times,
        ),
      ],
    );
  }

  String? _extractMedicationName(
    String normalized,
    List<MedicationScheduleView> activeSchedules,
  ) {
    const builtInNames = <String>[
      'amoxicillin',
      'ibuprofen',
      'metformin',
      'vitamin d',
      'vitamin b12',
    ];

    for (final schedule in activeSchedules) {
      final lower = schedule.medicationName.toLowerCase();
      if (normalized.contains(lower)) {
        return schedule.medicationName;
      }
    }

    for (final name in builtInNames) {
      if (normalized.contains(name)) {
        return name
            .split(' ')
            .map((part) => part[0].toUpperCase() + part.substring(1))
            .join(' ');
      }
    }
    return null;
  }

  MedicationScheduleView? _findMatchingSchedule(
    List<MedicationScheduleView> activeSchedules,
    String normalized,
  ) {
    for (final schedule in activeSchedules) {
      if (normalized.contains(schedule.medicationName.toLowerCase())) {
        return schedule;
      }
    }
    return null;
  }

  String _id(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  String _normalizeTime(RegExpMatch match) {
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final meridiem = match.group(3)!;

    if (meridiem == 'pm' && hour != 12) {
      hour += 12;
    }
    if (meridiem == 'am' && hour == 12) {
      hour = 0;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }
}
