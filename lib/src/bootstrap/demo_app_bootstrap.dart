import '../../env/env.dart';
import '../app/app_session.dart';
import '../core/application/event_store.dart';
import '../core/application/projection_runner.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';
import '../core/model/model_provider.dart';
import '../core/model/model_response_contract.dart';
import '../data/app_database.dart';
import '../data/drift_event_store.dart';
import '../data/drift_workspace.dart';
import '../data/gemini_model_provider.dart';
import '../features/calendar/application/medication_repository.dart';
import '../features/chat/application/chat_coordinator.dart';
import '../features/chat/application/conversation_repository.dart';

/// Bundles the app's core services and repositories.
class AppBootstrap {
  /// Creates an app bootstrap.
  const AppBootstrap({
    required this.appSession,
    required this.chatCoordinator,
    required this.configurationError,
    required this.conversationRepository,
    required this.eventStore,
    required this.medicationRepository,
    required this.modelProvider,
    required this.projectionRunner,
  });

  final AppSessionController appSession;
  final ChatCoordinator chatCoordinator;
  final String? configurationError;
  final ConversationRepository conversationRepository;
  final EventStore eventStore;
  final MedicationRepository medicationRepository;
  final ModelProvider modelProvider;
  final ProjectionRunner projectionRunner;
}

/// Creates the application bootstrap used by the v0 shell.
Future<AppBootstrap> createDemoAppBootstrap() async {
  const currentThreadId = 'thread-current';
  final configurationError = _configurationError();
  final modelProvider = _createModelProvider(configurationError);
  final appSession = AppSessionController(initialThreadId: currentThreadId);

  final database = AppDatabase();
  final eventStore = DriftEventStore(database: database);
  final workspace = DriftWorkspace(database: database, eventStore: eventStore);
  await _seedIfNeeded(eventStore);
  await workspace.rebuild();

  return AppBootstrap(
    appSession: appSession,
    chatCoordinator: ChatCoordinator(
      conversationRepository: workspace,
      eventStore: eventStore,
      medicationRepository: workspace,
      modelProvider: modelProvider,
    ),
    configurationError: configurationError,
    conversationRepository: workspace,
    eventStore: eventStore,
    medicationRepository: workspace,
    modelProvider: modelProvider,
    projectionRunner: workspace,
  );
}

String? _configurationError() {
  if (Env.geminiApiKey.isNotEmpty) {
    return null;
  }
  return 'Missing GEMINI_API_KEY in your local .env. Copy .env.example to '
      '.env, add your Gemini key, and relaunch the app.';
}

ModelProvider _createModelProvider(String? configurationError) {
  if (configurationError != null) {
    return _MissingConfigurationModelProvider(message: configurationError);
  }
  return GeminiModelProvider(apiKey: Env.geminiApiKey);
}

Future<void> _seedIfNeeded(EventStore eventStore) async {
  if ((await eventStore.loadAll()).isNotEmpty) {
    return;
  }
  await eventStore.append(_seedEvents());
}

