/// Deletes all app-managed data stored on the current device.
abstract interface class LocalDataResetService {
  /// Removes persisted local data such as event history and saved settings.
  Future<void> deleteAllLocalData();
}
