package com.cillianmyles.tokenizers

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LocalSpeechToTextBridge(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, RecognitionListener {
    private val methodChannel =
        MethodChannel(messenger, "tokenizers/local_speech_to_text/methods")
    private val eventChannel =
        EventChannel(messenger, "tokenizers/local_speech_to_text/events")

    private var eventSink: EventChannel.EventSink? = null
    private var pendingPrepareResult: MethodChannel.Result? = null
    private var pendingLocaleIds: List<String> = emptyList()
    private var speechRecognizer: SpeechRecognizer? = null
    private var isCancelling = false

    init {
        methodChannel.setMethodCallHandler(this)
        eventChannel.setStreamHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "prepare" -> prepare(call, result)
            "startListening" -> startListening(call, result)
            "stopListening" -> {
                speechRecognizer?.stopListening()
                result.success(null)
            }

            "cancelListening" -> {
                cancelActiveRecognition()
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun onRequestPermissionsResult(
        requestCode: Int,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != requestCodeRecordAudio) {
            return false
        }

        val result = pendingPrepareResult ?: return true
        pendingPrepareResult = null
        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(availableResult(pendingLocaleIds))
        } else {
            result.success(
                mapOf(
                    "message" to
                        "Microphone permission was denied, so local speech recognition cannot start.",
                    "resolvedLocaleId" to pendingLocaleIds.firstOrNull(),
                    "status" to "permissionDenied",
                ),
            )
        }
        pendingLocaleIds = emptyList()
        return true
    }

    fun dispose() {
        cancelActiveRecognition()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun prepare(call: MethodCall, result: MethodChannel.Result) {
        val localeIds = call.argument<List<String>>("localeIds").orEmpty()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(
                mapOf(
                    "message" to
                        "On-device speech recognition requires Android 12 or newer.",
                    "resolvedLocaleId" to localeIds.firstOrNull(),
                    "status" to "unsupported",
                ),
            )
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
            result.success(
                mapOf(
                    "message" to
                        "Speech recognition is unavailable on this Android device.",
                    "resolvedLocaleId" to localeIds.firstOrNull(),
                    "status" to "unsupported",
                ),
            )
            return
        }

        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)) {
            result.success(
                mapOf(
                    "message" to
                        "On-device speech recognition is unavailable on this Android device.",
                    "resolvedLocaleId" to localeIds.firstOrNull(),
                    "status" to "onDeviceUnavailable",
                ),
            )
            return
        }

        if (ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(availableResult(localeIds))
            return
        }

        pendingPrepareResult = result
        pendingLocaleIds = localeIds
        ActivityCompat.requestPermissions(
            activity,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            requestCodeRecordAudio,
        )
    }

    private fun startListening(call: MethodCall, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.error(
                "unsupported",
                "On-device speech recognition requires Android 12 or newer.",
                null,
            )
            return
        }
        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)) {
            result.error(
                "on-device-unavailable",
                "On-device speech recognition is unavailable on this device.",
                null,
            )
            return
        }
        if (ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.RECORD_AUDIO,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            result.error(
                "permission-denied",
                "Microphone permission was denied.",
                null,
            )
            return
        }

        val localeId =
            call.argument<String>("localeId")
                ?: activity.resources.configuration.locales[0].toLanguageTag()

        cancelActiveRecognition()
        isCancelling = false

        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
        speechRecognizer = recognizer
        recognizer.setRecognitionListener(this)
        recognizer.startListening(buildRecognizerIntent(localeId))
        result.success(null)
    }

    private fun buildRecognizerIntent(localeId: String): Intent {
        return Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, localeId)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
        }
    }

    private fun cancelActiveRecognition() {
        isCancelling = true
        speechRecognizer?.cancel()
        speechRecognizer?.destroy()
        speechRecognizer = null
    }

    private fun availableResult(localeIds: List<String>): Map<String, Any?> {
        return mapOf(
            "message" to "Ready for local speech recognition.",
            "resolvedLocaleId" to
                (localeIds.firstOrNull()
                    ?: activity.resources.configuration.locales[0].toLanguageTag()),
            "status" to "available",
        )
    }

    private fun emitStatus(status: String) {
        eventSink?.success(mapOf("status" to status, "type" to "status"))
    }

    private fun emitTranscript(text: String, isFinal: Boolean) {
        eventSink?.success(
            mapOf(
                "isFinal" to isFinal,
                "text" to text,
                "type" to "transcript",
            ),
        )
    }

    private fun emitError(code: String, message: String) {
        eventSink?.success(
            mapOf(
                "code" to code,
                "message" to message,
                "type" to "error",
            ),
        )
    }

    override fun onReadyForSpeech(params: Bundle?) {
        emitStatus("listening")
    }

    override fun onBeginningOfSpeech() {
        emitStatus("listening")
    }

    override fun onRmsChanged(rmsdB: Float) = Unit

    override fun onBufferReceived(buffer: ByteArray?) = Unit

    override fun onEndOfSpeech() {
        emitStatus("processing")
    }

    override fun onError(error: Int) {
        if ((isCancelling || speechRecognizer == null) &&
            error == SpeechRecognizer.ERROR_CLIENT
        ) {
            isCancelling = false
            return
        }

        val (code, message) =
            when (error) {
                SpeechRecognizer.ERROR_AUDIO ->
                    "audio-capture" to
                        "Android could not read microphone audio for local speech recognition."

                SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS ->
                    "permission-denied" to
                        "Microphone permission was denied, so local speech recognition cannot start."

                SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED ->
                    "language-not-supported" to
                        "On-device speech recognition is unavailable for the current language on Android."

                SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE ->
                    "language-unavailable" to
                        "Android does not currently have an on-device model for this language."

                SpeechRecognizer.ERROR_NO_MATCH ->
                    "no-match" to
                        "No speech was detected. Try recording again."

                SpeechRecognizer.ERROR_NETWORK,
                SpeechRecognizer.ERROR_NETWORK_TIMEOUT,
                SpeechRecognizer.ERROR_SERVER ->
                    "service-unavailable" to
                        "Android could not complete local speech recognition."

                else ->
                    "recognition-error" to
                        "Android stopped local speech recognition unexpectedly."
            }

        emitStatus("idle")
        emitError(code, message)
        speechRecognizer?.destroy()
        speechRecognizer = null
        isCancelling = false
    }

    override fun onResults(results: Bundle?) {
        val transcript =
            results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                ?.firstOrNull()
                ?.trim()
                .orEmpty()
        if (transcript.isNotEmpty()) {
            emitTranscript(transcript, true)
        }
        emitStatus("idle")
        speechRecognizer?.destroy()
        speechRecognizer = null
        isCancelling = false
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val transcript =
            partialResults?.getStringArrayList(
                SpeechRecognizer.RESULTS_RECOGNITION,
            )?.firstOrNull()
                ?.trim()
                .orEmpty()
        if (transcript.isNotEmpty()) {
            emitTranscript(transcript, false)
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) = Unit

    companion object {
        private const val requestCodeRecordAudio = 9107
    }
}
