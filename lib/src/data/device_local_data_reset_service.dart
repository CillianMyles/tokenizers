import 'package:tokenizers/src/core/application/local_data_reset_guard.dart';
import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';

/// Clears app-managed local storage on the current device.
class DeviceLocalDataResetService implements LocalDataResetService {
  /// Creates a local data reset service.
  const DeviceLocalDataResetService({
    required AppDatabase database,
    required LocalDataResetGuard resetGuard,
    required AiSettingsRepository settingsRepository,
  }) : _database = database,
       _resetGuard = resetGuard,
       _settingsRepository = settingsRepository;

  final AppDatabase _database;
  final LocalDataResetGuard _resetGuard;
  final AiSettingsRepository _settingsRepository;

  @override
  Future<void> deleteAllLocalData() async {
    _resetGuard.beginLocalDataReset();
    await _database.clearAllData();
    await _settingsRepository.clearAll();
  }
}
