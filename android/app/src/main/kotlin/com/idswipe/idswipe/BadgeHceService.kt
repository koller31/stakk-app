package com.idswipe.idswipe

import android.nfc.cardemulation.HostApduService
import android.os.Bundle
import android.os.Handler
import android.os.Looper

class BadgeHceService : HostApduService() {
    companion object {
        var activeAid: String? = null
        var activePayload: ByteArray? = null
        var isActive: Boolean = false

        private val SELECT_APDU_HEADER = byteArrayOf(
            0x00.toByte(), 0xA4.toByte(), 0x04.toByte(), 0x00.toByte()
        )
        private val SUCCESS_SW = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val FAILURE_SW = byteArrayOf(0x6F.toByte(), 0x00.toByte())

        private val handler = Handler(Looper.getMainLooper())
        private var timeoutRunnable: Runnable? = null
        private const val PAYLOAD_TIMEOUT_MS = 30_000L // 30 seconds

        fun hexStringToByteArray(hex: String): ByteArray {
            val cleanHex = hex.replace(" ", "").replace(":", "")
            val len = cleanHex.length
            val data = ByteArray(len / 2)
            var i = 0
            while (i < len) {
                data[i / 2] = ((Character.digit(cleanHex[i], 16) shl 4) + Character.digit(cleanHex[i + 1], 16)).toByte()
                i += 2
            }
            return data
        }

        /** Clear the active payload and zero the byte array. */
        fun clearPayload() {
            activePayload?.fill(0) // Zero out the bytes before releasing
            activePayload = null
            activeAid = null
            isActive = false
            cancelTimeout()
        }

        /** Start auto-clear timeout. Payload is cleared after 30 seconds. */
        fun startTimeout() {
            cancelTimeout()
            timeoutRunnable = Runnable { clearPayload() }
            handler.postDelayed(timeoutRunnable!!, PAYLOAD_TIMEOUT_MS)
        }

        /** Cancel any pending auto-clear timeout. */
        fun cancelTimeout() {
            timeoutRunnable?.let { handler.removeCallbacks(it) }
            timeoutRunnable = null
        }
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (!isActive || activePayload == null) {
            return FAILURE_SW
        }

        if (commandApdu.size >= 4 &&
            commandApdu[0] == SELECT_APDU_HEADER[0] &&
            commandApdu[1] == SELECT_APDU_HEADER[1]) {
            return activePayload!! + SUCCESS_SW
        }

        return FAILURE_SW
    }

    override fun onDeactivated(reason: Int) {
        clearPayload()
    }
}
