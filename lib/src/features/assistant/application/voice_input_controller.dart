import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
  String _committedTranscript = '';
  String _activeTranscript = '';

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
  String get transcript =>
      _joinTranscript(_committedTranscript, _activeTranscript);

  /// Human-readable helper copy for the current state.
  String get helperMessage => _helperMessage;

  /// Current error message, if any.
  String? get errorMessage => _errorMessage;

  /// Whether the user can insert the current transcript into the composer.
  bool get canInsert =>
      transcript.trim().isNotEmpty && !_isPreparing && !_isListening;

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
    _committedTranscript = transcript;
    _activeTranscript = '';
    notifyListeners();

    SpeechAvailability availability;
    try {
      availability = await _speechToTextService.prepare(
        localeIds: _localeCandidates,
      );
    } on Object {
      _errorMessage = 'Could not check local speech recognition.';
      _helperMessage = 'Try again in a moment.';
      _isPreparing = false;
      notifyListeners();
      return;
    }

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
      await _startListening(resolvedLocaleId: availability.resolvedLocaleId!);
    } on Object {
      _errorMessage = 'Could not start local speech recognition.';
      _helperMessage = 'Try again in a moment.';
      _isListening = false;
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> _startListening({required String resolvedLocaleId}) async {
    Object? lastError;
    for (final localeId in _startLocaleIds(resolvedLocaleId)) {
      try {
        await _speechToTextService.startListening(localeId: localeId);
        return;
      } on PlatformException catch (error) {
        lastError = error;
        if (_isLocaleError(error.code)) {
          continue;
        }
        rethrow;
      }
    }

    if (lastError case Object()) {
      throw lastError;
    }
    throw StateError('No locale candidates were available.');
  }

  List<String> _startLocaleIds(String resolvedLocaleId) {
    final localeIds = <String>[resolvedLocaleId];
    for (final localeId in _localeCandidates) {
      final trimmed = localeId.trim();
      if (trimmed.isEmpty || localeIds.contains(trimmed)) {
        continue;
      }
      localeIds.add(trimmed);
    }
    return localeIds;
  }

  bool _isLocaleError(String code) {
    return code == 'language-not-supported' ||
        code == 'language-unavailable' ||
        code == 'on-device-unavailable';
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
              _helperMessage = transcript.trim().isEmpty
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
        final text = event.text.trim();
        if (event.isFinal) {
          _activeTranscript = _nextActiveTranscript(
            previousText: _activeTranscript,
            nextText: text,
          );
          _committedTranscript = _appendTranscript(
            _committedTranscript,
            _activeTranscript,
          );
          _activeTranscript = '';
          _isListening = false;
          _isProcessing = false;
          _helperMessage = 'Review the transcript before inserting it.';
        } else {
          if (_looksLikeContinuation(
            previousText: _activeTranscript,
            nextText: text,
          )) {
            _activeTranscript = text;
          } else {
            _committedTranscript = _appendTranscript(
              _committedTranscript,
              _activeTranscript,
            );
            _activeTranscript = text;
          }
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
    _committedTranscript = transcript.trim();
    _activeTranscript = '';
    notifyListeners();
  }

  String _appendTranscript(String existingText, String nextText) {
    final trimmedExistingText = existingText.trim();
    final trimmedNextText = nextText.trim();
    if (trimmedNextText.isEmpty) {
      return trimmedExistingText;
    }
    if (trimmedExistingText.isEmpty) {
      return trimmedNextText;
    }
    return '$trimmedExistingText $trimmedNextText';
  }

  String _joinTranscript(String committedText, String activeText) {
    return _appendTranscript(committedText, activeText);
  }

  bool _looksLikeContinuation({
    required String previousText,
    required String nextText,
  }) {
    final trimmedPreviousText = previousText.trim();
    final trimmedNextText = nextText.trim();
    if (trimmedPreviousText.isEmpty || trimmedNextText.isEmpty) {
      return true;
    }
    if (trimmedPreviousText == trimmedNextText) {
      return true;
    }
    if (trimmedPreviousText.startsWith(trimmedNextText) ||
        trimmedNextText.startsWith(trimmedPreviousText)) {
      return true;
    }
    return _sharedPrefixLength(trimmedPreviousText, trimmedNextText) >=
        trimmedPreviousText.length ~/ 2;
  }

  String _nextActiveTranscript({
    required String previousText,
    required String nextText,
  }) {
    return _looksLikeContinuation(
          previousText: previousText,
          nextText: nextText,
        )
        ? nextText.trim()
        : _appendTranscript(previousText, nextText);
  }

  int _sharedPrefixLength(String leftText, String rightText) {
    final limit = leftText.length < rightText.length
        ? leftText.length
        : rightText.length;
    var index = 0;
    while (index < limit &&
        leftText.codeUnitAt(index) == rightText.codeUnitAt(index)) {
      index += 1;
    }
    return index;
  }

  @override
  void dispose() {
    unawaited(_speechToTextService.cancelListening());
    unawaited(_eventsSubscription.cancel());
    super.dispose();
  }
}
