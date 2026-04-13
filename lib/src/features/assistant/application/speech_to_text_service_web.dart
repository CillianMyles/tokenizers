import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';
import 'package:web/web.dart' as web;

SpeechToTextService createPlatformSpeechToTextService() {
  return WebSpeechToTextService();
}

class WebSpeechToTextService implements SpeechToTextService {
  final StreamController<SpeechToTextEvent> _eventsController =
      StreamController<SpeechToTextEvent>.broadcast();

  web.SpeechRecognition? _recognition;
  bool _isCancelling = false;

  @override
  Stream<SpeechToTextEvent> get events => _eventsController.stream;

  @override
  Future<SpeechAvailability> prepare({required List<String> localeIds}) async {
    final constructor = _speechRecognitionConstructor;
    if (constructor == null) {
      return const SpeechAvailability.unavailable(
        message:
            'Chrome local speech recognition is unavailable in this browser.',
        status: SpeechAvailabilityStatus.unsupported,
      );
    }

    final availableMethod = constructor['available'];
    final installMethod = constructor['install'];
    if (!_isJSFunction(availableMethod) || !_isJSFunction(installMethod)) {
      return const SpeechAvailability.unavailable(
        message: 'This browser cannot guarantee local-only speech recognition.',
        status: SpeechAvailabilityStatus.unsupported,
      );
    }
    final availableFunction = availableMethod as JSFunction;
    final installFunction = installMethod as JSFunction;

    SpeechAvailability? installFailure;
    for (final localeId in _dedupeLocales(localeIds)) {
      final availability = await _checkAvailability(
        availableMethod: availableFunction,
        constructor: constructor,
        localeId: localeId,
      );

      switch (availability) {
        case 'available':
          return SpeechAvailability.available(localeId: localeId);
        case 'downloadable':
        case 'downloading':
          final installed = await _installLanguagePack(
            constructor: constructor,
            installMethod: installFunction,
            localeId: localeId,
          );
          if (installed) {
            return SpeechAvailability.available(localeId: localeId);
          }
          installFailure = const SpeechAvailability.unavailable(
            message: 'Chrome could not install the local speech language pack.',
            status: SpeechAvailabilityStatus.installationFailed,
          );
        case 'unavailable':
          continue;
        default:
          continue;
      }
    }

    return installFailure ??
        const SpeechAvailability.unavailable(
          message:
              'Local speech recognition is unavailable for the current language in Chrome.',
          status: SpeechAvailabilityStatus.localeUnavailable,
        );
  }

  @override
  Future<void> startListening({required String localeId}) async {
    final constructor = _speechRecognitionConstructor;
    if (constructor == null) {
      throw StateError('SpeechRecognition is unavailable.');
    }

    await cancelListening();

    final recognition = _createRecognition(constructor);
    recognition.continuous = false;
    recognition.interimResults = true;
    recognition.lang = localeId;
    recognition.maxAlternatives = 1;
    recognition['processLocally'] = true.toJS;

    recognition.onstart = ((web.Event _) {
      _eventsController.add(
        const SpeechToTextStatusEvent(SpeechToTextStatus.listening),
      );
    }).toJS;
    recognition.onspeechend = ((web.Event _) {
      _eventsController.add(
        const SpeechToTextStatusEvent(SpeechToTextStatus.processing),
      );
    }).toJS;
    recognition.onend = ((web.Event _) {
      _eventsController.add(
        const SpeechToTextStatusEvent(SpeechToTextStatus.idle),
      );
      _disposeRecognition();
    }).toJS;
    recognition.onresult = ((web.Event event) {
      final speechEvent = event as web.SpeechRecognitionEvent;
      final results = speechEvent.results;
      if (results.length == 0) {
        return;
      }

      final latest = results.item(results.length - 1);
      final transcript = latest.item(0).transcript.trim();
      if (transcript.isEmpty) {
        return;
      }

      _eventsController.add(
        SpeechToTextTranscriptEvent(isFinal: latest.isFinal, text: transcript),
      );
    }).toJS;
    recognition.onerror = ((web.Event event) {
      final errorEvent = event as web.SpeechRecognitionErrorEvent;
      final code = errorEvent.error;
      if (_isCancelling && code == 'aborted') {
        _isCancelling = false;
        return;
      }

      final message = switch (code) {
        'audio-capture' =>
          'Chrome could not access the microphone for local speech recognition.',
        'language-not-supported' =>
          'Local speech recognition is unavailable for the current language in Chrome.',
        'not-allowed' =>
          'Microphone access was denied, so local speech recognition cannot start.',
        'service-not-allowed' =>
          'Chrome blocked local speech recognition for this page.',
        _ => 'Chrome stopped local speech recognition unexpectedly.',
      };
      _eventsController.add(
        SpeechToTextErrorEvent(code: code, message: message),
      );
    }).toJS;

    _recognition = recognition;
    recognition.start();
  }

