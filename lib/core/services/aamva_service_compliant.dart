import 'package:flutter/foundation.dart';

/// AAMVA Compliant Service - 2016 Standard (Version 08)
///
/// This implementation follows the AAMVA DL/ID Card Design Standard
/// Version 8 (2016) for PDF417 barcode generation.
///
/// Reference: AAMVA DL/ID Card Design Standard
/// Version: 8.0 (2013/2016)
///
/// Key Compliance Features:
/// - Proper file header with calculated offsets
/// - Correct compliance indicator
/// - All mandatory data elements
/// - Proper field terminators
/// - Jurisdiction-specific formatting

class AAMVAServiceCompliant {
  /// Generate fully AAMVA-compliant barcode data
  ///
  /// This creates a PDF417-compatible string that police scanners
  /// can read and decode properly.
  static String encodeToAAMVA({
    required String firstName,
    required String lastName,
    String? middleName,
    required String dateOfBirth, // MMDDYYYY format
    required String expirationDate, // MMDDYYYY format
    required String issueDate, // MMDDYYYY format
    required String licenseNumber,
    required String address,
    required String city,
    required String state, // 2-letter code
    required String zipCode,
    String? gender, // 1 = Male, 2 = Female
    String? eyeColor, // BRO, BLU, GRN, etc.
    String? height, // Format: "069 in" or "175 cm"
    String? suffix, // JR, SR, II, III, etc.
    String? restriction, // NONE or restriction codes
    String? vehicleClass, // C, D, M, etc.
    String jurisdictionCode = '636004', // Default Arkansas IIN
  }) {
    // Build the subfile data first so we can calculate its length
    final subfileData = _buildSubfileData(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dateOfBirth,
      expirationDate: expirationDate,
      issueDate: issueDate,
      licenseNumber: licenseNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      gender: gender,
      eyeColor: eyeColor,
      height: height,
      suffix: suffix,
      restriction: restriction,
      vehicleClass: vehicleClass,
    );

    // Calculate header components
    final String versionNumber = '08'; // AAMVA 2016 standard
    final String jurisdictionVersion = '01'; // Version 1
    final String numberOfEntries = '01'; // One subfile (DL)

    // Build header WITHOUT subfile designator initially
    final headerWithoutDesignator =
        'ANSI $jurisdictionCode$versionNumber$jurisdictionVersion$numberOfEntries';

    // Calculate offsets
    // Header length + 10 characters for subfile designator = offset to subfile data
    final headerLength = headerWithoutDesignator.length + 10; // +10 for subfile designator line
    final subfileOffset = headerLength.toString().padLeft(4, '0');
    final subfileLength = subfileData.length.toString().padLeft(4, '0');

    // Now build complete header with subfile designator
    final String subfileDesignator = 'DL$subfileOffset$subfileLength';

    // Assemble final barcode data
    final buffer = StringBuffer();

    // 1. Compliance Indicator (@ followed by line feed)
    buffer.write('@');
    buffer.write('\n');

    // 2. File Header
    buffer.write(headerWithoutDesignator);

    // 3. Subfile Designator (DL + offset + length)
    buffer.write(subfileDesignator);
    buffer.write('\r'); // CR after designator

    // 4. Subfile Data
    buffer.write(subfileData);

    return buffer.toString();
  }

