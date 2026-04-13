import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:tokenizers/src/core/domain/medication_dose_schedule.dart';
import 'package:tokenizers/src/core/domain/medication_schedule_preferences.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_schedule_time_inference.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';

const _defaultModel = 'gemini-2.5-flash';

/// Gemini-backed implementation of the app-owned model contract.
class GeminiModelProvider implements ModelProvider {
  /// Creates a Gemini model provider.
  GeminiModelProvider({
    required this.apiKey,
    this.model = _defaultModel,
    this.schedulePreferences = const MedicationSchedulePreferences(),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final MedicationSchedulePreferences schedulePreferences;
  final http.Client _client;
  int _actionCounter = 0;

  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    final contentParts = <Map<String, Object?>>[
      <String, Object?>{
        'text': _buildUserPrompt(
          confirmedSchedules: confirmedSchedules,
          conversation: conversation,
          threadId: threadId,
          userText: userText,
          imageAttachment: imageAttachment,
        ),
      },
    ];
    if (imageAttachment != null) {
      contentParts.add(<String, Object?>{
        'inline_data': <String, Object?>{
          'mime_type': imageAttachment.mimeType,
          'data': base64Encode(imageAttachment.bytes),
        },
      });
    }

    final requestPayload = <String, Object?>{
      'system_instruction': <String, Object?>{
        'parts': <Map<String, String>>[
          <String, String>{'text': _systemPrompt},
        ],
      },
      'contents': <Map<String, Object?>>[
        <String, Object?>{'role': 'user', 'parts': contentParts},
      ],
      'generationConfig': <String, Object?>{
        'temperature': 0.2,
        'responseMimeType': 'application/json',
        'responseJsonSchema': _responseSchema,
      },
    };

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$model:generateContent',
    );

    final response = await _client.post(
      uri,
      headers: <String, String>{
        'x-goog-api-key': apiKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Gemini API request failed (${response.statusCode}): ${response.body}',
      );
    }

    final apiPayload = decodeJsonObject(response.body);
    final text = _extractCandidateText(apiPayload);
    final structured = decodeJsonObject(text);
    return _parseStructuredResponse(
      structured,
      apiPayload,
      activeSchedules: confirmedSchedules,
      userText: userText,
    );
  }

  /// Decodes a JSON object string into a typed map.
  static Map<String, Object?> decodeJsonObject(String source) {
    return (jsonDecode(source) as Map).cast<String, Object?>();
  }

  String _buildUserPrompt({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    required ModelImageAttachment? imageAttachment,
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
            'times': schedule.resolvedTimes,
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
      'medication_schedule_preferences': <String, String>{
        'morning': schedulePreferences.morningTime,
        'lunch': schedulePreferences.lunchTime,
        'evening': schedulePreferences.eveningTime,
      },
      'conversation_history': recentMessages,
      'confirmed_schedules': schedules,
    });
  }

  String _extractCandidateText(Map<String, Object?> payload) {
    final candidates =
        (payload['candidates'] as List<Object?>?) ?? const <Object?>[];
    if (candidates.isEmpty) {
      throw Exception('Gemini API returned no candidates.');
    }

    final firstCandidate = candidates.first! as Map<String, Object?>;
    final content = firstCandidate['content']! as Map<String, Object?>;
    final parts = (content['parts'] as List<Object?>?) ?? const <Object?>[];
    final text = parts
        .whereType<Map<String, Object?>>()
        .map((part) => (part['text'] as String?) ?? '')
        .join('\n')
        .trim();

    if (text.isEmpty) {
      throw Exception('Gemini API returned an empty structured response.');
    }
    return text;
  }

  ModelResponseContract _parseStructuredResponse(
    Map<String, Object?> structured,
    Map<String, Object?> apiPayload, {
    required List<MedicationScheduleView> activeSchedules,
    required String userText,
  }) {
    final actions =
        ((structured['actions'] ?? const <Object?>[]) as List<Object?>)
            .whereType<Map<String, Object?>>()
            .map(_parseAction)
            .map(
              (action) => applyMedicationTimeFallback(
                action: action,
                activeSchedules: activeSchedules,
                preferences: schedulePreferences,
                userText: userText,
              ),
            )
            .toList(growable: false);

    return ModelResponseContract(
      actions: actions,
      assistantText:
          (structured['assistant_text'] as String?) ??
          'I could not draft a proposal from that message.',
      rawPayload: <String, Object?>{
        'gemini_response': apiPayload,
        'structured_response': structured,
      },
    );
  }

  ModelProposalAction _parseAction(Map<String, Object?> json) {
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

const _systemPrompt = '''
You are extracting medication management proposals for a patient-side tracking app.
Return JSON only and follow the provided schema exactly.
Never mutate current schedules directly. Always propose actions for explicit user review.
If required details other than timing are missing, use request_missing_info instead of guessing.
If the user gives a medication and dose but not an exact time, make a reasonable schedule guess instead of asking for time-only clarification.
When an image is attached, treat it as a prescription or medication instruction photo that may contain the primary evidence.
Times must use 24-hour HH:mm format.
Dates must use YYYY-MM-DD format.
If doses differ by time, represent them in dose_schedule.
Prefer aligning new medication times with existing active schedule times to support adherence.
If no existing schedule time is a good fit, use the provided morning/lunch/evening preferences.
For twice-daily schedules, prefer morning plus evening.
For three-times-daily schedules, prefer morning plus lunch plus evening.
''';

final _responseSchema = <String, Object?>{
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
          'start_date',
          'end_date',
          'dose_schedule',
          'times',
          'notes',
          'target_schedule_id',
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
          'medication_name': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'dose_amount': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'dose_unit': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'route': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'start_date': <String, Object?>{
            'type': <String>['string', 'null'],
            'format': 'date',
          },
          'end_date': <String, Object?>{
            'type': <String>['string', 'null'],
            'format': 'date',
          },
          'dose_schedule': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{
              'type': 'object',
              'required': <String>['time'],
              'properties': <String, Object?>{
                'time': <String, Object?>{'type': 'string', 'format': 'time'},
                'dose_amount': <String, Object?>{
                  'type': <String>['string', 'null'],
                },
                'dose_unit': <String, Object?>{
                  'type': <String>['string', 'null'],
                },
              },
            },
          },
          'times': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string', 'format': 'time'},
          },
          'notes': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'target_schedule_id': <String, Object?>{
            'type': <String>['string', 'null'],
          },
          'missing_fields': <String, Object?>{
            'type': 'array',
            'items': <String, Object?>{'type': 'string'},
          },
        },
      },
    },
  },
};
