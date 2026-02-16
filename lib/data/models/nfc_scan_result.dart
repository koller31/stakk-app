/// Model representing data captured from scanning a physical NFC card/tag.
/// Parses the native tag data map from NfcTagReader.kt into typed fields.
class NfcScanResult {
  final String uid;
  final List<String> techList;
  final String? atqa;
  final int? sak;
  final String? historicalBytes;
  final String? hiLayerResponse;
  final String? applicationData;
  final String? protocolInfo;
  final String? ndefType;
  final int? ndefMaxSize;
  final bool? ndefIsWritable;
  final List<NdefRecord>? ndefRecords;
  final String? mifareType;
  final int? mifareSize;
  final int? mifareSectorCount;
  final int? mifareBlockCount;
  final Map<String, String>? mifareSectors;
  final String? ultralightType;
  final Map<String, String>? ultralightPages;
  final bool? isExtendedLengthApduSupported;
  final int? maxTransceiveLength;

  NfcScanResult({
    required this.uid,
    required this.techList,
    this.atqa,
    this.sak,
    this.historicalBytes,
    this.hiLayerResponse,
    this.applicationData,
    this.protocolInfo,
    this.ndefType,
    this.ndefMaxSize,
    this.ndefIsWritable,
    this.ndefRecords,
    this.mifareType,
    this.mifareSize,
    this.mifareSectorCount,
    this.mifareBlockCount,
    this.mifareSectors,
    this.ultralightType,
    this.ultralightPages,
    this.isExtendedLengthApduSupported,
    this.maxTransceiveLength,
  });

  /// Parse the native map returned from NfcTagReader.kt via MethodChannel
  factory NfcScanResult.fromNativeMap(Map<dynamic, dynamic> map) {
    // Parse NDEF records
    List<NdefRecord>? ndefRecords;
    final rawRecords = map['ndefRecords'];
    if (rawRecords is List) {
      ndefRecords = rawRecords.map((r) {
        final m = Map<String, dynamic>.from(r as Map);
        return NdefRecord(
          tnf: m['tnf'] as int? ?? 0,
          type: m['type'] as String?,
          typeString: m['typeString'] as String?,
          payload: m['payload'] as String?,
          text: m['text'] as String?,
          uri: m['uri'] as String?,
        );
      }).toList();
    }

    // Parse MIFARE sectors
    Map<String, String>? mifareSectors;
    final rawSectors = map['mifareSectors'];
    if (rawSectors is Map) {
      mifareSectors = Map<String, String>.from(rawSectors);
    }

    // Parse Ultralight pages
    Map<String, String>? ultralightPages;
    final rawPages = map['ultralightPages'];
    if (rawPages is Map) {
      ultralightPages = Map<String, String>.from(rawPages);
    }

    // Parse tech list
    final rawTechList = map['techList'];
    final techList = rawTechList is List
        ? rawTechList.map((t) => t.toString()).toList()
        : <String>[];

    return NfcScanResult(
      uid: map['uid'] as String? ?? '',
      techList: techList,
      atqa: map['atqa'] as String?,
      sak: map['sak'] as int?,
      historicalBytes: map['historicalBytes'] as String?,
      hiLayerResponse: map['hiLayerResponse'] as String?,
      applicationData: map['applicationData'] as String?,
      protocolInfo: map['protocolInfo'] as String?,
      ndefType: map['ndefType'] as String?,
      ndefMaxSize: map['ndefMaxSize'] as int?,
      ndefIsWritable: map['ndefIsWritable'] as bool?,
      ndefRecords: ndefRecords,
      mifareType: map['mifareType'] as String?,
      mifareSize: map['mifareSize'] as int?,
      mifareSectorCount: map['mifareSectorCount'] as int?,
      mifareBlockCount: map['mifareBlockCount'] as int?,
      mifareSectors: mifareSectors,
      ultralightType: map['ultralightType'] as String?,
      ultralightPages: ultralightPages,
      isExtendedLengthApduSupported:
          map['isExtendedLengthApduSupported'] as bool?,
      maxTransceiveLength: map['maxTransceiveLength'] as int?,
    );
  }

  /// Human-readable card type derived from SAK value
  String get cardTypeDescription {
    if (sak != null) {
      switch (sak!) {
        case 0x08:
          return 'MIFARE Classic 1K';
        case 0x09:
          return 'MIFARE Mini';
        case 0x10:
          return 'MIFARE Plus 2K';
        case 0x11:
          return 'MIFARE Plus 4K';
        case 0x18:
          return 'MIFARE Classic 4K';
        case 0x20:
          if (techList.any((t) => t.contains('IsoDep'))) {
            return 'MIFARE DESFire';
          }
          return 'MIFARE Plus';
        case 0x28:
          return 'Smart MX (Javacard)';
        case 0x38:
          return 'Smart MX (Javacard)';
        case 0x98:
          return 'Gemplus MPCOS';
        case 0x00:
          if (ultralightType != null) {
            return 'MIFARE $ultralightType';
          }
          return 'MIFARE Ultralight';
      }
    }
    if (ultralightType != null) return 'MIFARE $ultralightType';
    if (mifareType != null) return 'MIFARE $mifareType';
    if (ndefType != null) return 'NDEF Tag';
    if (techList.any((t) => t.contains('NfcB'))) return 'NFC-B Tag';
    if (techList.any((t) => t.contains('IsoDep'))) return 'ISO-DEP Card';
    return 'NFC Tag';
  }

