import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';
import 'package:tokenizers/src/features/assistant/application/voice_input_controller.dart';

void main() {
  test(
    'VoiceInputController starts local recognition with the resolved locale',
    () async {
      final speechService = _FakeSpeechToTextService(
        prepareResult: const SpeechAvailability.available(localeId: 'en-US'),
      );
      final controller = VoiceInputController(
        speechToTextService: speechService,
        localeCandidates: const <String>['ga-IE', 'en-US'],
      );
      addTearDown(controller.dispose);

      await controller.start();

      expect(speechService.startedLocaleIds, <String>['en-US']);
      expect(controller.isListening, isTrue);

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: false,
          text: 'Add vitamin D',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Add vitamin D');

      speechService.emit(
        const SpeechToTextStatusEvent(SpeechToTextStatus.processing),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.isProcessing, isTrue);

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: true,
          text: 'Add vitamin D 1000 IU at 9am',
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.transcript, 'Add vitamin D 1000 IU at 9am');
      expect(controller.canInsert, isTrue);
      expect(controller.isListening, isFalse);
      expect(controller.isProcessing, isFalse);
    },
  );

  test('VoiceInputController surfaces availability failures', () async {
    final speechService = _FakeSpeechToTextService(
      prepareResult: const SpeechAvailability.unavailable(
        message: 'Local speech recognition is unavailable.',
        status: SpeechAvailabilityStatus.unsupported,
      ),
    );
    final controller = VoiceInputController(
      speechToTextService: speechService,
      localeCandidates: const <String>['en-US'],
    );
    addTearDown(controller.dispose);

    await controller.start();

    expect(controller.errorMessage, 'Local speech recognition is unavailable.');
    expect(controller.isListening, isFalse);
    expect(controller.canInsert, isFalse);
  });

  test('VoiceInputController recovers when prepare throws', () async {
    final speechService = _FakeSpeechToTextService(
      prepareError: PlatformException(code: 'channel-error'),
    );
    final controller = VoiceInputController(
      speechToTextService: speechService,
      localeCandidates: const <String>['en-US'],
    );
    addTearDown(controller.dispose);

    await controller.start();

    expect(
      controller.errorMessage,
      'Could not check local speech recognition.',
    );
    expect(controller.helperMessage, 'Try again in a moment.');
    expect(controller.isPreparing, isFalse);
    expect(controller.isBusy, isFalse);
    expect(controller.isListening, isFalse);
  });

  test(
    'VoiceInputController retries fallback locales on language errors',
    () async {
      final speechService = _FakeSpeechToTextService(
        prepareResult: const SpeechAvailability.available(localeId: 'ga-IE'),
        startErrors: <String, Object>{
          'ga-IE': PlatformException(code: 'language-not-supported'),
        },
      );
      final controller = VoiceInputController(
        speechToTextService: speechService,
        localeCandidates: const <String>['ga-IE', 'en-US'],
      );
      addTearDown(controller.dispose);

      await controller.start();

      expect(speechService.startedLocaleIds, <String>['ga-IE', 'en-US']);
      expect(controller.isListening, isTrue);
    },
  );

  test(
    'VoiceInputController preserves earlier text across listening restarts',
    () async {
      final speechService = _FakeSpeechToTextService(
        prepareResult: const SpeechAvailability.available(localeId: 'en-US'),
      );
      final controller = VoiceInputController(
        speechToTextService: speechService,
        localeCandidates: const <String>['en-US'],
      );
      addTearDown(controller.dispose);

      await controller.start();

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: true,
          text: 'Take vitamin D',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D');
      expect(controller.canInsert, isTrue);

      speechService.emit(
        const SpeechToTextStatusEvent(SpeechToTextStatus.idle),
      );
      await Future<void>.delayed(Duration.zero);

      await controller.start();
      expect(controller.transcript, 'Take vitamin D');

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: false,
          text: 'after breakfast',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D after breakfast');

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: true,
          text: 'after breakfast',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D after breakfast');
      expect(speechService.startedLocaleIds, <String>['en-US', 'en-US']);
    },
  );

  test(
    'VoiceInputController preserves earlier text when iOS resets partial text',
    () async {
      final speechService = _FakeSpeechToTextService(
        prepareResult: const SpeechAvailability.available(localeId: 'en-US'),
      );
      final controller = VoiceInputController(
        speechToTextService: speechService,
        localeCandidates: const <String>['en-US'],
      );
      addTearDown(controller.dispose);

      await controller.start();

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: false,
          text: 'Take vitamin D',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D');

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: false,
          text: 'after breakfast',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D after breakfast');

      speechService.emit(
        const SpeechToTextTranscriptEvent(
          isFinal: true,
          text: 'after breakfast at 9am',
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(controller.transcript, 'Take vitamin D after breakfast at 9am');
    },
  );
}

class _FakeSpeechToTextService implements SpeechToTextService {
  _FakeSpeechToTextService({
    this.prepareResult,
    this.prepareError,
    this.startErrors = const <String, Object>{},
  });

  final SpeechAvailability? prepareResult;
  final Object? prepareError;
  final Map<String, Object> startErrors;
  final StreamController<SpeechToTextEvent> _eventsController =
      StreamController<SpeechToTextEvent>.broadcast();
  final List<String> startedLocaleIds = <String>[];

  @override
  Stream<SpeechToTextEvent> get events => _eventsController.stream;

  @override
  Future<void> cancelListening() async {}

  @override
  void dispose() {
    unawaited(_eventsController.close());
  }

  void emit(SpeechToTextEvent event) {
    _eventsController.add(event);
  }

  @override
  Future<SpeechAvailability> prepare({required List<String> localeIds}) async {
    if (prepareError != null) {
      throw prepareError!;
    }
    return prepareResult!;
  }

  @override
  Future<void> startListening({required String localeId}) async {
    startedLocaleIds.add(localeId);
    final startError = startErrors[localeId];
    if (startError != null) {
      throw startError;
    }
    emit(const SpeechToTextStatusEvent(SpeechToTextStatus.listening));
  }

  @override
  Future<void> stopListening() async {
    emit(const SpeechToTextStatusEvent(SpeechToTextStatus.processing));
  }
}
