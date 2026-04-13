import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';

SpeechToTextService createPlatformSpeechToTextService() {
  return switch (defaultTargetPlatform) {
    TargetPlatform.android ||
    TargetPlatform.iOS => MethodChannelSpeechToTextService(),
    _ => const UnsupportedSpeechToTextService(),
  };
}

class MethodChannelSpeechToTextService implements SpeechToTextService {
  MethodChannelSpeechToTextService() {
    _eventsSubscription = _eventChannel.receiveBroadcastStream().listen(
      _handlePlatformEvent,
      onError: (Object error) {
        _eventsController.add(
          SpeechToTextErrorEvent(
            code: 'platform-error',
            message: 'Local speech recognition stopped unexpectedly.',
          ),
        );
      },
    );
  }

  static const MethodChannel _methodChannel = MethodChannel(
    'tokenizers/local_speech_to_text/methods',
  );
  static const EventChannel _eventChannel = EventChannel(
    'tokenizers/local_speech_to_text/events',
  );

  final StreamController<SpeechToTextEvent> _eventsController =
      StreamController<SpeechToTextEvent>.broadcast();
  late final StreamSubscription<dynamic> _eventsSubscription;

  @override
  Stream<SpeechToTextEvent> get events => _eventsController.stream;

  @override
  Future<SpeechAvailability> prepare({required List<String> localeIds}) async {
    final payload = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
      'prepare',
      <String, Object?>{'localeIds': localeIds},
    );
    return SpeechAvailability.fromMap(payload ?? const <Object?, Object?>{});
  }

  @override
  Future<void> startListening({required String localeId}) {
    return _methodChannel.invokeMethod<void>(
      'startListening',
      <String, Object?>{'localeId': localeId},
    );
  }

  @override
  Future<void> stopListening() {
    return _methodChannel.invokeMethod<void>('stopListening');
  }

  @override
  Future<void> cancelListening() {
    return _methodChannel.invokeMethod<void>('cancelListening');
  }

  void _handlePlatformEvent(dynamic event) {
    if (event is! Map<Object?, Object?>) {
      return;
    }

    switch (event['type'] as String? ?? '') {
      case 'status':
        final status = switch (event['status'] as String? ?? 'idle') {
          'listening' => SpeechToTextStatus.listening,
          'processing' => SpeechToTextStatus.processing,
          _ => SpeechToTextStatus.idle,
        };
        _eventsController.add(SpeechToTextStatusEvent(status));
      case 'transcript':
        final text = event['text'] as String? ?? '';
        if (text.trim().isEmpty) {
          return;
        }
        _eventsController.add(
          SpeechToTextTranscriptEvent(
            isFinal: event['isFinal'] as bool? ?? false,
            text: text,
          ),
        );
      case 'error':
        _eventsController.add(
          SpeechToTextErrorEvent(
            code: event['code'] as String? ?? 'platform-error',
            message:
                event['message'] as String? ??
                'Local speech recognition stopped unexpectedly.',
          ),
        );
    }
  }

  @override
  void dispose() {
    unawaited(cancelListening());
    unawaited(_eventsSubscription.cancel());
    unawaited(_eventsController.close());
  }
}
