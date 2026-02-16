/// Result of an OAuth2 authorization flow
class OAuthResult {
  final String accessToken;
  final String? refreshToken;
  final String? idToken;
  final DateTime? expiresAt;
  final List<String> scopes;

  OAuthResult({
    required this.accessToken,
    this.refreshToken,
    this.idToken,
    this.expiresAt,
    this.scopes = const [],
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}
