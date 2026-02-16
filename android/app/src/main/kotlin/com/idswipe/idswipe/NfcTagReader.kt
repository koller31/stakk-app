package com.idswipe.idswipe

import android.nfc.Tag
import android.nfc.tech.*
import android.util.Log

/**
 * Utility that extracts all readable data from an NFC tag.
 * Handles: NfcA, NfcB, IsoDep, Ndef, MifareClassic, MifareUltralight
 */
class NfcTagReader {

    companion object {
        private const val TAG = "NfcTagReader"

        // MIFARE Classic default keys
        private val KEY_DEFAULT = byteArrayOf(
            0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte(),
            0xFF.toByte(), 0xFF.toByte(), 0xFF.toByte()
        )
    }

    /**
     * Read all available data from an NFC tag and return as a map
     * suitable for passing back to Flutter via MethodChannel.
     */
    fun readTag(tag: Tag): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()

        // UID is always available
        result["uid"] = tag.id.toHexString()
        result["techList"] = tag.techList.toList()

        // Read each available technology
        for (tech in tag.techList) {
            try {
                when (tech) {
                    NfcA::class.java.name -> readNfcA(tag, result)
                    NfcB::class.java.name -> readNfcB(tag, result)
                    IsoDep::class.java.name -> readIsoDep(tag, result)
                    Ndef::class.java.name -> readNdef(tag, result)
                    MifareClassic::class.java.name -> readMifareClassic(tag, result)
                    MifareUltralight::class.java.name -> readMifareUltralight(tag, result)
                }
            } catch (e: Exception) {
                Log.w(TAG, "Error reading $tech: ${e.message}")
                result["error_$tech"] = e.message
            }
        }

