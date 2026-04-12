import 'package:flutter/foundation.dart';

import 'package:tokenizers/src/features/settings/application/ai_settings_repository.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Coordinates AI settings persistence and exposes live configuration state.
class AiSettingsController extends ChangeNotifier {
  /// Creates an AI settings controller.
  AiSettingsController({required AiSettingsRepository repository})
    : _repository = repository;

  final AiSettingsRepository _repository;
  AiSettings _settings = const AiSettings();
  String? _geminiApiKey;
  bool _isLoaded = false;
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

  /// Explains why the assistant is unavailable.
  String? get configurationError => _settings.configurationError;

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
}
