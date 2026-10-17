import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jeap_api_token';
  static String? _sessionToken;

  static Future<void> init() async {
    // Accessing the encrypted store here catches device/key-store setup errors
    // before the first authenticated request.
    await _storage.read(key: _tokenKey);
  }

  static Future<void> save(String token, {bool persist = true}) async {
    _sessionToken = token;
    if (persist) {
      await _storage.write(key: _tokenKey, value: token);
    } else {
      await _storage.delete(key: _tokenKey);
    }
  }

  static Future<String?> get() async =>
      _sessionToken ?? await _storage.read(key: _tokenKey);

  static Future<void> clear() async {
    _sessionToken = null;
    await _storage.delete(key: _tokenKey);
  }
}
