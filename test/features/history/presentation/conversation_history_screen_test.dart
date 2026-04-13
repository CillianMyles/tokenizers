import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/app/app_scope.dart';
import 'package:tokenizers/src/app/app_theme.dart';
import 'package:tokenizers/src/bootstrap/demo_app_bootstrap.dart';
import 'package:tokenizers/src/core/application/event_store.dart';
import 'package:tokenizers/src/core/application/projection_runner.dart';
import 'package:tokenizers/src/core/domain/domain_event.dart';
import 'package:tokenizers/src/core/domain/event_envelope.dart';
import 'package:tokenizers/src/core/model/model_provider.dart';
import 'package:tokenizers/src/core/model/model_response_contract.dart';
import 'package:tokenizers/src/data/api_key_store.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/history/presentation/conversation_history_screen.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  testWidgets('ConversationHistoryScreen filters timeline items by category', (
    tester,
  ) async {
    final eventStore = _FakeEventStore(
      events: <EventEnvelope<DomainEvent>>[
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-chat',
          eventType: 'message_added',
          occurredAt: DateTime(2026, 4, 9, 9),
          payload: const <String, Object?>{
            'thread_id': 'thread-1',
            'message_id': 'message-1',
            'text': 'Add magnesium tonight.',
          },
        ),
        _event(
          aggregateId: 'thread-1',
          eventId: 'event-assistant',
          eventType: 'model_turn_recorded',
          occurredAt: DateTime(2026, 4, 9, 9, 5),
          payload: const <String, Object?>{
            'assistant_text': 'I can draft that change for you.',
            'message_id': 'message-2',
            'thread_id': 'thread-1',
          },
        ),
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-medication',
          eventType: 'medication_schedule_added',
          occurredAt: DateTime(2026, 4, 9, 9, 10),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Magnesium',
            'dose_amount': '250',
            'dose_unit': 'mg',
            'times': <String>['21:00'],
          },
        ),
        _event(
          aggregateId: 'schedule-1',
          eventId: 'event-adherence',
          eventType: 'medication_taken',
          occurredAt: DateTime(2026, 4, 9, 21, 5),
          payload: const <String, Object?>{
            'schedule_id': 'schedule-1',
            'medication_name': 'Magnesium',
            'scheduled_for': '2026-04-09T21:00:00.000',
            'taken_at': '2026-04-09T21:05:00.000',
          },
        ),
      ],
    );

    await tester.pumpWidget(
      AppScope(
        bootstrap: _buildBootstrap(eventStore: eventStore),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: ConversationHistoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Message sent'), findsOneWidget);
    expect(find.text('Assistant replied'), findsOneWidget);
    expect(find.text('Magnesium added'), findsOneWidget);
    expect(find.text('Medication taken'), findsOneWidget);

    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    expect(find.text('Message sent'), findsOneWidget);
    expect(find.text('Assistant replied'), findsOneWidget);
    expect(find.text('Magnesium added'), findsNothing);
    expect(find.text('Medication taken'), findsNothing);

    await tester.tap(find.text('Medication'));
    await tester.pumpAndSettle();

    expect(find.text('Magnesium added'), findsOneWidget);
    expect(find.text('Message sent'), findsNothing);
    expect(find.text('Assistant replied'), findsNothing);

    await tester.tap(find.text('Adherence'));
    await tester.pumpAndSettle();

    expect(find.text('Medication taken'), findsOneWidget);
    expect(find.text('Magnesium added'), findsNothing);
  });
}

AppBootstrap _buildBootstrap({required EventStore eventStore}) {
  final conversationRepository = _FakeConversationRepository();
  final medicationRepository = _FakeMedicationRepository();
  final modelProvider = _FakeModelProvider();

  return AppBootstrap(
    activityStreamId: 'thread-current',
    aiSettingsController: AiSettingsController(
      repository: const _FakeAiSettingsRepository(),
    ),
    chatCoordinator: ChatCoordinator(
      conversationRepository: conversationRepository,
      eventStore: eventStore,
      medicationRepository: medicationRepository,
      modelProvider: modelProvider,
    ),
    conversationRepository: conversationRepository,
    eventStore: eventStore,
    localDataResetService: const _FakeLocalDataResetService(),
    medicationCommandService: MedicationCommandService(eventStore: eventStore),
    medicationRepository: medicationRepository,
    modelProvider: modelProvider,
    projectionRunner: const _FakeProjectionRunner(),
  );
}

EventEnvelope<DomainEvent> _event({
  required String aggregateId,
  required String eventId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: 'test',
    aggregateId: aggregateId,
    actorType: EventActorType.user,
    correlationId: 'corr-$eventId',
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
  );
}

class _FakeAiSettingsRepository implements AiSettingsRepository {
  const _FakeAiSettingsRepository();

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearGeminiApiKey() async {}

  @override
  Future<AiSettings> load() async => const AiSettings();

  @override
  Future<String?> loadGeminiApiKey() async => null;

  @override
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord() async => null;

  @override
  Future<AiSettings> save(AiSettings settings) async => settings;

  @override
  Future<void> saveGeminiApiKey(String apiKey) async {}
}

class _FakeLocalDataResetService implements LocalDataResetService {
  const _FakeLocalDataResetService();

  @override
  Future<void> deleteAllLocalData() async {}
}

class _FakeMedicationRepository implements MedicationRepository {
  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    return const <MedicationScheduleView>[];
  }

  @override
  Future<List<MedicationScheduleView>> getCurrentAndUpcomingSchedules() async {
    return const <MedicationScheduleView>[];
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules(DateTime day) {
    return Stream<List<MedicationScheduleView>>.value(
      <MedicationScheduleView>[],
    );
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) {
    return Stream<List<MedicationCalendarEntry>>.value(
      <MedicationCalendarEntry>[],
    );
  }
}

class _FakeConversationRepository implements ConversationRepository {
  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    return const <ConversationMessageView>[];
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    return null;
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) {
    return Stream<List<ConversationMessageView>>.value(
      <ConversationMessageView>[],
    );
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) {
    return Stream<ProposalView?>.value(null);
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() {
    return Stream<List<ConversationThreadView>>.value(
      <ConversationThreadView>[],
    );
  }
}

class _FakeEventStore implements EventStore {
  _FakeEventStore({required this.events});

  final List<EventEnvelope<DomainEvent>> events;

  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> newEvents) async {}

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async => events;

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(events);
  }
}

class _FakeModelProvider implements ModelProvider {
  @override
  Future<ModelResponseContract> generateResponse({
    required List<MedicationScheduleView> confirmedSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
    ModelImageAttachment? imageAttachment,
  }) async {
    return const ModelResponseContract(
      actions: <ModelProposalAction>[],
      assistantText: '',
      rawPayload: <String, Object?>{},
    );
  }
}

class _FakeProjectionRunner implements ProjectionRunner {
  const _FakeProjectionRunner();

  @override
  Future<void> rebuild() async {}
}
