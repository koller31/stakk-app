package com.idswipe.idswipe

import android.nfc.cardemulation.HostApduService
import android.os.Bundle

class BadgeHceService : HostApduService() {
    companion object {
        var activeAid: String? = null
        var activePayload: ByteArray? = null
        var isActive: Boolean = false

        // Standard SELECT APDU header
        private val SELECT_APDU_HEADER = byteArrayOf(
            0x00.toByte(), // CLA
            0xA4.toByte(), // INS (SELECT)
            0x04.toByte(), // P1 (by name)
            0x00.toByte()  // P2
        )

        private val SUCCESS_SW = byteArrayOf(0x90.toByte(), 0x00.toByte())
        private val FAILURE_SW = byteArrayOf(0x6F.toByte(), 0x00.toByte())

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
    }

    override fun processCommandApdu(commandApdu: ByteArray, extras: Bundle?): ByteArray {
        if (!isActive || activePayload == null) {
            return FAILURE_SW
        }

        // Check if this is a SELECT command
        if (commandApdu.size >= 4 &&
            commandApdu[0] == SELECT_APDU_HEADER[0] &&
            commandApdu[1] == SELECT_APDU_HEADER[1]) {
            // Return payload + success status word
            return activePayload!! + SUCCESS_SW
        }

        return FAILURE_SW
    }

    override fun onDeactivated(reason: Int) {
        // Called when HCE is deactivated
    }
}
