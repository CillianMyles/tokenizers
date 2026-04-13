import AVFoundation
import Flutter
import Speech

final class LocalSpeechToTextPlugin: NSObject, FlutterStreamHandler {
  private var eventSink: FlutterEventSink?
  private let audioEngine = AVAudioEngine()
  private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
  private var recognitionTask: SFSpeechRecognitionTask?
  private var speechRecognizer: SFSpeechRecognizer?
  private var isCancelling = false

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = LocalSpeechToTextPlugin()
    let methodChannel = FlutterMethodChannel(
      name: "tokenizers/local_speech_to_text/methods",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "tokenizers/local_speech_to_text/events",
      binaryMessenger: registrar.messenger()
    )

    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }
}

extension LocalSpeechToTextPlugin: FlutterPlugin {
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "prepare":
      let payload = call.arguments as? [String: Any]
      let localeIds = payload?["localeIds"] as? [String] ?? []
      prepare(localeIds: localeIds, result: result)
    case "startListening":
      let payload = call.arguments as? [String: Any]
      let localeId = payload?["localeId"] as? String
      startListening(localeId: localeId, result: result)
    case "stopListening":
      stopListening()
      result(nil)
    case "cancelListening":
      cancelListening()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

private extension LocalSpeechToTextPlugin {
  func prepare(localeIds: [String], result: @escaping FlutterResult) {
    guard #available(iOS 13.0, *) else {
      result(
        unavailableResult(
          localeId: localeIds.first,
          message: "On-device speech recognition requires iOS 13 or newer.",
          status: "unsupported"
        )
      )
      return
    }

    SFSpeechRecognizer.requestAuthorization { [weak self] authorizationStatus in
      DispatchQueue.main.async {
        guard let self else {
          result([:])
          return
        }

        guard authorizationStatus == .authorized else {
          result(
            self.unavailableResult(
              localeId: localeIds.first,
              message:
                "Speech recognition permission was denied, so local transcription cannot start.",
              status: "permissionDenied"
            )
          )
          return
        }

        self.requestMicrophonePermission { granted in
          DispatchQueue.main.async {
            guard granted else {
              result(
                self.unavailableResult(
                  localeId: localeIds.first,
                  message:
                    "Microphone permission was denied, so local transcription cannot start.",
                  status: "permissionDenied"
                )
              )
              return
            }

            guard
              let localeId = self.firstSupportedOnDeviceLocale(from: localeIds)
            else {
              result(
                self.unavailableResult(
                  localeId: localeIds.first,
                  message:
                    "On-device speech recognition is unavailable for the current language on this iPhone.",
                  status: "onDeviceUnavailable"
                )
              )
              return
            }

            result(
              [
                "message": "Ready for local speech recognition.",
                "resolvedLocaleId": localeId,
                "status": "available",
              ]
            )
          }
        }
      }
    }
  }

  func startListening(localeId: String?, result: @escaping FlutterResult) {
    guard #available(iOS 13.0, *) else {
      result(
        FlutterError(
          code: "unsupported",
          message: "On-device speech recognition requires iOS 13 or newer.",
          details: nil
        )
      )
      return
    }

    let resolvedLocaleId =
      localeId ?? Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
    guard
      let recognizer = SFSpeechRecognizer(locale: Locale(identifier: resolvedLocaleId)),
      recognizer.supportsOnDeviceRecognition
    else {
      result(
        FlutterError(
          code: "on-device-unavailable",
          message:
            "On-device speech recognition is unavailable for the selected language.",
          details: nil
        )
      )
      return
    }

    cancelListening()
    isCancelling = false

    speechRecognizer = recognizer
    recognitionTask = nil
    recognitionRequest = nil

    do {
      let audioSession = AVAudioSession.sharedInstance()
      try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    } catch {
      result(
        FlutterError(
          code: "audio-session",
          message: "Could not configure the microphone for local speech recognition.",
          details: error.localizedDescription
        )
      )
      return
    }

    let request = SFSpeechAudioBufferRecognitionRequest()
    request.requiresOnDeviceRecognition = true //important to keep local SST
    request.shouldReportPartialResults = true
    recognitionRequest = request

    let inputNode = audioEngine.inputNode
    let format = inputNode.outputFormat(forBus: 0)
    inputNode.removeTap(onBus: 0)
    inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) {
      [weak self] buffer, _ in
      self?.recognitionRequest?.append(buffer)
    }

    audioEngine.prepare()
    do {
      try audioEngine.start()
    } catch {
      cleanupRecognitionSession()
      result(
        FlutterError(
          code: "audio-engine",
          message: "Could not start local speech recognition.",
          details: error.localizedDescription
        )
      )
      return
    }

    emitStatus("listening")
    recognitionTask = recognizer.recognitionTask(with: request) {
      [weak self] recognitionResult, error in
      guard let self else {
        return
      }

      if let recognitionResult {
        let transcript = recognitionResult.bestTranscription.formattedString
          .trimmingCharacters(in: .whitespacesAndNewlines)
        if !transcript.isEmpty {
          self.emitTranscript(text: transcript, isFinal: recognitionResult.isFinal)
        }
        if recognitionResult.isFinal {
          self.emitStatus("idle")
          self.cleanupRecognitionSession()
        }
      }

      if let error {
        if self.isCancelling {
          self.isCancelling = false
          self.cleanupRecognitionSession()
          return
        }
        self.emitStatus("idle")
        self.emitError(
          code: "recognition-error",
          message: "iOS stopped local speech recognition unexpectedly.",
          details: error.localizedDescription
        )
        self.cleanupRecognitionSession()
      }
    }

    result(nil)
  }

  func stopListening() {
    emitStatus("processing")
    recognitionRequest?.endAudio()
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
  }

  func cancelListening() {
    isCancelling = true
    recognitionTask?.cancel()
    recognitionRequest?.endAudio()
    audioEngine.stop()
    audioEngine.inputNode.removeTap(onBus: 0)
    cleanupRecognitionSession()
  }

  func cleanupRecognitionSession() {
    recognitionTask?.cancel()
    recognitionTask = nil
    recognitionRequest = nil
    speechRecognizer = nil
    if audioEngine.isRunning {
      audioEngine.stop()
    }
    audioEngine.inputNode.removeTap(onBus: 0)
    try? AVAudioSession.sharedInstance().setActive(false)
  }

  func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
      completion(granted)
    }
  }

  @available(iOS 13.0, *)
  func firstSupportedOnDeviceLocale(from localeIds: [String]) -> String? {
    for localeId in localeIds where !localeId.trimmingCharacters(in: .whitespaces).isEmpty {
      guard
        let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeId)),
        recognizer.supportsOnDeviceRecognition
      else {
        continue
      }
      return localeId
    }

    return nil
  }

  func unavailableResult(
    localeId: String?,
    message: String,
    status: String
  ) -> [String: Any?] {
    return [
      "message": message,
      "resolvedLocaleId": localeId,
      "status": status,
    ]
  }

  func emitStatus(_ status: String) {
    eventSink?(
      [
        "status": status,
        "type": "status",
      ]
    )
  }

  func emitTranscript(text: String, isFinal: Bool) {
    eventSink?(
      [
        "isFinal": isFinal,
        "text": text,
        "type": "transcript",
      ]
    )
  }

  func emitError(code: String, message: String, details: String?) {
    eventSink?(
      [
        "code": code,
        "details": details,
        "message": message,
        "type": "error",
      ]
    )
  }
}
