package com.example.pet

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var notificationTapChannel: MethodChannel? = null
    private var processExitChannel: MethodChannel? = null
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
        processExitChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            processExitChannelName,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLastExitReason" -> result.success(lastExitReason())
                    else -> result.notImplemented()
                }
            }
        }
    }

    /**
     * Reports how the previous process died, straight from the system.
     *
     * Unlike the Dart-side sentinel this is authoritative: the OS records
     * REASON_LOW_MEMORY for kills the app can never observe itself, because it
     * is SIGKILLed without running any handler. Only available on API 30+.
     */
    private fun lastExitReason(): Map<String, Any?>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return null
        }
        return try {
            val manager =
                getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
                    ?: return null
            val info: ApplicationExitInfo =
                manager.getHistoricalProcessExitReasons(packageName, 0, 1)
                    .firstOrNull() ?: return null
            mapOf(
                "reason" to info.reason,
                "reason_name" to reasonName(info.reason),
                "description" to info.description,
                "timestamp" to info.timestamp,
                "importance" to info.importance,
                // Was the process user-visible when it died? A foreground kill
                // is what the user experiences as the app vanishing.
                "was_foreground" to
                    (info.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE),
                "pss_kb" to info.pss,
                "rss_kb" to info.rss,
            )
        } catch (error: Exception) {
            null
        }
    }

    private fun reasonName(reason: Int): String = when (reason) {
        ApplicationExitInfo.REASON_EXIT_SELF -> "exit_self"
        ApplicationExitInfo.REASON_SIGNALED -> "signaled"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "low_memory"
        ApplicationExitInfo.REASON_CRASH -> "crash"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "crash_native"
        ApplicationExitInfo.REASON_ANR -> "anr"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "initialization_failure"
        ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "permission_change"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "excessive_resource_usage"
        ApplicationExitInfo.REASON_USER_REQUESTED -> "user_requested"
        ApplicationExitInfo.REASON_USER_STOPPED -> "user_stopped"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "dependency_died"
        ApplicationExitInfo.REASON_OTHER -> "other"
        else -> "unknown"
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
        private const val processExitChannelName = "pet/process_exit_reasons"
    }
}
