/// Rebuilds read models from the event log.
abstract interface class ProjectionRunner {
  /// Replays the current event stream into projections.
  Future<void> rebuild();
}
