import 'dart:async';

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
import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';
import 'package:tokenizers/src/features/assistant/presentation/assistant_screen.dart';
import 'package:tokenizers/src/features/calendar/application/medication_command_service.dart';
import 'package:tokenizers/src/features/calendar/application/medication_repository.dart';
import 'package:tokenizers/src/features/calendar/domain/medication_models.dart';
import 'package:tokenizers/src/features/chat/application/chat_coordinator.dart';
import 'package:tokenizers/src/features/chat/application/conversation_repository.dart';
import 'package:tokenizers/src/features/chat/domain/conversation_models.dart';
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  testWidgets('AssistantScreen inserts a local transcript into the composer', (
    tester,
  ) async {
    final settingsController = AiSettingsController(
      repository: const _ConfiguredAiSettingsRepository(),
    );
    await settingsController.load();

    final speechToTextService = _FakeSpeechToTextService(
      prepareResult: const SpeechAvailability.available(localeId: 'en-US'),
      transcript: 'Add vitamin D 1000 IU at 9am',
    );

    await tester.pumpWidget(
      AppScope(
        bootstrap: _buildBootstrap(
          settingsController: settingsController,
          speechToTextService: speechToTextService,
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AssistantScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('More input options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Record audio'));
    await tester.pumpAndSettle();

    expect(find.text('Add vitamin D 1000 IU at 9am'), findsOneWidget);

    await tester.tap(find.text('Insert transcript'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(TextField),
        matching: find.text('Add vitamin D 1000 IU at 9am'),
      ),
      findsOneWidget,
    );
  });
}

AppBootstrap _buildBootstrap({
  required AiSettingsController settingsController,
  required SpeechToTextService speechToTextService,
}) {
  final eventStore = _FakeEventStore();
  final conversationRepository = _FakeConversationRepository();
  final medicationRepository = _FakeMedicationRepository();
  final modelProvider = _FakeModelProvider();

  return AppBootstrap(
    activityStreamId: 'thread-current',
    aiSettingsController: settingsController,
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
    speechToTextService: speechToTextService,
  );
}

class _ConfiguredAiSettingsRepository implements AiSettingsRepository {
  const _ConfiguredAiSettingsRepository();

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearGeminiApiKey() async {}

  @override
  Future<AiSettings> load() async {
    return const AiSettings(apiKeySource: ApiKeySource.stored);
  }

  @override
  Future<String?> loadGeminiApiKey() async => 'key';

  @override
  Future<ApiKeyRecord?> loadGeminiApiKeyRecord() async {
    return const ApiKeyRecord(source: ApiKeySource.stored, value: 'key');
  }

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
  @override
  Future<void> append(Iterable<EventEnvelope<DomainEvent>> events) async {}

  @override
  Future<List<EventEnvelope<DomainEvent>>> loadAll() async {
    return const <EventEnvelope<DomainEvent>>[];
  }

  @override
  Stream<List<EventEnvelope<DomainEvent>>> watchAll() {
    return Stream<List<EventEnvelope<DomainEvent>>>.value(
      <EventEnvelope<DomainEvent>>[],
    );
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

class _FakeSpeechToTextService implements SpeechToTextService {
  _FakeSpeechToTextService({
    required this.prepareResult,
    required this.transcript,
  });

  final SpeechAvailability prepareResult;
  final String transcript;
  final StreamController<SpeechToTextEvent> _eventsController =
      StreamController<SpeechToTextEvent>.broadcast();

  @override
  Stream<SpeechToTextEvent> get events => _eventsController.stream;

  @override
  Future<void> cancelListening() async {}

  @override
  void dispose() {
    unawaited(_eventsController.close());
  }

  @override
  Future<SpeechAvailability> prepare({required List<String> localeIds}) async {
    return prepareResult;
  }

  @override
  Future<void> startListening({required String localeId}) async {
    _eventsController.add(
      const SpeechToTextStatusEvent(SpeechToTextStatus.listening),
    );
    _eventsController.add(
      SpeechToTextTranscriptEvent(isFinal: true, text: transcript),
    );
    _eventsController.add(
      const SpeechToTextStatusEvent(SpeechToTextStatus.idle),
    );
  }

  @override
  Future<void> stopListening() async {
    _eventsController.add(
      const SpeechToTextStatusEvent(SpeechToTextStatus.processing),
    );
    _eventsController.add(
      SpeechToTextTranscriptEvent(isFinal: true, text: transcript),
    );
    _eventsController.add(
      const SpeechToTextStatusEvent(SpeechToTextStatus.idle),
    );
  }
}
