import 'package:tokenizers/src/data/app_database.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/application/local_data_reset_service.dart';

/// Clears app-managed local storage on the current device.
class DeviceLocalDataResetService implements LocalDataResetService {
  /// Creates a local data reset service.
  const DeviceLocalDataResetService({
    required AppDatabase database,
    required AiSettingsRepository settingsRepository,
  }) : _database = database,
       _settingsRepository = settingsRepository;

  final AppDatabase _database;
  final AiSettingsRepository _settingsRepository;

  @override
  Future<void> deleteAllLocalData() async {
    await _database.clearAllData();
    await _settingsRepository.clearAll();
  }
}
