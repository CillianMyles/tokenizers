import 'package:flutter/foundation.dart';

import 'package:tokenizers/src/data/local_gemma_service.dart';
import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Coordinates AI settings persistence and exposes live configuration state.
class AiSettingsController extends ChangeNotifier {
  /// Creates an AI settings controller.
  AiSettingsController({
    LocalGemmaService? localGemmaService,
    required AiSettingsRepository repository,
  }) : _localGemmaService = localGemmaService,
       _repository = repository;

  final LocalGemmaService? _localGemmaService;
  final AiSettingsRepository _repository;
  AiSettings _settings = const AiSettings();
  Set<LocalGemmaModel> _installedLocalModels = const <LocalGemmaModel>{};
  String? _geminiApiKey;
  bool _isLoaded = false;
  bool _isDownloadingLocalModel = false;
  bool _isRemovingLocalModel = false;
  String? _localGemmaError;
  int? _localModelDownloadProgress;
  bool _isSavingApiKey = false;
  bool _isSavingModel = false;
  String? _errorMessage;

  /// The current AI settings snapshot.
  AiSettings get settings => _settings;

  /// Whether settings have been loaded from storage.
  bool get isLoaded => _isLoaded;

  /// Whether a settings write is currently in progress.
  bool get isSavingApiKey => _isSavingApiKey;

  /// Whether the model selection is currently being persisted.
  bool get isSavingModel => _isSavingModel;

  /// The loaded Gemini API key, if present.
  String? get geminiApiKey => _geminiApiKey;

  /// The latest load or save failure shown to the UI.
  String? get errorMessage => _errorMessage;

  /// Whether the selected local model is being downloaded.
  bool get isDownloadingLocalModel => _isDownloadingLocalModel;

  /// Whether the selected local model is being removed.
  bool get isRemovingLocalModel => _isRemovingLocalModel;

  /// Progress for the active local-model download.
  int? get localModelDownloadProgress => _localModelDownloadProgress;

  /// Platform or runtime error for the on-device Gemma workflow.
  String? get localGemmaError => _localGemmaError;

  /// Installed Gemma presets available on this device.
  Set<LocalGemmaModel> get installedLocalModels =>
      Set<LocalGemmaModel>.unmodifiable(_installedLocalModels);

  /// Explains why the assistant is unavailable.
  String? get configurationError {
    if (_settings.provider == AiProvider.gemini) {
      return _settings.configurationError;
    }
    if (_localGemmaError != null) {
      return _localGemmaError;
    }
    if (!_installedLocalModels.contains(_settings.localModel)) {
      return 'Download ${_settings.localModel.label} in Settings to use the '
          'offline assistant.';
    }
    return null;
  }

  /// Loads the initial settings and cached Gemini key.
  Future<void> load() async {
    _errorMessage = null;
    notifyListeners();

    try {
      final settings = await _repository.load();
      final apiKeyRecord = await _repository.loadGeminiApiKeyRecord();
      _settings = settings.copyWith(
        apiKeySource: apiKeyRecord?.source ?? ApiKeySource.none,
      );
      _geminiApiKey = apiKeyRecord?.value;
      await _refreshLocalGemmaStatus();
      _isLoaded = true;
    } catch (error) {
      _errorMessage = 'Could not load AI settings. ${error.toString()}';
    }

    notifyListeners();
  }

  /// Persists the selected Gemini model and an optional replacement key.
  Future<void> saveGeminiSettings({
    required GeminiModel geminiModel,
    String replacementApiKey = '',
  }) async {
    await saveGeminiModel(geminiModel);
    final trimmedApiKey = replacementApiKey.trim();
    if (trimmedApiKey.isEmpty) {
      return;
    }
    await saveGeminiApiKey(trimmedApiKey);
  }

  /// Persists the selected Gemini model.
  Future<void> saveGeminiModel(GeminiModel geminiModel) async {
    await _saveModel(() async {
      _settings = await _repository.save(
        _settings.copyWith(geminiModel: geminiModel),
      );
    });
  }

