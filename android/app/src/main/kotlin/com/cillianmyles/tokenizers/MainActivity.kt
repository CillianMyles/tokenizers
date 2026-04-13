package com.cillianmyles.tokenizers

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private var localSpeechToTextBridge: LocalSpeechToTextBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        localSpeechToTextBridge = LocalSpeechToTextBridge(
            activity = this,
            messenger = flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (localSpeechToTextBridge?.onRequestPermissionsResult(
                requestCode = requestCode,
                grantResults = grantResults,
            ) == true
        ) {
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    override fun onDestroy() {
        localSpeechToTextBridge?.dispose()
        localSpeechToTextBridge = null
        super.onDestroy()
    }
}
