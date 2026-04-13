import 'package:tokenizers/src/features/assistant/application/speech_to_text_service.dart';

SpeechToTextService createPlatformSpeechToTextService() {
  return const UnsupportedSpeechToTextService();
}