  /// Persists the Gemini API key without changing the selected model.
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _saveApiKey(() async {
      await _repository.saveGeminiApiKey(apiKey);
      _geminiApiKey = apiKey;
      _settings = _settings.copyWith(apiKeySource: ApiKeySource.stored);
    });
  }

  /// Persists the selected AI provider.
  Future<void> saveProvider(AiProvider provider) async {
    await _saveModel(() async {
      _settings = await _repository.save(
        _settings.copyWith(provider: provider),
      );
    });
  }

  /// Persists the selected local Gemma model.
  Future<void> saveLocalGemmaModel(LocalGemmaModel localModel) async {
    await _saveModel(() async {
      _settings = await _repository.save(
        _settings.copyWith(localModel: localModel),
      );
    });
  }

  /// Clears the stored Gemini API key.
  Future<void> clearGeminiApiKey() async {
    await _saveApiKey(() async {
      await _repository.clearGeminiApiKey();
      final apiKeyRecord = await _repository.loadGeminiApiKeyRecord();
      _geminiApiKey = apiKeyRecord?.value;
      _settings = _settings.copyWith(
        apiKeySource: apiKeyRecord?.source ?? ApiKeySource.none,
      );
    });
  }

  /// Refreshes the current local Gemma status without mutating saved settings.
  Future<void> refreshLocalGemmaStatus() async {
    _errorMessage = null;
    notifyListeners();
    await _refreshLocalGemmaStatus();
    notifyListeners();
  }

  /// Downloads the selected local Gemma model from Hugging Face.
  Future<void> downloadLocalGemmaModel([LocalGemmaModel? localModel]) async {
    final service = _localGemmaService;
    if (service == null) {
      _errorMessage = 'Offline Gemma is unavailable in this build.';
      notifyListeners();
      return;
    }

    _isDownloadingLocalModel = true;
    _errorMessage = null;
    _localModelDownloadProgress = 0;
    notifyListeners();

    try {
      final status = await service.downloadModel(
        localModel ?? _settings.localModel,
        onProgress: (progress) {
          _localModelDownloadProgress = progress;
          notifyListeners();
        },
      );
      _applyLocalGemmaStatus(status);
    } catch (error) {
      _errorMessage = 'Could not download the local model. ${error.toString()}';
    } finally {
      _isDownloadingLocalModel = false;
      _localModelDownloadProgress = null;
      notifyListeners();
    }
  }

  /// Deletes the selected local Gemma model from this device.
  Future<void> deleteLocalGemmaModel([LocalGemmaModel? localModel]) async {
    final service = _localGemmaService;
    if (service == null) {
      _errorMessage = 'Offline Gemma is unavailable in this build.';
      notifyListeners();
      return;
    }

    _isRemovingLocalModel = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final status = await service.deleteModel(
        localModel ?? _settings.localModel,
      );
      _applyLocalGemmaStatus(status);
    } catch (error) {
      _errorMessage = 'Could not remove the local model. ${error.toString()}';
    } finally {
      _isRemovingLocalModel = false;
      notifyListeners();
    }
  }

  Future<void> _saveApiKey(Future<void> Function() action) async {
    _isSavingApiKey = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = 'Could not save AI settings. ${error.toString()}';
    } finally {
      _isSavingApiKey = false;
      notifyListeners();
    }
  }

  Future<void> _saveModel(Future<void> Function() action) async {
    _isSavingModel = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = 'Could not save AI settings. ${error.toString()}';
    } finally {
      _isSavingModel = false;
      notifyListeners();
    }
  }

  Future<void> _refreshLocalGemmaStatus() async {
    final service = _localGemmaService;
    if (service == null) {
      _installedLocalModels = const <LocalGemmaModel>{};
      _localGemmaError = 'Offline Gemma is unavailable in this build.';
      return;
    }

    try {
      final status = await service.getStatus();
      _applyLocalGemmaStatus(status);
    } catch (error) {
      _installedLocalModels = const <LocalGemmaModel>{};
      _localGemmaError =
          'Offline Gemma could not be checked on this device. ${error.toString()}';
    }
  }

  void _applyLocalGemmaStatus(LocalGemmaServiceStatus status) {
    _installedLocalModels = status.installedModels;
    _localGemmaError = status.errorMessage;
  }
}
