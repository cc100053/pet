package com.example.pet

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationTapChannel: MethodChannel? = null
    private var pendingNotificationTap: Map<String, String>? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingNotificationTap = extractNotificationTap(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        notificationTapChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationTapChannelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "consumeInitialNotificationTap" -> {
                        result.success(pendingNotificationTap)
                        pendingNotificationTap = null
                    }

                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val tapPayload = extractNotificationTap(intent) ?: return
        pendingNotificationTap = tapPayload
        notificationTapChannel?.invokeMethod("notificationTap", tapPayload)
    }

    private fun extractNotificationTap(intent: Intent?): Map<String, String>? {
        intent ?: return null
        val roomId = intent.getStringExtra("room_id")?.trim().orEmpty()
        if (roomId.isEmpty()) {
            return null
        }
        val payload = mutableMapOf("room_id" to roomId)
        intent.getStringExtra("message_id")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { payload["message_id"] = it }
        intent.getStringExtra("message_kind")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { payload["message_kind"] = it }
        intent.getStringExtra("message_type")
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let { payload["message_type"] = it }
        return payload
    }

    companion object {
        private const val notificationTapChannelName = "pet/notification_taps"
    }
}
