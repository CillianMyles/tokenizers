package com.cillianmyles.tokenizers

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.speech.RecognitionSupport
import android.speech.RecognitionSupportCallback
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
        val localeIds = pendingLocaleIds
        pendingPrepareResult = null
        pendingLocaleIds = emptyList()
        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            finishPrepare(result, localeIds)
        } else {
            result.success(
                unavailableResult(
                    message =
                        "Microphone permission was denied, so local speech recognition cannot start.",
                    resolvedLocaleId = requestedLocaleIds(localeIds).firstOrNull(),
                    status = "permissionDenied",
                ),
            )
        }
        return true
    }

    fun dispose() {
        cancelActiveRecognition()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    private fun prepare(call: MethodCall, result: MethodChannel.Result) {
        val localeIds = call.argument<List<String>>("localeIds").orEmpty()
        val requestedLocaleId = requestedLocaleIds(localeIds).firstOrNull()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            result.success(
                unavailableResult(
                    message =
                        "On-device speech recognition requires Android 12 or newer.",
                    resolvedLocaleId = requestedLocaleId,
                    status = "unsupported",
                ),
            )
            return
        }

        if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
            result.success(
                unavailableResult(
                    message =
                        "Speech recognition is unavailable on this Android device.",
                    resolvedLocaleId = requestedLocaleId,
                    status = "unsupported",
                ),
            )
            return
        }

        if (!SpeechRecognizer.isOnDeviceRecognitionAvailable(activity)) {
            result.success(
                unavailableResult(
                    message =
                        "On-device speech recognition is unavailable on this Android device.",
                    resolvedLocaleId = requestedLocaleId,
                    status = "onDeviceUnavailable",
                ),
            )
            return
        }

        if (ContextCompat.checkSelfPermission(
                activity,
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            finishPrepare(result, localeIds)
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
                ?: defaultLocaleId()

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

    private fun finishPrepare(
        result: MethodChannel.Result,
        localeIds: List<String>,
    ) {
        resolveSupportedLocaleId(localeIds) { localeId, hasDownloadableModel ->
            val requestedLocaleId = requestedLocaleIds(localeIds).firstOrNull()
            val payload =
                when {
                    localeId != null -> availableResult(localeId)
                    hasDownloadableModel ->
                        unavailableResult(
                            message =
                                "Android supports this language, but its on-device speech model is not installed yet.",
                            resolvedLocaleId = requestedLocaleId,
                            status = "localeUnavailable",
                        )
                    else ->
                        unavailableResult(
                            message =
                                "On-device speech recognition is unavailable for the current language on this Android device.",
                            resolvedLocaleId = requestedLocaleId,
                            status = "localeUnavailable",
                        )
                }
            result.success(payload)
        }
    }

    private fun resolveSupportedLocaleId(
        localeIds: List<String>,
        onResolved: (String?, Boolean) -> Unit,
    ) {
        val candidates = requestedLocaleIds(localeIds).ifEmpty { listOf(defaultLocaleId()) }
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            // Android 12 exposes on-device recognition but not per-locale
            // support checks, so this remains a best-effort fallback.
            onResolved(candidates.firstOrNull(), false)
            return
        }

        val recognizer = SpeechRecognizer.createOnDeviceSpeechRecognizer(activity)
        var hasDownloadableModel = false

        fun finish(localeId: String?) {
            recognizer.destroy()
            onResolved(localeId, hasDownloadableModel)
        }

        fun checkCandidate(index: Int) {
            if (index >= candidates.size) {
                finish(null)
                return
            }

            val localeId = candidates[index]
            recognizer.checkRecognitionSupport(
                buildRecognizerIntent(localeId),
                activity.mainExecutor,
                object : RecognitionSupportCallback {
                    override fun onSupportResult(recognitionSupport: RecognitionSupport) {
                        if (recognitionSupport.installedOnDeviceLanguages.contains(localeId)) {
                            finish(localeId)
                            return
                        }

                        if (recognitionSupport.supportedOnDeviceLanguages.contains(localeId) ||
                            recognitionSupport.pendingOnDeviceLanguages.contains(localeId)
                        ) {
                            hasDownloadableModel = true
                        }

                        checkCandidate(index + 1)
                    }

                    override fun onError(error: Int) {
                        when (error) {
                            SpeechRecognizer.ERROR_LANGUAGE_NOT_SUPPORTED,
                            SpeechRecognizer.ERROR_LANGUAGE_UNAVAILABLE -> checkCandidate(index + 1)
                            else -> finish(null)
                        }
                    }
                },
            )
        }

        try {
            checkCandidate(0)
        } catch (_: Exception) {
            finish(null)
        }
    }

    private fun requestedLocaleIds(localeIds: List<String>): List<String> {
        return localeIds.map(String::trim).filter(String::isNotEmpty).distinct()
    }

    private fun defaultLocaleId(): String {
        return activity.resources.configuration.locales[0].toLanguageTag()
    }

    private fun availableResult(localeId: String): Map<String, Any?> {
        return mapOf(
            "message" to "Ready for local speech recognition.",
            "resolvedLocaleId" to localeId,
            "status" to "available",
        )
    }

    private fun unavailableResult(
        message: String,
        resolvedLocaleId: String?,
        status: String,
    ): Map<String, Any?> {
        return mapOf(
            "message" to message,
            "resolvedLocaleId" to resolvedLocaleId,
            "status" to status,
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
