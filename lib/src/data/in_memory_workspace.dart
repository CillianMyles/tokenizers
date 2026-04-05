import 'dart:async';

import '../core/application/event_store.dart';
import '../core/application/projection_runner.dart';
import '../core/domain/domain_event.dart';
import '../core/domain/event_envelope.dart';
import '../features/calendar/application/medication_repository.dart';
import '../features/calendar/domain/medication_models.dart';
import '../features/chat/application/conversation_repository.dart';
import '../features/chat/domain/conversation_models.dart';
import '../features/proposals/domain/proposal_models.dart';
import 'projection_state.dart';

/// Rebuilds read models from the in-memory event stream.
class InMemoryWorkspace
    implements ConversationRepository, MedicationRepository, ProjectionRunner {
  /// Creates an in-memory workspace.
  InMemoryWorkspace({required EventStore eventStore})
    : _eventStore = eventStore {
    _subscription = _eventStore.watchAll().listen((events) {
      _state = ProjectionState.fromEvents(events);
      _controller.add(_state);
    });
  }

  final EventStore _eventStore;
  late final StreamSubscription<List<EventEnvelope<DomainEvent>>> _subscription;
  final StreamController<ProjectionState> _controller =
      StreamController<ProjectionState>.broadcast();

  ProjectionState _state = const ProjectionState.empty();

  @override
  Future<List<ConversationMessageView>> getMessages(String threadId) async {
    return _state.messagesByThread[threadId] ??
        const <ConversationMessageView>[];
  }

  @override
  Future<ProposalView?> getPendingProposal(String threadId) async {
    return _state.pendingProposalsByThread[threadId];
  }

  @override
  Future<List<MedicationScheduleView>> getActiveSchedules() async {
    return _state.activeSchedules;
  }

  @override
  Future<void> rebuild() async {
    _state = ProjectionState.fromEvents(await _eventStore.loadAll());
    _controller.add(_state);
  }

  /// Releases in-memory subscriptions.
  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }

  @override
  Stream<List<MedicationCalendarEntry>> watchCalendarEntriesForDay(
    DateTime day,
  ) async* {
    yield _state.entriesForDay(day);
    yield* _controller.stream.map((state) => state.entriesForDay(day));
  }

  @override
  Stream<List<MedicationScheduleView>> watchActiveSchedules() async* {
    yield _state.activeSchedules;
    yield* _controller.stream.map((state) => state.activeSchedules);
  }

  @override
  Stream<List<ConversationMessageView>> watchMessages(String threadId) async* {
    yield _state.messagesByThread[threadId] ??
        const <ConversationMessageView>[];
    yield* _controller.stream.map(
      (state) =>
          state.messagesByThread[threadId] ?? const <ConversationMessageView>[],
    );
  }

  @override
  Stream<ProposalView?> watchPendingProposal(String threadId) async* {
    yield _state.pendingProposalsByThread[threadId];
    yield* _controller.stream.map(
      (state) => state.pendingProposalsByThread[threadId],
    );
  }

  @override
  Stream<List<ConversationThreadView>> watchThreads() async* {
    yield _state.threads;
    yield* _controller.stream.map((state) => state.threads);
  }
}