  @override
  Future<void> stopListening() async {
    _recognition?.stop();
  }

  @override
  Future<void> cancelListening() async {
    final recognition = _recognition;
    if (recognition == null) {
      return;
    }
    _isCancelling = true;
    recognition.abort();
    _disposeRecognition();
  }

  @override
  void dispose() {
    unawaited(cancelListening());
    unawaited(_eventsController.close());
  }

  JSFunction? get _speechRecognitionConstructor {
    final constructor = globalContext['SpeechRecognition'];
    if (_isJSFunction(constructor)) {
      return constructor as JSFunction;
    }

    final webkitConstructor = globalContext['webkitSpeechRecognition'];
    if (_isJSFunction(webkitConstructor)) {
      return webkitConstructor as JSFunction;
    }
    return null;
  }

  Future<String> _checkAvailability({
    required JSFunction availableMethod,
    required JSFunction constructor,
    required String localeId,
  }) async {
    final options = _newJsObject();
    options['langs'] = <JSString>[localeId.toJS].toJS;
    options['processLocally'] = true.toJS;

    try {
      final promise =
          availableMethod.callAsFunction(constructor, options)
              as JSPromise<JSString>;
      final value = await promise.toDart;
      return value.toDart;
    } on Object {
      return 'unavailable';
    }
  }

  Future<bool> _installLanguagePack({
    required JSFunction constructor,
    required JSFunction installMethod,
    required String localeId,
  }) async {
    final options = _newJsObject();
    options['langs'] = <JSString>[localeId.toJS].toJS;
    options['processLocally'] = true.toJS;

    try {
      final promise =
          installMethod.callAsFunction(constructor, options)
              as JSPromise<JSBoolean>;
      final value = await promise.toDart;
      return value.toDart;
    } on Object {
      return false;
    }
  }

  web.SpeechRecognition _createRecognition(JSFunction constructor) {
    return constructor.callAsConstructor<web.SpeechRecognition>();
  }

  void _disposeRecognition() {
    _recognition?.onaudiostart = null;
    _recognition?.onsoundstart = null;
    _recognition?.onspeechstart = null;
    _recognition?.onspeechend = null;
    _recognition?.onsoundend = null;
    _recognition?.onaudioend = null;
    _recognition?.onresult = null;
    _recognition?.onnomatch = null;
    _recognition?.onerror = null;
    _recognition?.onstart = null;
    _recognition?.onend = null;
    _recognition = null;
    _isCancelling = false;
  }

  List<String> _dedupeLocales(List<String> localeIds) {
    final candidates = <String>[];
    for (final localeId in localeIds) {
      final trimmed = localeId.trim();
      if (trimmed.isNotEmpty && !candidates.contains(trimmed)) {
        candidates.add(trimmed);
      }
    }
    return candidates;
  }
}

JSObject _newJsObject() {
  final objectConstructor = globalContext['Object'] as JSFunction;
  return objectConstructor.callAsConstructor<JSObject>();
}

bool _isJSFunction(JSAny? value) {
  return value != null && value.isA<JSFunction>();
}
