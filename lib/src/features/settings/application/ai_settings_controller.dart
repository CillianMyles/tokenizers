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
  bool _isSaving = false;
  String? _errorMessage;

  /// The current AI settings snapshot.
  AiSettings get settings => _settings;

  /// Whether settings have been loaded from storage.
  bool get isLoaded => _isLoaded;

  /// Whether a settings write is currently in progress.
  bool get isSaving => _isSaving;

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
    await _save(() async {
      final trimmedApiKey = replacementApiKey.trim();
      var nextSettings = await _repository.save(
        _settings.copyWith(geminiModel: geminiModel),
      );

      if (trimmedApiKey.isNotEmpty) {
        await _repository.saveGeminiApiKey(trimmedApiKey);
        _geminiApiKey = trimmedApiKey;
        nextSettings = nextSettings.copyWith(apiKeySource: ApiKeySource.stored);
      } else {
        nextSettings = nextSettings.copyWith(
          apiKeySource: _settings.apiKeySource,
        );
      }

      _settings = nextSettings;
    });
  }

  /// Clears the stored Gemini API key.
  Future<void> clearGeminiApiKey() async {
    await _save(() async {
      await _repository.clearGeminiApiKey();
      final apiKeyRecord = await _repository.loadGeminiApiKeyRecord();
      _geminiApiKey = apiKeyRecord?.value;
      _settings = _settings.copyWith(
        apiKeySource: apiKeyRecord?.source ?? ApiKeySource.none,
      );
    });
  }

  Future<void> _save(Future<void> Function() action) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
    } catch (error) {
      _errorMessage = 'Could not save AI settings. ${error.toString()}';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
