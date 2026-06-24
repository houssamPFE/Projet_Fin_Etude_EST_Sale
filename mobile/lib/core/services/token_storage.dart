import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kAccessKey  = 'nexora_access_token';
const _kRefreshKey = 'nexora_refresh_token';

class TokenStorage {
  const TokenStorage();

  // Do NOT use encryptedSharedPreferences: true.
  // EncryptedSharedPreferences has a known bug on Android emulators and some OEM
  // ROMs (Android 6-9) where it throws a crypto exception on the first read after
  // a cold start / force-kill, making stored tokens unreadable.
  // The default AndroidOptions uses the raw Android Keystore + AES directly,
  // which is stable across all supported Android versions and emulators.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
    ),
  );

  Future<void> saveTokens(String access, String refresh) async {
    try {
      await _storage.write(key: _kAccessKey, value: access);
      await _storage.write(key: _kRefreshKey, value: refresh);
    } catch (_) {}

    // Backup to SharedPreferences for absolute reliability across emulator/device restarts
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kAccessKey, access);
      await prefs.setString(_kRefreshKey, refresh);
    } catch (_) {}
  }

  /// Returns the short-lived access token (15 min TTL).
  /// May return null if expired storage reset occurred — callers should
  /// fall back to [readRefreshToken] before concluding the session is gone.
  Future<String?> read() async {
    try {
      final secureVal = await _storage.read(key: _kAccessKey);
      if (secureVal != null) return secureVal;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kAccessKey);
    } catch (_) {
      return null;
    }
  }

  /// Returns the long-lived refresh token (30 day TTL).
  /// Presence of this token means the user has an active session.
  Future<String?> readRefreshToken() async {
    try {
      final secureVal = await _storage.read(key: _kRefreshKey);
      if (secureVal != null) return secureVal;
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kRefreshKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.delete(key: _kAccessKey);
      await _storage.delete(key: _kRefreshKey);
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kAccessKey);
      await prefs.remove(_kRefreshKey);
    } catch (_) {}
  }
}

final tokenStorageProvider = Provider<TokenStorage>((_) => const TokenStorage());
