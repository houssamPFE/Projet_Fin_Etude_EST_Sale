import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'nexora_access_token';

class TokenStorage {
  const TokenStorage();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> save(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<String?> read() => _storage.read(key: _kTokenKey);

  Future<void> delete() => _storage.delete(key: _kTokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>((_) => const TokenStorage());
