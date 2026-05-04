// ─────────────────────────────────────────────────────────────────────────────
// AuthUser
// ─────────────────────────────────────────────────────────────────────────────

class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;
  final bool twoFactorEnabled;
  final String language;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.createdAt,
    this.twoFactorEnabled = false,
    this.language = 'fr',
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        twoFactorEnabled: json['two_factor_enabled'] as bool? ?? false,
        language: json['language'] as String? ?? 'fr',
      );

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  String get initials {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LoginResult — sealed union returned by login & verify-email & 2FA
// ─────────────────────────────────────────────────────────────────────────────

sealed class LoginResult {}

// Normal successful login — carries tokens + user
class LoginSuccess extends LoginResult {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  LoginSuccess({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginSuccess.fromJson(Map<String, dynamic> json) {
    final data  = json['data'] as Map<String, dynamic>;
    final token = data['token'] as Map<String, dynamic>;
    return LoginSuccess(
      accessToken:  token['access_token']  as String,
      refreshToken: token['refresh_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

// Login requires 2FA — carries the short-lived 2FA token
class LoginNeeds2FA extends LoginResult {
  final String twoFactorToken;
  LoginNeeds2FA({required this.twoFactorToken});
}

// Login blocked because email not yet verified
class LoginNeedsVerification extends LoginResult {}

// ─────────────────────────────────────────────────────────────────────────────
// RegisterResponse
// ─────────────────────────────────────────────────────────────────────────────

class RegisterResponse {
  final String message;
  final AuthUser user;

  const RegisterResponse({required this.message, required this.user});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        message: json['message'] as String? ?? '',
        user: AuthUser.fromJson(json['data'] as Map<String, dynamic>),
      );
}