  /// Picks the best available data for HCE emulation.
  /// Priority: NDEF text/payload > MIFARE sector data > Ultralight pages
  ///           > historical bytes > UID
  String get hcePayload {
    // 1. NDEF text or URI payload
    if (ndefRecords != null && ndefRecords!.isNotEmpty) {
      for (final record in ndefRecords!) {
        if (record.text != null && record.text!.isNotEmpty) {
          return _stringToHex(record.text!);
        }
        if (record.uri != null && record.uri!.isNotEmpty) {
          return _stringToHex(record.uri!);
        }
        if (record.payload != null && record.payload!.isNotEmpty) {
          return record.payload!;
        }
      }
    }

    // 2. MIFARE Classic sector data (first non-empty sector)
    if (mifareSectors != null && mifareSectors!.isNotEmpty) {
      for (final entry in mifareSectors!.entries) {
        if (entry.value.isNotEmpty) {
          return entry.value;
        }
      }
    }

    // 3. Ultralight page data
    if (ultralightPages != null && ultralightPages!.isNotEmpty) {
      final allPages = StringBuffer();
      for (final entry in ultralightPages!.entries) {
        allPages.write(entry.value);
      }
      if (allPages.isNotEmpty) return allPages.toString();
    }

    // 4. Historical bytes
    if (historicalBytes != null && historicalBytes!.isNotEmpty) {
      return historicalBytes!;
    }

    // 5. Fallback: UID itself
    return uid;
  }

  /// Generates a proprietary AID from F0 prefix + UID bytes.
  /// F0 prefix = proprietary AIDs (not registered with payment networks).
  String get hceAid {
    // F0 + up to 6 bytes of UID (AID max 16 bytes, but keep it short)
    final uidClean = uid.replaceAll(RegExp(r'[^0-9A-Fa-f]'), '');
    final uidBytes =
        uidClean.length > 12 ? uidClean.substring(0, 12) : uidClean;
    return 'F0$uidBytes';
  }

  /// Converts this scan result to a map for storage in WalletCardModel.extractedData
  Map<String, dynamic> toExtractedData() {
    return {
      'scanType': 'nfc',
      'cardType': cardTypeDescription,
      'uid': uid,
      'techList': techList,
      if (atqa != null) 'atqa': atqa,
      if (sak != null) 'sak': sak,
      if (historicalBytes != null) 'historicalBytes': historicalBytes,
      if (ndefType != null) 'ndefType': ndefType,
      if (ndefRecords != null)
        'ndefRecords': ndefRecords!
            .map((r) => {
                  'tnf': r.tnf,
                  if (r.typeString != null) 'type': r.typeString,
                  if (r.text != null) 'text': r.text,
                  if (r.uri != null) 'uri': r.uri,
                  if (r.payload != null) 'payload': r.payload,
                })
            .toList(),
      if (mifareType != null) 'mifareType': mifareType,
      if (mifareSize != null) 'mifareSize': mifareSize,
      if (mifareSectorCount != null) 'readableSectors': mifareSectors?.length,
      if (ultralightType != null) 'ultralightType': ultralightType,
      if (ultralightPages != null) 'readablePages': ultralightPages?.length,
      'scanDate': DateTime.now().toIso8601String(),
    };
  }

  /// Short tech summary for display
  String get techSummary {
    final shortNames = techList
        .map((t) => t.split('.').last)
        .where((t) => t != 'NdefFormatable')
        .toList();
    return shortNames.join(', ');
  }

  /// Whether NDEF data was captured
  bool get hasNdef => ndefRecords != null && ndefRecords!.isNotEmpty;

  /// Whether MIFARE sector data was captured
  bool get hasMifareData => mifareSectors != null && mifareSectors!.isNotEmpty;

  /// Whether Ultralight page data was captured
  bool get hasUltralightData =>
      ultralightPages != null && ultralightPages!.isNotEmpty;

  static String _stringToHex(String input) {
    return input.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }
}

/// Represents a single NDEF record parsed from a tag
class NdefRecord {
  final int tnf;
  final String? type;
  final String? typeString;
  final String? payload;
  final String? text;
  final String? uri;

  NdefRecord({
    required this.tnf,
    this.type,
    this.typeString,
    this.payload,
    this.text,
    this.uri,
  });
}