  /// Build the subfile data section with all required fields
  static String _buildSubfileData({
    required String firstName,
    required String lastName,
    String? middleName,
    required String dateOfBirth,
    required String expirationDate,
    required String issueDate,
    required String licenseNumber,
    required String address,
    required String city,
    required String state,
    required String zipCode,
    String? gender,
    String? eyeColor,
    String? height,
    String? suffix,
    String? restriction,
    String? vehicleClass,
  }) {
    final buffer = StringBuffer();

    // MANDATORY FIELDS (Required by AAMVA standard)

    // DCS - Customer Family Name (Last Name)
    buffer.write('DCS${lastName.toUpperCase()}\r');

    // DAC - Customer First Name
    buffer.write('DAC${firstName.toUpperCase()}\r');

    // DAD - Customer Middle Name (can be empty)
    buffer.write('DAD${middleName?.toUpperCase() ?? ''}\r');

    // DBB - Date of Birth (MMDDYYYY)
    buffer.write('DBB$dateOfBirth\r');

    // DBA - Document Expiration Date (MMDDYYYY)
    buffer.write('DBA$expirationDate\r');

    // DAQ - Customer ID Number (License Number)
    buffer.write('DAQ$licenseNumber\r');

    // DAG - Street Address
    buffer.write('DAG${address.toUpperCase()}\r');

    // DAI - City
    buffer.write('DAI${city.toUpperCase()}\r');

    // DAJ - Jurisdiction Code (State)
    buffer.write('DAJ${state.toUpperCase()}\r');

    // DAK - Postal Code (ZIP)
    buffer.write('DAK$zipCode\r');

    // DCF - Document Discriminator (Unique ID for this license)
    // This is typically a combination of state code + unique number
    final documentDiscriminator = '${state.toUpperCase()}$licenseNumber';
    buffer.write('DCF$documentDiscriminator\r');

    // DCG - Country (USA)
    buffer.write('DCGUSA\r');

    // DDE - Family Name Truncation (N = Not truncated, T = Truncated)
    buffer.write('DDEN\r');

    // DDF - First Name Truncation
    buffer.write('DDFN\r');

    // DDG - Middle Name Truncation
    buffer.write('DDGN\r');

    // OPTIONAL BUT RECOMMENDED FIELDS

    // DBD - Document Issue Date
    buffer.write('DBD$issueDate\r');

    // DBC - Sex (1=Male, 2=Female)
    if (gender != null) {
      buffer.write('DBC$gender\r');
    } else {
      buffer.write('DBC1\r'); // Default to male if not specified
    }

    // DAY - Eye Color
    if (eyeColor != null) {
      buffer.write('DAY${eyeColor.toUpperCase()}\r');
    }

    // DAU - Height
    if (height != null) {
      buffer.write('DAU$height\r');
    }

    // DCU - Name Suffix
    if (suffix != null) {
      buffer.write('DCU${suffix.toUpperCase()}\r');
    }

    // DCA - Jurisdiction-specific vehicle class
    if (vehicleClass != null) {
      buffer.write('DCA${vehicleClass.toUpperCase()}\r');
    } else {
      buffer.write('DCAD\r'); // Default to Class D (regular driver)
    }

    // DCB - Jurisdiction-specific restriction codes
    if (restriction != null) {
      buffer.write('DCB${restriction.toUpperCase()}\r');
    } else {
      buffer.write('DCBNONE\r'); // No restrictions
    }

    // DCD - Jurisdiction-specific endorsement codes
    buffer.write('DCDNONE\r'); // No endorsements

    // DAZ - Hair Color (if available)
    buffer.write('DAZBRO\r'); // Default to brown

    // DCE - Physical Description Weight Range (0=up to 70kg, 1=70-99kg, etc.)
    buffer.write('DCE1\r'); // Default to 70-99kg range

    // DCL - Race / Ethnicity (Optional, many states omit this)
    // Omitting as per modern privacy practices

    // DAW - Weight (pounds or kg)
    // Omitting if not provided

    return buffer.toString();
  }

  /// Generate sample AAMVA data for testing with police scanners
  static String generateSampleData() {
    return encodeToAAMVA(
      firstName: 'JOHN',
      lastName: 'DOE',
      middleName: 'MICHAEL',
      dateOfBirth: '01151990', // Jan 15, 1990
      expirationDate: '01152028', // Jan 15, 2028
      issueDate: '01152024', // Jan 15, 2024
      licenseNumber: '123456789',
      address: '123 MAIN STREET',
      city: 'LITTLE ROCK',
      state: 'AR',
      zipCode: '72201',
      gender: '1',
      eyeColor: 'BRO',
      height: '070 in',
      vehicleClass: 'D',
      restriction: 'NONE',
    );
  }

