import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jeap_api_token';
  static const _rememberEmailKey = 'jeap_remember_email';
  static const _rememberMeKey = 'jeap_remember_me';
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

  static Future<void> saveRememberedEmail(String email, bool remember) async {
    if (remember) {
      await _storage.write(key: _rememberMeKey, value: 'true');
      await _storage.write(key: _rememberEmailKey, value: email);
    } else {
      await _storage.write(key: _rememberMeKey, value: 'false');
      await _storage.delete(key: _rememberEmailKey);
    }
  }

  static Future<String?> getRememberedEmail() async {
    final remember = await _storage.read(key: _rememberMeKey);
    if (remember != 'false') {
      return await _storage.read(key: _rememberEmailKey);
    }
    return null;
  }

  static Future<bool> isRememberMeEnabled() async {
    final remember = await _storage.read(key: _rememberMeKey);
    return remember != 'false';
  }

  static Future<void> clear() async {
    _sessionToken = null;
    await _storage.delete(key: _tokenKey);
  }
}
