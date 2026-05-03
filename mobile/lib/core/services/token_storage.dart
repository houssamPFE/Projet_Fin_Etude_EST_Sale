import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessKey  = 'nexora_access_token';
const _kRefreshKey = 'nexora_refresh_token';

class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _kAccessKey, value: access);
    await _storage.write(key: _kRefreshKey, value: refresh);
  }

  Future<String?> read() => _storage.read(key: _kAccessKey);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshKey);

  Future<void> deleteAll() async {
    await _storage.delete(key: _kAccessKey);
    await _storage.delete(key: _kRefreshKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((_) => const TokenStorage());
