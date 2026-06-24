import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'atma_access_token';
  static String? _memoryToken;
  static bool _useMemoryStorage = false;

  static void useMemoryStorageForTesting([bool enabled = true]) {
    _useMemoryStorage = enabled;
    if (!enabled) {
      _memoryToken = null;
    }
  }

  static Future<void> saveToken(String token) {
    if (_useMemoryStorage) {
      _memoryToken = token;
      return Future.value();
    }
    return _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() {
    if (_useMemoryStorage) {
      return Future.value(_memoryToken);
    }
    return _storage.read(key: _tokenKey);
  }

  static Future<void> clearToken() {
    if (_useMemoryStorage) {
      _memoryToken = null;
      return Future.value();
    }
    return _storage.delete(key: _tokenKey);
  }
}
