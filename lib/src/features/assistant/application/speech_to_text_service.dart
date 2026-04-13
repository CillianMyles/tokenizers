import 'package:tokenizers/src/features/assistant/application/speech_to_text_service_stub.dart'
    if (dart.library.js_interop) 'package:tokenizers/src/features/assistant/application/speech_to_text_service_web.dart'
    if (dart.library.io) 'package:tokenizers/src/features/assistant/application/speech_to_text_service_io.dart'
    as platform;

/// Creates the platform speech-to-text service used by the assistant.
SpeechToTextService createSpeechToTextService() {
  return platform.createPlatformSpeechToTextService();
}

/// States exposed by the local speech availability check.
enum SpeechAvailabilityStatus {
  available,
  unsupported,
  permissionDenied,
  onDeviceUnavailable,
  localeUnavailable,
  installationFailed,
}

/// Availability result for local-only speech recognition.
class SpeechAvailability {
  /// Creates a new availability result.
  const SpeechAvailability({
    required this.message,
    required this.status,
    this.resolvedLocaleId,
  });

  /// Creates an available result.
  const SpeechAvailability.available({
    required String localeId,
    this.message = 'Ready for local speech recognition.',
  }) : status = SpeechAvailabilityStatus.available,
       resolvedLocaleId = localeId;

  /// Creates an unavailable result.
  const SpeechAvailability.unavailable({
    required this.message,
    required this.status,
    this.resolvedLocaleId,
  });

  /// Describes the current availability outcome.
  final String message;

  /// Indicates how local speech recognition resolved.
  final SpeechAvailabilityStatus status;

  /// The locale that should be used when recognition starts.
  final String? resolvedLocaleId;

  /// Whether local-only speech recognition can start.
  bool get isAvailable => status == SpeechAvailabilityStatus.available;

  /// Creates an availability result from a platform channel payload.
  factory SpeechAvailability.fromMap(Map<Object?, Object?> payload) {
    final statusValue = payload['status'] as String? ?? 'unsupported';
    final message =
        payload['message'] as String? ??
        'Local speech recognition is unavailable.';
    final localeId = payload['resolvedLocaleId'] as String?;
    final status = switch (statusValue) {
      'available' => SpeechAvailabilityStatus.available,
      'permissionDenied' => SpeechAvailabilityStatus.permissionDenied,
      'onDeviceUnavailable' => SpeechAvailabilityStatus.onDeviceUnavailable,
      'localeUnavailable' => SpeechAvailabilityStatus.localeUnavailable,
      'installationFailed' => SpeechAvailabilityStatus.installationFailed,
      _ => SpeechAvailabilityStatus.unsupported,
    };
    return SpeechAvailability(
      message: message,
      status: status,
      resolvedLocaleId: localeId,
    );
  }
}

/// Service status updates emitted while local speech recognition runs.
enum SpeechToTextStatus { idle, listening, processing }

/// Base type for speech service updates.
sealed class SpeechToTextEvent {
  /// Creates a speech event.
  const SpeechToTextEvent();
}

/// Reports a service status change.
class SpeechToTextStatusEvent extends SpeechToTextEvent {
  /// Creates a status event.
  const SpeechToTextStatusEvent(this.status);

  /// Current local recognition status.
  final SpeechToTextStatus status;
}

/// Reports an updated transcript.
class SpeechToTextTranscriptEvent extends SpeechToTextEvent {
  /// Creates a transcript event.
  const SpeechToTextTranscriptEvent({
    required this.isFinal,
    required this.text,
  });

  /// Whether the transcript is final.
  final bool isFinal;

  /// Latest recognized text.
  final String text;
}

/// Reports a local recognition error.
class SpeechToTextErrorEvent extends SpeechToTextEvent {
  /// Creates an error event.
  const SpeechToTextErrorEvent({required this.code, required this.message});

  /// Stable error identifier.
  final String code;

  /// Human-readable error message.
  final String message;
}

/// App-owned contract for local-only speech recognition.
abstract interface class SpeechToTextService {
  /// Broadcast speech events for the active recognition session.
  Stream<SpeechToTextEvent> get events;

  /// Verifies that local-only speech recognition can run for one locale.
  ///
  /// The service should resolve the best supported locale from [localeIds] and
  /// never fall back to cloud recognition.
  Future<SpeechAvailability> prepare({required List<String> localeIds});

  /// Starts local-only speech recognition for [localeId].
  Future<void> startListening({required String localeId});

  /// Stops listening and requests a final transcript if available.
  Future<void> stopListening();

  /// Cancels the active recognition session without returning a final result.
  Future<void> cancelListening();

  /// Releases any held resources.
  void dispose();
}

/// Default service used when no local speech implementation is available.
class UnsupportedSpeechToTextService implements SpeechToTextService {
  /// Creates an unsupported speech service.
  const UnsupportedSpeechToTextService({
    this.message = 'Local speech recognition is not available on this device.',
  });

  /// Message shown when speech is unsupported.
  final String message;

  @override
  Stream<SpeechToTextEvent> get events =>
      const Stream<SpeechToTextEvent>.empty();

  @override
  Future<void> cancelListening() async {}

  @override
  void dispose() {}

  @override
  Future<SpeechAvailability> prepare({required List<String> localeIds}) async {
    return SpeechAvailability.unavailable(
      message: message,
      status: SpeechAvailabilityStatus.unsupported,
      resolvedLocaleId: localeIds.isEmpty ? null : localeIds.first,
    );
  }

  @override
  Future<void> startListening({required String localeId}) async {}

  @override
  Future<void> stopListening() async {}
}
