import 'package:hive/hive.dart';

part 'business_connection_model.g.dart';

@HiveType(typeId: 4)
class BusinessConnectionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String providerName;

  @HiveField(2)
  final String? issuerUrl;

  @HiveField(3)
  final String clientId;

  @HiveField(4)
  final String? discoveryUrl;

  @HiveField(5)
  final String? authEndpoint;

  @HiveField(6)
  final String? tokenEndpoint;

  @HiveField(7)
  final String badgeApiEndpoint;

  @HiveField(8)
  final String? accessToken;

  @HiveField(9)
  final String? refreshToken;

  @HiveField(10)
  final DateTime? tokenExpiry;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime updatedAt;

  @HiveField(13)
  final String? logoUrl;

  @HiveField(14)
  final List<String> scopes;

  BusinessConnectionModel({
    required this.id,
    required this.providerName,
    this.issuerUrl,
    required this.clientId,
    this.discoveryUrl,
    this.authEndpoint,
    this.tokenEndpoint,
    required this.badgeApiEndpoint,
    this.accessToken,
    this.refreshToken,
    this.tokenExpiry,
    required this.createdAt,
    required this.updatedAt,
    this.logoUrl,
    this.scopes = const [],
  });

  bool get isTokenExpired {
    if (tokenExpiry == null || accessToken == null) return true;
    return DateTime.now().isAfter(tokenExpiry!);
  }

  bool get hasValidToken => accessToken != null && !isTokenExpired;

  BusinessConnectionModel copyWith({
    String? id,
    String? providerName,
    String? issuerUrl,
    String? clientId,
    String? discoveryUrl,
    String? authEndpoint,
    String? tokenEndpoint,
    String? badgeApiEndpoint,
    String? accessToken,
    String? refreshToken,
    DateTime? tokenExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? logoUrl,
    List<String>? scopes,
  }) {
    return BusinessConnectionModel(
      id: id ?? this.id,
      providerName: providerName ?? this.providerName,
      issuerUrl: issuerUrl ?? this.issuerUrl,
      clientId: clientId ?? this.clientId,
      discoveryUrl: discoveryUrl ?? this.discoveryUrl,
      authEndpoint: authEndpoint ?? this.authEndpoint,
      tokenEndpoint: tokenEndpoint ?? this.tokenEndpoint,
      badgeApiEndpoint: badgeApiEndpoint ?? this.badgeApiEndpoint,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenExpiry: tokenExpiry ?? this.tokenExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      logoUrl: logoUrl ?? this.logoUrl,
      scopes: scopes ?? this.scopes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'providerName': providerName,
      'issuerUrl': issuerUrl,
      'clientId': clientId,
      'discoveryUrl': discoveryUrl,
      'authEndpoint': authEndpoint,
      'tokenEndpoint': tokenEndpoint,
      'badgeApiEndpoint': badgeApiEndpoint,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenExpiry': tokenExpiry?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'logoUrl': logoUrl,
      'scopes': scopes,
    };
  }

  factory BusinessConnectionModel.fromJson(Map<String, dynamic> json) {
    return BusinessConnectionModel(
      id: json['id'] as String,
      providerName: json['providerName'] as String,
      issuerUrl: json['issuerUrl'] as String?,
      clientId: json['clientId'] as String,
      discoveryUrl: json['discoveryUrl'] as String?,
      authEndpoint: json['authEndpoint'] as String?,
      tokenEndpoint: json['tokenEndpoint'] as String?,
      badgeApiEndpoint: json['badgeApiEndpoint'] as String,
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenExpiry: json['tokenExpiry'] != null
          ? DateTime.parse(json['tokenExpiry'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      logoUrl: json['logoUrl'] as String?,
      scopes: (json['scopes'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}
