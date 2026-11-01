import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jeap_mobile/core/network/api_config.dart';

class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _userKey = 'jeap_cached_user';
  static const _storage = FlutterSecureStorage();

  final ValueNotifier<Map<String, dynamic>?> userNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);
  final ValueNotifier<bool> isGuestNotifier = ValueNotifier<bool>(false);

  Map<String, dynamic>? get currentUser => userNotifier.value;
  bool get isGuest => isGuestNotifier.value;
  bool get isAuthenticated => currentUser != null && !isGuest;

  bool get isSeller {
    if (isGuest) return false;
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
    if (isGuest) return false;
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
    if (isGuest) return 'Guest User';
    final user = currentUser;
    if (user == null) return 'JEAP User';
    final name = user['name']?.toString();
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final first = user['first_name']?.toString() ?? '';
    final last = user['last_name']?.toString() ?? '';
    final combined = '$first $last'.trim();
    return combined.isNotEmpty ? combined : 'JEAP User';
  }

  String get email => isGuest ? '' : (currentUser?['email']?.toString() ?? '');

  String? get avatarUrl {
    if (isGuest) return null;
    final url = currentUser?['avatar_url']?.toString();
    return ApiConfig.resolveImageUrl(url);
  }

  void setGuest(bool value) {
    isGuestNotifier.value = value;
    if (value) {
      userNotifier.value = null;
    }
  }

  Future<void> init() async {
    try {
      final raw = await _storage.read(key: _userKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          userNotifier.value = decoded;
          isGuestNotifier.value = false;
        }
      }
    } catch (_) {}
  }

  Future<void> setUser(Map<String, dynamic>? user) async {
    userNotifier.value = user;
    if (user != null) {
      isGuestNotifier.value = false;
    }
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
    isGuestNotifier.value = false;
    try {
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }
}
