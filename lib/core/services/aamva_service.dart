/// AAMVA (American Association of Motor Vehicle Administrators) Service
/// Handles encoding and decoding of driver's license barcode data
///
/// The PDF417 barcode on the back of a driver's license contains data
/// in a specific format defined by AAMVA. This service helps encode
/// user ID data into that format for scanning.

class AAMVAService {
  /// Generate AAMVA-compliant barcode data from ID card fields
  ///
  /// This creates a PDF417-compatible string that follows the AAMVA
  /// DL/ID Card Design Standard format.
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
    String jurisdictionCode = '636004', // Default Arkansas IIN
  }) {
    // Build the AAMVA data string
    // Header
    final buffer = StringBuffer();

    // Compliance Indicator
    buffer.write('@');
    buffer.write('\n');

    // Data Element Separator
    buffer.write('ANSI ');
    buffer.write(jurisdictionCode); // Issuer Identification Number (IIN)
    buffer.write('08'); // AAMVA Version (08 = 2013)
    buffer.write('01'); // Jurisdiction Version
    buffer.write('02'); // Number of entries
    buffer.write('DL'); // Subfile type (Driver License)
    buffer.write('00410288'); // Offset and length (placeholder)
    buffer.write('ZA03290015'); // Jurisdiction-specific offset

    // Driver License subfile
    buffer.write('DL');

    // DAQ - Customer ID Number (License Number)
    buffer.write('DAQ');
    buffer.write(licenseNumber);
    buffer.write('\n');

    // DCS - Customer Family Name
    buffer.write('DCS');
    buffer.write(lastName.toUpperCase());
    buffer.write('\n');

    // DCT - Customer Given Names (First + Middle)
    buffer.write('DCT');
    buffer.write(firstName.toUpperCase());
    if (middleName != null && middleName.isNotEmpty) {
      buffer.write(',');
      buffer.write(middleName.toUpperCase());
    }
    buffer.write('\n');

    // DAC - Customer First Name
    buffer.write('DAC');
    buffer.write(firstName.toUpperCase());
    buffer.write('\n');

    // DAD - Customer Middle Name
    buffer.write('DAD');
    buffer.write(middleName?.toUpperCase() ?? '');
    buffer.write('\n');

    // DBB - Date of Birth (MMDDYYYY)
    buffer.write('DBB');
    buffer.write(dateOfBirth);
    buffer.write('\n');

    // DBA - Document Expiration Date
    buffer.write('DBA');
    buffer.write(expirationDate);
    buffer.write('\n');

    // DBD - Document Issue Date
    buffer.write('DBD');
    buffer.write(issueDate);
    buffer.write('\n');

    // DAG - Street Address
    buffer.write('DAG');
    buffer.write(address.toUpperCase());
    buffer.write('\n');

    // DAI - City
    buffer.write('DAI');
    buffer.write(city.toUpperCase());
    buffer.write('\n');

    // DAJ - Jurisdiction Code (State)
    buffer.write('DAJ');
    buffer.write(state.toUpperCase());
    buffer.write('\n');

    // DAK - Postal Code
    buffer.write('DAK');
    buffer.write(zipCode);
    buffer.write('\n');

    // DBC - Sex (1=Male, 2=Female)
    if (gender != null) {
      buffer.write('DBC');
      buffer.write(gender);
      buffer.write('\n');
    }

    // DAY - Eye Color
    if (eyeColor != null) {
      buffer.write('DAY');
      buffer.write(eyeColor.toUpperCase());
      buffer.write('\n');
    }

    // DAU - Height
    if (height != null) {
      buffer.write('DAU');
      buffer.write(height);
      buffer.write('\n');
    }

    // DCU - Name Suffix
    if (suffix != null) {
      buffer.write('DCU');
      buffer.write(suffix.toUpperCase());
      buffer.write('\n');
    }

    // DCG - Country (USA)
    buffer.write('DCG');
    buffer.write('USA');
    buffer.write('\n');

    return buffer.toString();
  }

  /// Generate sample AAMVA data for testing/demo purposes
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
    );
  }

  /// Parse fields from OCR text (from scanning the front of ID)
  /// Returns a map of recognized fields
  static Map<String, String> parseFromOCR(String ocrText) {
    final fields = <String, String>{};

    // This is a simplified parser - in production you'd use more
    // sophisticated pattern matching or ML-based extraction

    // Try to find common patterns
    final lines = ocrText.split('\n');

    for (final line in lines) {
      final upperLine = line.toUpperCase().trim();

      // Look for date patterns (MM/DD/YYYY or MM-DD-YYYY)
      final datePattern = RegExp(r'(\d{2})[/-](\d{2})[/-](\d{4})');
      final dateMatch = datePattern.firstMatch(line);
      if (dateMatch != null) {
        // Could be DOB or expiration - need context
        final dateValue =
            '${dateMatch.group(1)}${dateMatch.group(2)}${dateMatch.group(3)}';

        if (upperLine.contains('DOB') ||
            upperLine.contains('BIRTH') ||
            upperLine.contains('BORN')) {
          fields['dateOfBirth'] = dateValue;
        } else if (upperLine.contains('EXP') || upperLine.contains('EXPIRES')) {
          fields['expirationDate'] = dateValue;
        }
      }

      // Look for license number patterns (varies by state)
      final licensePattern = RegExp(r'[A-Z]?\d{6,12}');
      if (upperLine.contains('DL') ||
          upperLine.contains('LIC') ||
          upperLine.contains('NO')) {
        final licMatch = licensePattern.firstMatch(line);
        if (licMatch != null) {
          fields['licenseNumber'] = licMatch.group(0)!;
        }
      }

      // Look for address patterns
      if (RegExp(r'^\d+\s+[A-Z]').hasMatch(upperLine)) {
        fields['address'] = upperLine;
      }

      // Look for state abbreviations
      final statePattern = RegExp(
          r'\b(AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY)\b');
      final stateMatch = statePattern.firstMatch(upperLine);
      if (stateMatch != null) {
        fields['state'] = stateMatch.group(0)!;
      }

      // Look for ZIP codes
      final zipPattern = RegExp(r'\b\d{5}(-\d{4})?\b');
      final zipMatch = zipPattern.firstMatch(line);
      if (zipMatch != null) {
        fields['zipCode'] = zipMatch.group(0)!.substring(0, 5);
      }
    }

    return fields;
  }

  /// Get the Issuer Identification Number (IIN) for a state
  static String getStateIIN(String stateCode) {
    // AAMVA assigns unique IINs to each jurisdiction
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
}

/// Model class to hold parsed ID card data
class IDCardData {
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

  IDCardData({
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
  });

  /// Convert to AAMVA barcode string
  String toAAMVA() {
    return AAMVAService.encodeToAAMVA(
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
      jurisdictionCode: AAMVAService.getStateIIN(state),
    );
  }

  /// Create sample data for testing
  factory IDCardData.sample() {
    return IDCardData(
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
    );
  }
}
