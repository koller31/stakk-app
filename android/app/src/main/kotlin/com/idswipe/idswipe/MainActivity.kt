package com.idswipe.idswipe

import android.app.ActivityManager
import android.content.Context
import android.content.ComponentName
import android.nfc.NfcAdapter
import android.nfc.Tag
import android.nfc.cardemulation.CardEmulation
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.idswipe/screen_pinning"
    private val NFC_CHANNEL = "com.idswipe/nfc_badge"

    private val tagReader = NfcTagReader()
    private var pendingNfcResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots, screen recording, and app switcher thumbnails
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onPause() {
        super.onPause()
        stopNfcReaderMode()
        // Clear HCE payload when app backgrounds to prevent pocket-tap attacks
        BadgeHceService.clearPayload()
    }

    private fun stopNfcReaderMode() {
        try {
            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
            nfcAdapter?.disableReaderMode(this)
        } catch (_: Exception) {}

        pendingNfcResult?.error("NFC_CANCELLED", "NFC scan cancelled", null)
        pendingNfcResult = null
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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NFC_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "activateBadge" -> {
                        try {
                            val aid = call.argument<String>("aid")
                            val payload = call.argument<String>("payload")

                            if (aid == null || payload == null) {
                                result.error("INVALID_ARGS", "AID and payload are required", null)
                                return@setMethodCallHandler
                            }

                            // Convert hex payload to bytes
                            BadgeHceService.activePayload = BadgeHceService.hexStringToByteArray(payload)
                            BadgeHceService.activeAid = aid
                            BadgeHceService.isActive = true
                            // Auto-clear payload after 30 seconds
                            BadgeHceService.startTimeout()

                            // Dynamically register AID
                            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
                            if (nfcAdapter != null) {
                                val cardEmulation = CardEmulation.getInstance(nfcAdapter)
                                val componentName = ComponentName(this, BadgeHceService::class.java)
                                cardEmulation.registerAidsForService(
                                    componentName,
                                    "other",
                                    listOf(aid)
                                )
                            }

                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NFC_ERROR", e.message, null)
                        }
                    }
                    "deactivateBadge" -> {
                        try {
                            BadgeHceService.activeAid = null
                            BadgeHceService.activePayload = null
                            BadgeHceService.isActive = false
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NFC_ERROR", e.message, null)
                        }
                    }
                    "isNfcAvailable" -> {
                        try {
                            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
                            result.success(nfcAdapter?.isEnabled ?: false)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "isHceSupported" -> {
                        try {
                            result.success(packageManager.hasSystemFeature("android.hardware.nfc.hce"))
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "startNfcReader" -> {
                        try {
                            val nfcAdapter = NfcAdapter.getDefaultAdapter(this)
                            if (nfcAdapter == null || !nfcAdapter.isEnabled) {
                                result.error("NFC_UNAVAILABLE", "NFC is not available or disabled", null)
                                return@setMethodCallHandler
                            }

                            // Cancel any previous pending scan
                            pendingNfcResult?.error("NFC_CANCELLED", "New scan started", null)
                            pendingNfcResult = result

                            // Temporarily disable HCE so we can read
                            BadgeHceService.isActive = false

                            // Enable reader mode with all NFC type flags
                            // Note: omitting FLAG_READER_SKIP_NDEF_CHECK so NDEF is read
                            val flags = NfcAdapter.FLAG_READER_NFC_A or
                                    NfcAdapter.FLAG_READER_NFC_B or
                                    NfcAdapter.FLAG_READER_NFC_F or
                                    NfcAdapter.FLAG_READER_NFC_V or
                                    NfcAdapter.FLAG_READER_NFC_BARCODE or
                                    NfcAdapter.FLAG_READER_NO_PLATFORM_SOUNDS

                            val extras = Bundle().apply {
                                putInt(NfcAdapter.EXTRA_READER_PRESENCE_CHECK_DELAY, 250)
                            }

                            nfcAdapter.enableReaderMode(
                                this,
                                { tag: Tag ->
                                    // Tag discovered - read it
                                    try {
                                        val tagData = tagReader.readTag(tag)
                                        runOnUiThread {
                                            pendingNfcResult?.success(tagData)
                                            pendingNfcResult = null
                                            // Disable reader mode after successful read
                                            try {
                                                nfcAdapter.disableReaderMode(this)
                                            } catch (_: Exception) {}
                                        }
                                    } catch (e: Exception) {
                                        runOnUiThread {
                                            pendingNfcResult?.error("NFC_READ_ERROR", e.message, null)
                                            pendingNfcResult = null
                                            try {
                                                nfcAdapter.disableReaderMode(this)
                                            } catch (_: Exception) {}
                                        }
                                    }
                                },
                                flags,
                                extras
                            )

                            // Don't call result.success() here - it will be called
                            // when a tag is discovered (async callback)
                        } catch (e: Exception) {
                            pendingNfcResult = null
                            result.error("NFC_ERROR", e.message, null)
                        }
                    }
                    "stopNfcReader" -> {
                        try {
                            stopNfcReaderMode()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("NFC_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
