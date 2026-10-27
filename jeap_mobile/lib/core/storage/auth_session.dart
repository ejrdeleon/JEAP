import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _userKey = 'jeap_cached_user';
  static const _storage = FlutterSecureStorage();

  final ValueNotifier<Map<String, dynamic>?> userNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  Map<String, dynamic>? get currentUser => userNotifier.value;

  bool get isSeller {
    final user = currentUser;
    if (user == null) return false;
    if (user['is_seller'] == true) return true;
    final role = user['role']?.toString().toLowerCase();
    if (role == 'seller') return true;
    final roles = user['roles'];
    if (roles is List &&
        roles.any((r) => r.toString().toLowerCase() == 'seller')) {
      return true;
    }
    return false;
  }

  bool get isRider {
    final user = currentUser;
    if (user == null) return false;
    final role = user['role']?.toString().toLowerCase();
    if (role == 'rider' || role == 'courier') return true;
    final roles = user['roles'];
    if (roles is List &&
        roles.any((r) =>
            r.toString().toLowerCase() == 'rider' ||
            r.toString().toLowerCase() == 'courier')) {
      return true;
    }
    return false;
  }

  String get displayName {
    final user = currentUser;
    if (user == null) return 'JEAP User';
    final name = user['name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final first = user['first_name']?.toString() ?? '';
    final last = user['last_name']?.toString() ?? '';
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : 'JEAP User';
  }

  String get email => currentUser?['email']?.toString() ?? '';

  String? get avatarUrl {
    final url = currentUser?['avatar_url']?.toString();
    if (url != null && url.trim().isNotEmpty) return url.trim();
    return null;
  }

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          userNotifier.value = decoded;
        }
      }
    } catch (_) {}
  }

  Future<void> setUser(Map<String, dynamic>? user) async {
    userNotifier.value = user;
    try {
      if (user != null) {
        await _storage.write(key: _userKey, value: jsonEncode(user));
      } else {
        await _storage.delete(key: _userKey);
      }
    } catch (_) {}
  }

  Future<void> clear() async {
    userNotifier.value = null;
    try {
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }
}
