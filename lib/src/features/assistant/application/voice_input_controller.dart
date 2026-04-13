import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';

/// Controls the assistant voice-input sheet state.
class VoiceInputController extends ChangeNotifier {
  /// Creates a voice input controller.
  VoiceInputController({
    required SpeechToTextService speechToTextService,
    List<String>? localeCandidates,
  }) : _speechToTextService = speechToTextService,
       _localeCandidates = localeCandidates ?? defaultLocaleCandidates() {
    _eventsSubscription = _speechToTextService.events.listen(_handleEvent);
  }

  final List<String> _localeCandidates;
  final SpeechToTextService _speechToTextService;
  late final StreamSubscription<SpeechToTextEvent> _eventsSubscription;

  String? _errorMessage;
  String _helperMessage = 'Tap start to transcribe speech on this device.';
  bool _isListening = false;
  bool _isPreparing = false;
  bool _isProcessing = false;
  String _transcript = '';

  /// Suggested locale fallbacks for local speech recognition.
  static List<String> defaultLocaleCandidates() {
    final localeId = PlatformDispatcher.instance.locale.toLanguageTag();
    final candidates = <String>[];

    if (localeId.isNotEmpty) {
      candidates.add(localeId);
    }
    if (localeId.startsWith('en-') && !candidates.contains('en-US')) {
      candidates.add('en-US');
    }
    if (!candidates.contains('en-US')) {
      candidates.add('en-US');
    }

    return candidates;
  }

  /// Whether the sheet is asking the platform to prepare speech recognition.
  bool get isPreparing => _isPreparing;

  /// Whether the sheet is actively listening to the microphone.
  bool get isListening => _isListening;

  /// Whether the platform is finalizing the local transcript.
  bool get isProcessing => _isProcessing;

  /// Current transcript shown to the user.
  String get transcript => _transcript;

  /// Human-readable helper copy for the current state.
  String get helperMessage => _helperMessage;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether the user can insert the current transcript into the composer.
  bool get canInsert =>
      _transcript.trim().isNotEmpty && !_isPreparing && !_isListening;

  /// Whether the controller is busy with microphone work.
  bool get isBusy => _isPreparing || _isListening || _isProcessing;

  /// Starts a local-only speech session.
  Future<void> start() async {
    if (isBusy) {
      return;
    }

    _errorMessage = null;
    _helperMessage = 'Checking on-device speech recognition…';
    _isPreparing = true;
    _isProcessing = false;
    _isListening = false;
    _transcript = '';
    notifyListeners();

    final availability = await _speechToTextService.prepare(
      localeIds: _localeCandidates,
    );

    _isPreparing = false;
    if (!availability.isAvailable || availability.resolvedLocaleId == null) {
      _errorMessage = availability.message;
      _helperMessage = 'Local speech recognition could not start.';
      notifyListeners();
      return;
    }

    _helperMessage = 'Listening locally on this device…';
    notifyListeners();

    try {
      await _speechToTextService.startListening(
        localeId: availability.resolvedLocaleId!,
      );
    } on Object {
      _errorMessage = 'Could not start local speech recognition.';
      _helperMessage = 'Try again in a moment.';
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Stops listening and waits for the final transcript.
  Future<void> stop() async {
    if (!_isListening) {
      return;
    }
    await _speechToTextService.stopListening();
  }

  /// Cancels the current recognition session and clears the transcript.
  Future<void> cancel() async {
    await _speechToTextService.cancelListening();
    _reset(
      helperMessage: 'Tap start to transcribe speech on this device.',
      transcript: '',
    );
  }

  void _handleEvent(SpeechToTextEvent event) {
    switch (event) {
      case SpeechToTextErrorEvent():
        _errorMessage = event.message;
        _helperMessage = 'Local speech recognition stopped.';
        _isListening = false;
        _isPreparing = false;
        _isProcessing = false;
      case SpeechToTextStatusEvent():
        switch (event.status) {
          case SpeechToTextStatus.idle:
            _isListening = false;
            _isProcessing = false;
            if (_errorMessage == null) {
              _helperMessage = _transcript.trim().isEmpty
                  ? 'No speech detected yet.'
                  : 'Review the transcript before inserting it.';
            }
          case SpeechToTextStatus.listening:
            _errorMessage = null;
            _isListening = true;
            _isPreparing = false;
            _isProcessing = false;
            _helperMessage = 'Listening locally on this device…';
          case SpeechToTextStatus.processing:
            _isListening = false;
            _isProcessing = true;
            _helperMessage = 'Finishing local transcription…';
        }
      case SpeechToTextTranscriptEvent():
        _errorMessage = null;
        _transcript = event.text.trim();
        if (event.isFinal) {
          _isListening = false;
          _isProcessing = false;
          _helperMessage = 'Review the transcript before inserting it.';
        }
    }
    notifyListeners();
  }

  void _reset({required String helperMessage, required String transcript}) {
    _errorMessage = null;
    _helperMessage = helperMessage;
    _isListening = false;
    _isPreparing = false;
    _isProcessing = false;
    _transcript = transcript;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_speechToTextService.cancelListening());
    unawaited(_eventsSubscription.cancel());
    super.dispose();
  }
}
