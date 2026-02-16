/// Badge profile data returned from a business badge API
class BadgeProfile {
  final String employeeName;
  final String? title;
  final String? department;
  final String? employeeId;
  final String companyName;
  final String? companyLogoUrl;
  final String? cardImageUrl;
  final String? nfcAid;
  final String? nfcPayload;
  final Map<String, dynamic>? additionalData;

  BadgeProfile({
    required this.employeeName,
    this.title,
    this.department,
    this.employeeId,
    required this.companyName,
    this.companyLogoUrl,
    this.cardImageUrl,
    this.nfcAid,
    this.nfcPayload,
    this.additionalData,
  });

  factory BadgeProfile.fromJson(Map<String, dynamic> json) {
    return BadgeProfile(
      employeeName: json['employeeName'] as String? ??
          json['employee_name'] as String? ??
          json['name'] as String? ??
          'Unknown',
      title: json['title'] as String?,
      department: json['department'] as String?,
      employeeId: json['employeeId'] as String? ??
          json['employee_id'] as String?,
      companyName: json['companyName'] as String? ??
          json['company_name'] as String? ??
          json['company'] as String? ??
          'Unknown Company',
      companyLogoUrl: json['companyLogoUrl'] as String? ??
          json['company_logo_url'] as String? ??
          json['logo_url'] as String?,
      cardImageUrl: json['cardImageUrl'] as String? ??
          json['card_image_url'] as String? ??
          json['badge_image_url'] as String?,
      nfcAid: json['nfcAid'] as String? ??
          json['nfc_aid'] as String?,
      nfcPayload: json['nfcPayload'] as String? ??
          json['nfc_payload'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>? ??
          json['additional_data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employeeName': employeeName,
      'title': title,
      'department': department,
      'employeeId': employeeId,
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'cardImageUrl': cardImageUrl,
      'nfcAid': nfcAid,
      'nfcPayload': nfcPayload,
      'additionalData': additionalData,
    };
  }
}
