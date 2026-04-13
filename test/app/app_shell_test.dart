import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/app/tokenizers_app.dart';
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
import 'package:tokenizers/src/features/proposals/domain/proposal_models.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_controller.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

void main() {
  testWidgets('AppShell uses bottom navigation on narrow layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      TokenizersApp(bootstrap: _buildBootstrap(_FakeMedicationRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
  });

  testWidgets('AppShell uses a desktop rail on wide layouts', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      TokenizersApp(bootstrap: _buildBootstrap(_FakeMedicationRepository())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Bring Your Own AI'), findsOneWidget);
  });

  testWidgets('configuration banner only appears on the assistant tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      TokenizersApp(bootstrap: _buildBootstrap(_FakeMedicationRepository())),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Add a Gemini API key in Settings to use the assistant.'),
      findsNothing,
    );

    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    expect(
      find.text('Add a Gemini API key in Settings to use the assistant.'),
      findsOneWidget,
    );
  });

  testWidgets('configuration banner opens settings from the assistant tab', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(700, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      TokenizersApp(bootstrap: _buildBootstrap(_FakeMedicationRepository())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Assistant'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Open Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Bring Your Own AI'), findsOneWidget);
    expect(
      find.text('Add a Gemini API key in Settings to use the assistant.'),
      findsNothing,
    );
  });
}

AppBootstrap _buildBootstrap(_FakeMedicationRepository medicationRepository) {
  final eventStore = _FakeEventStore();
  final conversationRepository = _FakeConversationRepository();
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
  Stream<List<MedicationScheduleView>> watchActiveSchedules() {
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
    required List<MedicationScheduleView> activeSchedules,
    required List<ConversationMessageView> conversation,
    required String threadId,
    required String userText,
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
