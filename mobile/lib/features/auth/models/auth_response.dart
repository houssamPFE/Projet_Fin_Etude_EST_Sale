class AuthUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.createdAt,
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

// Login response — backend shape:
// { message, data: { user: {...}, token: { access_token, refresh_token, ... } } }
class LoginResponse {
  final String accessToken;
  final AuthUser user;

  const LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final token = data['token'] as Map<String, dynamic>;
    return LoginResponse(
      accessToken: token['access_token'] as String,
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }
}

// Register response — backend shape (no token, email verification required):
// { message, data: { ...user fields... } }
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