        return result
    }

    private fun readNfcA(tag: Tag, result: MutableMap<String, Any?>) {
        val nfcA = NfcA.get(tag) ?: return
        try {
            nfcA.connect()
            result["atqa"] = nfcA.atqa.toHexString()
            result["sak"] = nfcA.sak.toInt()
            result["maxTransceiveLength"] = nfcA.maxTransceiveLength
        } finally {
            try { nfcA.close() } catch (_: Exception) {}
        }
    }

    private fun readNfcB(tag: Tag, result: MutableMap<String, Any?>) {
        val nfcB = NfcB.get(tag) ?: return
        try {
            nfcB.connect()
            result["applicationData"] = nfcB.applicationData?.toHexString()
            result["protocolInfo"] = nfcB.protocolInfo?.toHexString()
            result["maxTransceiveLength"] = nfcB.maxTransceiveLength
        } finally {
            try { nfcB.close() } catch (_: Exception) {}
        }
    }

    private fun readIsoDep(tag: Tag, result: MutableMap<String, Any?>) {
        val isoDep = IsoDep.get(tag) ?: return
        try {
            isoDep.connect()
            result["historicalBytes"] = isoDep.historicalBytes?.toHexString()
            result["hiLayerResponse"] = isoDep.hiLayerResponse?.toHexString()
            result["maxTransceiveLength"] = isoDep.maxTransceiveLength
            result["isExtendedLengthApduSupported"] = isoDep.isExtendedLengthApduSupported
        } finally {
            try { isoDep.close() } catch (_: Exception) {}
        }
    }

    private fun readNdef(tag: Tag, result: MutableMap<String, Any?>) {
        val ndef = Ndef.get(tag) ?: return
        try {
            ndef.connect()
            result["ndefType"] = ndef.type
            result["ndefMaxSize"] = ndef.maxSize
            result["ndefIsWritable"] = ndef.isWritable

            val ndefMessage = ndef.cachedNdefMessage ?: ndef.ndefMessage
            if (ndefMessage != null) {
                val records = mutableListOf<Map<String, Any?>>()
                for (record in ndefMessage.records) {
                    val recordMap = mutableMapOf<String, Any?>()
                    recordMap["tnf"] = record.tnf.toInt()
                    recordMap["type"] = record.type?.toHexString()
                    recordMap["typeString"] = String(record.type ?: byteArrayOf())
                    recordMap["payload"] = record.payload?.toHexString()

                    // Try to extract text payload
                    if (record.tnf == android.nfc.NdefRecord.TNF_WELL_KNOWN) {
                        try {
                            val payload = record.payload
                            if (payload != null && payload.isNotEmpty()) {
                                // Text record: first byte is status (encoding + lang length)
                                val typeStr = String(record.type ?: byteArrayOf())
                                if (typeStr == "T") {
                                    val langLength = (payload[0].toInt() and 0x3F)
                                    if (payload.size > 1 + langLength) {
                                        recordMap["text"] = String(
                                            payload,
                                            1 + langLength,
                                            payload.size - 1 - langLength,
                                            Charsets.UTF_8
                                        )
                                    }
                                } else if (typeStr == "U") {
                                    // URI record
                                    val prefixes = arrayOf(
                                        "", "http://www.", "https://www.", "http://",
                                        "https://", "tel:", "mailto:"
                                    )
                                    val prefixIndex = payload[0].toInt() and 0xFF
                                    val prefix = if (prefixIndex < prefixes.size) prefixes[prefixIndex] else ""
                                    recordMap["uri"] = prefix + String(
                                        payload, 1, payload.size - 1, Charsets.UTF_8
                                    )
                                }
                            }
                        } catch (e: Exception) {
                            Log.w(TAG, "Error parsing NDEF text: ${e.message}")
                        }
                    }

                    records.add(recordMap)
                }
                result["ndefRecords"] = records
            }
        } finally {
            try { ndef.close() } catch (_: Exception) {}
        }
    }

    private fun readMifareClassic(tag: Tag, result: MutableMap<String, Any?>) {
        val mifare = MifareClassic.get(tag) ?: return
        try {
            mifare.connect()
            result["mifareType"] = when (mifare.type) {
                MifareClassic.TYPE_CLASSIC -> "Classic"
                MifareClassic.TYPE_PLUS -> "Plus"
                MifareClassic.TYPE_PRO -> "Pro"
                else -> "Unknown"
            }
            result["mifareSize"] = mifare.size
            result["mifareSectorCount"] = mifare.sectorCount
            result["mifareBlockCount"] = mifare.blockCount

            // Try to read sectors with default key
            val sectors = mutableMapOf<String, String>()
            for (i in 0 until mifare.sectorCount) {
                try {
                    if (mifare.authenticateSectorWithKeyA(i, KEY_DEFAULT)) {
                        val firstBlock = mifare.sectorToBlock(i)
                        val blockCount = mifare.getBlockCountInSector(i)
                        val sectorData = StringBuilder()
                        for (b in firstBlock until firstBlock + blockCount) {
                            try {
                                val blockData = mifare.readBlock(b)
                                sectorData.append(blockData.toHexString())
                            } catch (_: Exception) {
                                // Skip unreadable blocks
                            }
                        }
                        if (sectorData.isNotEmpty()) {
                            sectors["sector_$i"] = sectorData.toString()
                        }
                    }
                } catch (_: Exception) {
                    // Sector not accessible with default key
                }
            }
            if (sectors.isNotEmpty()) {
                result["mifareSectors"] = sectors
            }
        } finally {
            try { mifare.close() } catch (_: Exception) {}
        }
    }

    private fun readMifareUltralight(tag: Tag, result: MutableMap<String, Any?>) {
        val ultralight = MifareUltralight.get(tag) ?: return
        try {
            ultralight.connect()
            result["ultralightType"] = when (ultralight.type) {
                MifareUltralight.TYPE_ULTRALIGHT -> "Ultralight"
                MifareUltralight.TYPE_ULTRALIGHT_C -> "Ultralight C"
                else -> "Unknown"
            }

            // Read pages (4 bytes each, readPages returns 4 pages = 16 bytes)
            val pages = mutableMapOf<String, String>()
            // Ultralight has ~16 pages, Ultralight C has ~48
            val maxPage = if (ultralight.type == MifareUltralight.TYPE_ULTRALIGHT_C) 44 else 16
            var page = 0
            while (page < maxPage) {
                try {
                    val data = ultralight.readPages(page)
                    if (data != null && data.isNotEmpty()) {
                        pages["page_$page"] = data.toHexString()
                    }
                    page += 4 // readPages reads 4 pages at a time
                } catch (_: Exception) {
                    break // Hit protected area
                }
            }
            if (pages.isNotEmpty()) {
                result["ultralightPages"] = pages
            }
        } finally {
            try { ultralight.close() } catch (_: Exception) {}
        }
    }

    // Extension to convert ByteArray to hex string
    private fun ByteArray.toHexString(): String {
        return joinToString("") { "%02X".format(it) }
    }
}
