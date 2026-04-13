import 'dart:convert';

import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';

/// Builds the app-owned user prompt for medication proposal extraction.
String buildMedicationAssistantPrompt({
  required List<MedicationScheduleView> confirmedSchedules,
  required List<ConversationMessageView> conversation,
  required String threadId,
  required String userText,
  ModelImageAttachment? imageAttachment,
}) {
  final recentMessages = conversation
      .take(conversation.length > 8 ? 8 : conversation.length)
      .map((message) {
        return <String, Object?>{
          'actor': message.actor.name,
          'text': message.text,
          'created_at': message.createdAt.toIso8601String(),
        };
      })
      .toList(growable: false);

  final schedules = confirmedSchedules
      .map((schedule) {
        return <String, Object?>{
          'schedule_id': schedule.scheduleId,
          'medication_name': schedule.medicationName,
          'dose_amount': schedule.doseAmount,
          'dose_unit': schedule.doseUnit,
          'route': schedule.route,
          'start_date': schedule.startDate.toIso8601String().split('T').first,
          'end_date': schedule.endDate?.toIso8601String().split('T').first,
          'dose_schedule': medicationDoseScheduleToJsonList(
            schedule.resolvedDoseSchedule,
          ),
          'times': schedule.times,
          'notes': schedule.notes,
        };
      })
      .toList(growable: false);

  return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'thread_id': threadId,
    'input_mode': imageAttachment == null ? 'text' : 'text_and_image',
    'latest_user_text': userText,
    'image_attached': imageAttachment != null,
    'image_mime_type': imageAttachment?.mimeType,
    'conversation_history': recentMessages,
    'confirmed_schedules': schedules,
  });
}

/// Shared instruction for structured proposal generation.
const medicationAssistantSystemPrompt = '''
You are extracting medication management proposals for a patient-side tracking app.
Return JSON only and follow the provided schema exactly.
Never mutate current schedules directly. Always propose actions for explicit user review.
If the message is ambiguous or missing required information, use request_missing_info instead of guessing.
When an image is attached, treat it as a prescription or medication instruction photo that may contain the primary evidence.
Times must use 24-hour HH:mm format.
Dates must use YYYY-MM-DD format.
If doses differ by time, represent them in dose_schedule.
''';

/// Shared response schema used by all providers.
final medicationAssistantResponseSchema = <String, Object?>{
  'type': 'object',
  'propertyOrdering': <String>['assistant_text', 'actions'],
  'required': <String>['assistant_text', 'actions'],
  'properties': <String, Object?>{
    'assistant_text': <String, Object?>{
      'type': 'string',
      'description':
          'Short conversational text explaining what was extracted or what is missing.',
    },
    'actions': <String, Object?>{
      'type': 'array',
      'description': 'Structured medication proposals for later user review.',
      'items': <String, Object?>{
        'type': 'object',
        'propertyOrdering': <String>[
          'type',
          'medication_name',
          'dose_amount',
          'dose_unit',
          'route',
          'times',
          'dose_schedule',
          'start_date',
          'end_date',
          'target_schedule_id',
          'notes',
          'missing_fields',
        ],
        'required': <String>['type'],
        'properties': <String, Object?>{
          'type': <String, Object?>{
            'type': 'string',
            'enum': <String>[
              'add_medication_schedule',
              'update_medication_schedule',
              'stop_medication_schedule',
              'request_missing_info',
            ],
          },
          'medication_name': <String, Object?>{'type': 'string'},
          'dose_amount': <String, Object?>{'type': 'string'},
          'dose_unit': <String, Object?>{'type': 'string'},
          'route': <String, Object?>{'type': 'string'},
          'times': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
          'dose_schedule': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{
              'type': 'object',
              'required': <String>['time', 'dose_amount', 'dose_unit'],
              'properties': <String, Object?>{
                'time': <String, Object?>{'type': 'string'},
                'dose_amount': <String, Object?>{'type': 'string'},
                'dose_unit': <String, Object?>{'type': 'string'},
              },
            },
          },
          'start_date': <String, Object?>{'type': 'string'},
          'end_date': <String, Object?>{'type': 'string'},
          'target_schedule_id': <String, Object?>{'type': 'string'},
          'notes': <String, Object?>{'type': 'string'},
          'missing_fields': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
        },
      },
    },
  },
};

/// Decodes a JSON object string into a typed map.
Map<String, Object?> decodeJsonObject(String source) {
  return (jsonDecode(source) as Map).cast<String, Object?>();
}

/// Parses the app-owned structured response into a domain contract.
ModelResponseContract parseMedicationAssistantResponse({
  required Map<String, Object?> structured,
  required Map<String, Object?> rawPayload,
  required String rawPayloadKey,
}) {
  final parser = _MedicationAssistantResponseParser();
  final actions =
      ((structured['actions'] ?? const <Object?>[]) as List<Object?>)
          .whereType<Map<String, Object?>>()
          .map(parser.parseAction)
          .toList(growable: false);

  return ModelResponseContract(
    actions: actions,
    assistantText:
        (structured['assistant_text'] as String?) ??
        'I could not draft a proposal from that message.',
    rawPayload: <String, Object?>{
      rawPayloadKey: rawPayload,
      'structured_response': structured,
    },
  );
}

class _MedicationAssistantResponseParser {
  int _actionCounter = 0;

  ModelProposalAction parseAction(Map<String, Object?> json) {
    final type = switch (json['type']) {
      'add_medication_schedule' =>
        ModelProposalActionType.addMedicationSchedule,
      'update_medication_schedule' =>
        ModelProposalActionType.updateMedicationSchedule,
      'stop_medication_schedule' =>
        ModelProposalActionType.stopMedicationSchedule,
      _ => ModelProposalActionType.requestMissingInfo,
    };

    return ModelProposalAction(
      actionId:
          'action-${DateTime.now().microsecondsSinceEpoch}-${_actionCounter++}',
      doseAmount: json['dose_amount'] as String?,
      doseSchedule: medicationDoseScheduleFromJsonList(
        json['dose_schedule'],
        fallbackDoseAmount: json['dose_amount'] as String?,
        fallbackDoseUnit: json['dose_unit'] as String?,
        fallbackTimes: ((json['times'] ?? const <Object?>[]) as List<Object?>)
            .whereType<String>()
            .toList(),
      ),
      doseUnit: json['dose_unit'] as String?,
      endDate: _tryParseDate(json['end_date'] as String?),
      medicationName: json['medication_name'] as String?,
      missingFields:
          ((json['missing_fields'] ?? const <Object?>[]) as List<Object?>)
              .whereType<String>()
              .toList(),
      notes: json['notes'] as String?,
      route: json['route'] as String?,
      startDate: _tryParseDate(json['start_date'] as String?),
      targetScheduleId: json['target_schedule_id'] as String?,
      times: ((json['times'] ?? const <Object?>[]) as List<Object?>)
          .whereType<String>()
          .toList(),
      type: type,
    );
  }

  DateTime? _tryParseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}