  /// Get the Issuer Identification Number (IIN) for a state
  /// These are officially assigned by AAMVA
  static String getStateIIN(String stateCode) {
    const stateIINs = {
      'AL': '636033',
      'AK': '636059',
      'AZ': '636026',
      'AR': '636004', // Arkansas
      'CA': '636014',
      'CO': '636020',
      'CT': '636006',
      'DE': '636011',
      'FL': '636010',
      'GA': '636055',
      'HI': '636047',
      'ID': '636050',
      'IL': '636035',
      'IN': '636037',
      'IA': '636018',
      'KS': '636022',
      'KY': '636046',
      'LA': '636007',
      'ME': '636041',
      'MD': '636003',
      'MA': '636002',
      'MI': '636032',
      'MN': '636038',
      'MS': '636051',
      'MO': '636030',
      'MT': '636008',
      'NE': '636054',
      'NV': '636049',
      'NH': '636039',
      'NJ': '636036',
      'NM': '636009',
      'NY': '636001',
      'NC': '636004',
      'ND': '636034',
      'OH': '636023',
      'OK': '636058',
      'OR': '636029',
      'PA': '636025',
      'RI': '636052',
      'SC': '636005',
      'SD': '636042',
      'TN': '636053',
      'TX': '636015',
      'UT': '636040',
      'VT': '636024',
      'VA': '636000',
      'WA': '636045',
      'WV': '636061',
      'WI': '636031',
      'WY': '636060',
    };

    return stateIINs[stateCode.toUpperCase()] ?? '636004'; // Default to AR
  }

  /// Validate AAMVA data format
  /// Returns true if data appears to be compliant
  static bool validateFormat(String aamvaData) {
    // Check for compliance indicator
    if (!aamvaData.startsWith('@\n')) {
      return false;
    }

    // Check for ANSI header
    if (!aamvaData.contains('ANSI ')) {
      return false;
    }

    // Check for required fields
    final requiredFields = ['DCS', 'DAC', 'DBB', 'DBA', 'DAQ', 'DAG', 'DAI', 'DAJ', 'DAK'];
    for (final field in requiredFields) {
      if (!aamvaData.contains(field)) {
        return false;
      }
    }

    return true;
  }

  /// Debug: Print the barcode data structure (only runs in debug mode)
  static void debugPrintStructure(String aamvaData) {
    assert(() {
      debugPrint('===== AAMVA BARCODE STRUCTURE =====');
      debugPrint('Total Length: ${aamvaData.length} characters');
      debugPrint('');

      final lines = aamvaData.split('\r');
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].replaceAll('\n', '\\n');
        if (i == 0) {
          debugPrint('COMPLIANCE INDICATOR: "$line"');
        } else if (line.startsWith('ANSI')) {
          debugPrint('FILE HEADER: "$line"');
        } else if (line.startsWith('DL')) {
          debugPrint('SUBFILE DESIGNATOR: "$line"');
        } else if (line.length > 3) {
          final fieldId = line.substring(0, 3);
          final fieldValue = line.substring(3);
          debugPrint('  $fieldId: "$fieldValue"');
        }
      }
      debugPrint('===================================');
      return true;
    }());
  }
}

/// Model class for ID card data with AAMVA compliance
class IDCardDataCompliant {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String dateOfBirth;
  final String expirationDate;
  final String issueDate;
  final String licenseNumber;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String? gender;
  final String? eyeColor;
  final String? height;
  final String? suffix;
  final String? restriction;
  final String? vehicleClass;

  IDCardDataCompliant({
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.dateOfBirth,
    required this.expirationDate,
    required this.issueDate,
    required this.licenseNumber,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    this.gender,
    this.eyeColor,
    this.height,
    this.suffix,
    this.restriction,
    this.vehicleClass,
  });

  /// Convert to AAMVA compliant barcode string
  String toAAMVA() {
    return AAMVAServiceCompliant.encodeToAAMVA(
      firstName: firstName,
      lastName: lastName,
      middleName: middleName,
      dateOfBirth: dateOfBirth,
      expirationDate: expirationDate,
      issueDate: issueDate,
      licenseNumber: licenseNumber,
      address: address,
      city: city,
      state: state,
      zipCode: zipCode,
      gender: gender,
      eyeColor: eyeColor,
      height: height,
      suffix: suffix,
      restriction: restriction,
      vehicleClass: vehicleClass,
      jurisdictionCode: AAMVAServiceCompliant.getStateIIN(state),
    );
  }

  /// Create sample data for testing with police scanners
  factory IDCardDataCompliant.sample() {
    return IDCardDataCompliant(
      firstName: 'JOHN',
      lastName: 'DOE',
      middleName: 'MICHAEL',
      dateOfBirth: '01151990',
      expirationDate: '01152028',
      issueDate: '01152024',
      licenseNumber: '123456789',
      address: '123 MAIN STREET',
      city: 'LITTLE ROCK',
      state: 'AR',
      zipCode: '72201',
      gender: '1',
      eyeColor: 'BRO',
      height: '070 in',
      vehicleClass: 'D',
      restriction: 'NONE',
    );
  }
}