List<EventEnvelope<DomainEvent>> _seedEvents() {
  return <EventEnvelope<DomainEvent>>[
    _event(
      eventId: 'event-thread-baseline',
      aggregateId: 'thread-baseline',
      eventType: 'thread_started',
      occurredAt: DateTime(2026, 4, 2, 7, 40),
      payload: const <String, Object?>{
        'thread_id': 'thread-baseline',
        'title': 'Existing medication plan',
      },
    ),
    _event(
      eventId: 'event-msg-baseline-user',
      aggregateId: 'thread-baseline',
      eventType: 'message_added',
      occurredAt: DateTime(2026, 4, 2, 7, 41),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'thread_id': 'thread-baseline',
        'message_id': 'msg-baseline-user',
        'text': 'I started metformin 500 mg at 8am and 8pm today.',
      },
    ),
    _event(
      eventId: 'event-msg-baseline-model',
      aggregateId: 'thread-baseline',
      eventType: 'model_turn_recorded',
      occurredAt: DateTime(2026, 4, 2, 7, 41, 30),
      actorType: EventActorType.model,
      payload: const <String, Object?>{
        'thread_id': 'thread-baseline',
        'message_id': 'msg-baseline-model',
        'assistant_text':
            'I drafted a metformin schedule for review and you confirmed it.',
        'raw_payload': <String, Object?>{'source': 'seed'},
      },
    ),
    _event(
      eventId: 'event-proposal-baseline',
      aggregateId: 'proposal-baseline',
      eventType: 'proposal_created',
      occurredAt: DateTime(2026, 4, 2, 7, 42),
      actorType: EventActorType.model,
      payload: const <String, Object?>{
        'proposal_id': 'proposal-baseline',
        'thread_id': 'thread-baseline',
        'summary': 'Start metformin 500 mg twice daily.',
        'assistant_text': 'Please confirm the metformin schedule.',
        'actions': <Map<String, Object?>>[
          <String, Object?>{
            'action_id': 'proposal-action-baseline',
            'type': 'add_medication_schedule',
            'medication_name': 'Metformin',
            'dose_amount': '500',
            'dose_unit': 'mg',
            'start_date': '2026-04-02',
            'times': <String>['08:00', '20:00'],
            'notes': 'Taken with meals.',
          },
        ],
      },
    ),
    _event(
      eventId: 'event-proposal-baseline-confirmed',
      aggregateId: 'proposal-baseline',
      eventType: 'proposal_confirmed',
      occurredAt: DateTime(2026, 4, 2, 7, 43),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'proposal_id': 'proposal-baseline',
        'thread_id': 'thread-baseline',
      },
    ),
    _event(
      eventId: 'event-medication-baseline',
      aggregateId: 'medication-metformin',
      eventType: 'medication_registered',
      occurredAt: DateTime(2026, 4, 2, 7, 43, 10),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'medication_id': 'medication-metformin',
        'medication_name': 'Metformin',
      },
    ),
    _event(
      eventId: 'event-schedule-baseline',
      aggregateId: 'schedule-metformin',
      eventType: 'medication_schedule_added',
      occurredAt: DateTime(2026, 4, 2, 7, 43, 10),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'schedule_id': 'schedule-metformin',
        'medication_id': 'medication-metformin',
        'medication_name': 'Metformin',
        'dose_amount': '500',
        'dose_unit': 'mg',
        'start_date': '2026-04-02',
        'times': <String>['08:00', '20:00'],
        'notes': 'Taken with meals.',
        'source_proposal_id': 'proposal-baseline',
      },
    ),
    _event(
      eventId: 'event-thread-current',
      aggregateId: 'thread-current',
      eventType: 'thread_started',
      occurredAt: DateTime(2026, 4, 5, 8, 30),
      payload: const <String, Object?>{
        'thread_id': 'thread-current',
        'title': 'Today’s medication capture',
      },
    ),
    _event(
      eventId: 'event-msg-current-user',
      aggregateId: 'thread-current',
      eventType: 'message_added',
      occurredAt: DateTime(2026, 4, 5, 8, 31),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'thread_id': 'thread-current',
        'message_id': 'msg-current-user',
        'text': 'Add vitamin D 1000 IU at 9am every day.',
      },
    ),
    _event(
      eventId: 'event-msg-current-model',
      aggregateId: 'thread-current',
      eventType: 'model_turn_recorded',
      occurredAt: DateTime(2026, 4, 5, 8, 31, 30),
      actorType: EventActorType.model,
      payload: const <String, Object?>{
        'thread_id': 'thread-current',
        'message_id': 'msg-current-model',
        'assistant_text':
            'I created a pending vitamin D proposal. Review it before it changes your schedule.',
        'raw_payload': <String, Object?>{'source': 'seed'},
      },
    ),
    _event(
      eventId: 'event-proposal-current',
      aggregateId: 'proposal-current',
      eventType: 'proposal_created',
      occurredAt: DateTime(2026, 4, 5, 8, 32),
      actorType: EventActorType.model,
      payload: const <String, Object?>{
        'proposal_id': 'proposal-current',
        'thread_id': 'thread-current',
        'summary': 'Add vitamin D 1000 IU every day at 9am.',
        'assistant_text':
            'This is still pending. Nothing will change until you confirm it.',
        'actions': <Map<String, Object?>>[
          <String, Object?>{
            'action_id': 'proposal-action-current',
            'type': 'add_medication_schedule',
            'medication_name': 'Vitamin D',
            'dose_amount': '1000',
            'dose_unit': 'IU',
            'start_date': '2026-04-05',
            'times': <String>['09:00'],
            'notes': 'Morning supplement.',
          },
        ],
      },
    ),
    _event(
      eventId: 'event-thread-history',
      aggregateId: 'thread-history',
      eventType: 'thread_started',
      occurredAt: DateTime(2026, 4, 4, 17, 10),
      payload: const <String, Object?>{
        'thread_id': 'thread-history',
        'title': 'Travel refill questions',
      },
    ),
    _event(
      eventId: 'event-msg-history-user',
      aggregateId: 'thread-history',
      eventType: 'message_added',
      occurredAt: DateTime(2026, 4, 4, 17, 12),
      actorType: EventActorType.user,
      payload: const <String, Object?>{
        'thread_id': 'thread-history',
        'message_id': 'msg-history-user',
        'text': 'I am traveling next week. Remind me what is active.',
      },
    ),
    _event(
      eventId: 'event-msg-history-model',
      aggregateId: 'thread-history',
      eventType: 'model_turn_recorded',
      occurredAt: DateTime(2026, 4, 4, 17, 12, 30),
      actorType: EventActorType.model,
      payload: const <String, Object?>{
        'thread_id': 'thread-history',
        'message_id': 'msg-history-model',
        'assistant_text':
            'Your confirmed schedule currently includes metformin only.',
        'raw_payload': <String, Object?>{'source': 'seed'},
      },
    ),
  ];
}

final class _MissingConfigurationModelProvider implements ModelProvider {
  const _MissingConfigurationModelProvider({required this.message});

  final String message;

  @override
  Future<ModelResponseContract> generateResponse({
    required List activeSchedules,
    required List conversation,
    required String threadId,
    required String userText,
  }) {
    throw StateError(message);
  }
}

EventEnvelope<DomainEvent> _event({
  required String eventId,
  required String aggregateId,
  required String eventType,
  required DateTime occurredAt,
  required Map<String, Object?> payload,
  EventActorType actorType = EventActorType.system,
}) {
  return EventEnvelope<DomainEvent>(
    eventId: eventId,
    aggregateType: eventType.startsWith('medication_')
        ? 'medication'
        : eventType.startsWith('proposal_')
        ? 'proposal'
        : 'conversation',
    aggregateId: aggregateId,
    event: DomainEvent(type: eventType, payload: payload),
    occurredAt: occurredAt,
    actorType: actorType,
  );
}
