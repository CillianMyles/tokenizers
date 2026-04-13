import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:tokenizers/src/features/settings/domain/ai_settings.dart';

/// Read-only snapshot of local Gemma availability and installed models.
class LocalGemmaServiceStatus {
  /// Creates a service status snapshot.
  const LocalGemmaServiceStatus({
    this.errorMessage,
    this.installedModels = const <LocalGemmaModel>{},
  });

  /// Human-friendly initialization or platform error, if any.
  final String? errorMessage;

  /// Installed local Gemma presets available to the app.
  final Set<LocalGemmaModel> installedModels;

  /// Whether the service is usable on the current platform.
  bool get isSupported => errorMessage == null;

  /// Whether a given preset is already installed locally.
  bool isInstalled(LocalGemmaModel model) => installedModels.contains(model);
}

/// Abstraction for local Gemma runtime and download lifecycle.
abstract interface class LocalGemmaService {
  /// Returns current platform support and installed local models.
  Future<LocalGemmaServiceStatus> getStatus();

  /// Downloads the requested local model from Hugging Face.
  Future<LocalGemmaServiceStatus> downloadModel(
    LocalGemmaModel model, {
    void Function(int progress)? onProgress,
  });

  /// Removes a previously installed local model from device storage.
  Future<LocalGemmaServiceStatus> deleteModel(LocalGemmaModel model);

  /// Runs local inference and returns the raw model text response.
  Future<String> generateText({
    required LocalGemmaModel model,
    required String prompt,
    required String systemInstruction,
    int maxTokens = 2048,
  });
}

/// `flutter_gemma`-backed implementation for on-device Gemma 4 workflows.
class FlutterGemmaLocalService implements LocalGemmaService {
  const FlutterGemmaLocalService();

  static Future<void>? _initialization;
  static String? _initializationError;

  @override
  Future<LocalGemmaServiceStatus> deleteModel(LocalGemmaModel model) async {
    await _ensureInitialized();
    if (_initializationError case final message?) {
      return LocalGemmaServiceStatus(errorMessage: message);
    }

    await FlutterGemmaPlugin.instance.modelManager.deleteModel(_specFor(model));
    return getStatus();
  }

  @override
  Future<LocalGemmaServiceStatus> downloadModel(
    LocalGemmaModel model, {
    void Function(int progress)? onProgress,
  }) async {
    await _ensureInitialized();
    if (_initializationError case final message?) {
      return LocalGemmaServiceStatus(errorMessage: message);
    }

    var builder = FlutterGemma.installModel(
      modelType: ModelType.gemmaIt,
    ).fromNetwork(model.downloadUri.toString());
    if (onProgress != null) {
      builder = builder.withProgress(onProgress);
    }
    await builder.install();
    return getStatus();
  }

  @override
  Future<String> generateText({
    required LocalGemmaModel model,
    required String prompt,
    required String systemInstruction,
    int maxTokens = 2048,
  }) async {
    await _ensureInitialized();
    if (_initializationError case final message?) {
      throw StateError(message);
    }

    final status = await getStatus();
    if (!status.isInstalled(model)) {
      throw StateError(
        'Download ${model.label} in Settings before using the offline assistant.',
      );
    }

    FlutterGemmaPlugin.instance.modelManager.setActiveModel(_specFor(model));
    final inferenceModel = await FlutterGemma.getActiveModel(
      maxTokens: maxTokens,
    );

    try {
      final chat = await inferenceModel.createChat(
        isThinking: true,
        modelType: ModelType.gemmaIt,
        systemInstruction: systemInstruction,
      );
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));
      final response = await chat.generateChatResponse();
      return switch (response) {
        TextResponse(:final token) => token.trim(),
        ThinkingResponse(:final content) => content.trim(),
        FunctionCallResponse() => throw StateError(
          'Local Gemma returned an unexpected function call response.',
        ),
        ParallelFunctionCallResponse() => throw StateError(
          'Local Gemma returned unexpected parallel function calls.',
        ),
      };
    } finally {
      await inferenceModel.close();
    }
  }

  @override
  Future<LocalGemmaServiceStatus> getStatus() async {
    await _ensureInitialized();
    if (_initializationError case final message?) {
      return LocalGemmaServiceStatus(errorMessage: message);
    }

    final installedModels = <LocalGemmaModel>{};
    for (final model in LocalGemmaModel.values) {
      final isInstalled = await FlutterGemma.isModelInstalled(model.fileName);
      if (isInstalled) {
        installedModels.add(model);
      }
    }

    return LocalGemmaServiceStatus(installedModels: installedModels);
  }

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    try {
      await FlutterGemma.initialize(webStorageMode: WebStorageMode.streaming);
    } catch (error) {
      _initializationError = _friendlyInitializationError(error);
    }
  }

  String _friendlyInitializationError(Object error) {
    final message = error.toString();
    if (message.contains('UnsupportedError')) {
      return 'Offline Gemma is unavailable on this device or platform.';
    }
    return 'Offline Gemma could not start on this device. $message';
  }

  InferenceModelSpec _specFor(LocalGemmaModel model) {
    return InferenceModelSpec.fromLegacyUrl(
      name: model.modelId,
      modelUrl: model.downloadUri.toString(),
      modelType: ModelType.gemmaIt,
    );
  }
}
