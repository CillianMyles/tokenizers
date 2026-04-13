import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';
import 'package:tokenizers/src/features/assistant/application/voice_input_controller.dart';

void main() {
  test(
    'VoiceInputController starts local recognition and exposes transcript',
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
}

class _FakeSpeechToTextService implements SpeechToTextService {
  _FakeSpeechToTextService({required this.prepareResult});

  final SpeechAvailability prepareResult;
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
    return prepareResult;
  }

  @override
  Future<void> startListening({required String localeId}) async {
    startedLocaleIds.add(localeId);
    emit(const SpeechToTextStatusEvent(SpeechToTextStatus.listening));
  }

  @override
  Future<void> stopListening() async {
    emit(const SpeechToTextStatusEvent(SpeechToTextStatus.processing));
  }
}
