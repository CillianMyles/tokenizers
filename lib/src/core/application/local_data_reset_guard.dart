/// Lets long-running workflows drop stale local writes after a data reset.
abstract interface class LocalDataResetGuard {
  /// Invalidates any pending local writes started before the reset.
  void beginLocalDataReset();
}
