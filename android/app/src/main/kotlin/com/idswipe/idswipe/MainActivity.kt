package com.idswipe.idswipe

import android.app.ActivityManager
import android.content.Context
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.idswipe/screen_pinning"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots, screen recording, and app switcher thumbnails
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLockTask" -> {
                        try {
                            startLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", e.message, null)
                        }
                    }
                    "stopLockTask" -> {
                        try {
                            stopLockTask()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", e.message, null)
                        }
                    }
                    "isInLockTaskMode" -> {
                        try {
                            val activityManager =
                                getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                            val lockTaskMode = activityManager.lockTaskModeState
                            val isLocked = lockTaskMode != ActivityManager.LOCK_TASK_MODE_NONE
                            result.success(isLocked)
                        } catch (e: Exception) {
                            result.error("LOCK_TASK_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
