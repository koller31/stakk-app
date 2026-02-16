/// Configuration for initiating a new business OAuth connection
class BusinessConnectionConfig {
  final String providerName;
  final String clientId;
  final String? discoveryUrl;
  final String? issuerUrl;
  final String? authEndpoint;
  final String? tokenEndpoint;
  final String badgeApiEndpoint;
  final List<String> scopes;
  final String? logoUrl;

  BusinessConnectionConfig({
    required this.providerName,
    required this.clientId,
    this.discoveryUrl,
    this.issuerUrl,
    this.authEndpoint,
    this.tokenEndpoint,
    required this.badgeApiEndpoint,
    this.scopes = const ['openid', 'profile'],
    this.logoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'providerName': providerName,
      'clientId': clientId,
      'discoveryUrl': discoveryUrl,
      'issuerUrl': issuerUrl,
      'authEndpoint': authEndpoint,
      'tokenEndpoint': tokenEndpoint,
      'badgeApiEndpoint': badgeApiEndpoint,
      'scopes': scopes,
      'logoUrl': logoUrl,
    };
  }

  factory BusinessConnectionConfig.fromJson(Map<String, dynamic> json) {
    return BusinessConnectionConfig(
      providerName: json['providerName'] as String,
      clientId: json['clientId'] as String,
      discoveryUrl: json['discoveryUrl'] as String?,
      issuerUrl: json['issuerUrl'] as String?,
      authEndpoint: json['authEndpoint'] as String?,
      tokenEndpoint: json['tokenEndpoint'] as String?,
      badgeApiEndpoint: json['badgeApiEndpoint'] as String,
      scopes: (json['scopes'] as List<dynamic>?)?.cast<String>() ??
          const ['openid', 'profile'],
      logoUrl: json['logoUrl'] as String?,
    );
  }
}
