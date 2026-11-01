import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jeap_api_token';
  static const _rememberEmailKey = 'jeap_remember_email';
  static const _rememberMeKey = 'jeap_remember_me';
  static const _baseUrlKey = 'jeap_api_base_url';
  static String? _sessionToken;

  static Future<void> init() async {
    // Accessing the encrypted store here catches device/key-store setup errors
    // before the first authenticated request.
    try {
      await _storage.read(key: _tokenKey);
    } catch (_) {}
  }

  static Future<void> save(String token, {bool persist = true}) async {
    _sessionToken = token;
    if (persist) {
      try {
        await _storage.write(key: _tokenKey, value: token);
      } catch (_) {}
    } else {
      try {
        await _storage.delete(key: _tokenKey);
      } catch (_) {}
    }
  }

  static Future<String?> get() async {
    if (_sessionToken != null) return _sessionToken;
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRememberedEmail(String email, bool remember) async {
    try {
      if (remember) {
        await _storage.write(key: _rememberMeKey, value: 'true');
        await _storage.write(key: _rememberEmailKey, value: email);
      } else {
        await _storage.write(key: _rememberMeKey, value: 'false');
        await _storage.delete(key: _rememberEmailKey);
      }
    } catch (_) {}
  }

  static Future<String?> getRememberedEmail() async {
    try {
      final remember = await _storage.read(key: _rememberMeKey);
      if (remember != 'false') {
        return await _storage.read(key: _rememberEmailKey);
      }
    } catch (_) {}
    return null;
  }

  static Future<bool> isRememberMeEnabled() async {
    try {
      final remember = await _storage.read(key: _rememberMeKey);
      return remember != 'false';
    } catch (_) {
      return true;
    }
  }

  static Future<void> saveBaseUrl(String url) async {
    try {
      await _storage.write(key: _baseUrlKey, value: url);
    } catch (_) {}
  }

  static Future<String?> getBaseUrl() async {
    try {
      return await _storage.read(key: _baseUrlKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearBaseUrl() async {
    try {
      await _storage.delete(key: _baseUrlKey);
    } catch (_) {}
  }

  static Future<void> clear() async {
    _sessionToken = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
  }
}
