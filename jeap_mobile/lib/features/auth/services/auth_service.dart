import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/features/auth/models/registration_data.dart';

class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? user;

  const AuthResult({required this.success, required this.message, this.user});
}

class AuthService {
  AuthService({ApiClient? api}) : _api = api ?? const ApiClient();

  final ApiClient _api;

  Future<AuthResult> signInWithGoogle() async {
    if (!_api.baseUrl.startsWith('https://')) {
      return const AuthResult(
        success: false,
        message: 'Google sign-in requires a configured HTTPS JEAP API URL.',
      );
    }
    UserCredential? credential;
    var exchanged = false;
    try {
      final googleUser = await GoogleSignIn(
        serverClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      ).signIn();
      if (googleUser == null) {
        return const AuthResult(success: false, message: 'Sign-in cancelled.');
      }
      final googleTokens = await googleUser.authentication;
      final idToken = googleTokens.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AuthResult(
          success: false,
          message:
              'Google did not return an ID token. Check the OAuth client setup.',
        );
      }
      credential = await FirebaseAuth.instance.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final firebaseIdToken = await credential.user?.getIdToken();
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw const AuthException('Firebase did not return an ID token.');
      }

      final response = await _api.post('/auth/google', {
        'id_token': firebaseIdToken,
      });
      final data = _asMap(response);
      final user = _asMap(data?['user']);
      final token = data?['token'];
      if (token is! String || token.isEmpty || user == null) {
        throw const AuthException(
            'The server returned an invalid sign-in response.');
      }
      if (user['status'] != 'active') {
        throw AuthException(_accountStatusMessage(user['status']));
      }
      await TokenStorage.save(token);
      exchanged = true;
      return AuthResult(success: true, message: 'Logged in.', user: user);
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    } on FirebaseAuthException catch (error) {
      return AuthResult(
        success: false,
        message: error.message ?? 'Google authentication failed.',
      );
    } on PlatformException catch (error) {
      return AuthResult(
        success: false,
        message: error.message ?? 'Google sign-in could not be completed.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (_) {
      return const AuthResult(
        success: false,
        message: 'Google sign-in is not configured. Contact JEAP support.',
      );
    } finally {
      if (!exchanged) {
        if (Firebase.apps.isNotEmpty) {
          await FirebaseAuth.instance.signOut().catchError((_) {});
        }
        await GoogleSignIn().signOut().catchError((_) => null);
      }
    }
  }

  Future<AuthResult> register(RegistrationData data) async {
    try {
      final response = await _api.post('/register', {
        ...data.toJson(),
        'address_line': data.formattedAddress,
        'postal_code': data.zipCode,
      });
      return AuthResult(
        success: true,
        message: _message(response, 'Registration submitted.'),
        user: _asMap(response is Map ? response['user'] : null),
      );
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    }
  }

  Future<AuthResult> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    try {
      final response = await _api.post('/login', {
        'email': email,
        'password': password,
      });
      final data = _asMap(response);
      final token = data?['token'];
      final user = _asMap(data?['user']);
      if (token is! String || token.isEmpty || user == null) {
        return const AuthResult(
          success: false,
          message: 'The server returned an invalid sign-in response.',
        );
      }
      await TokenStorage.save(token, persist: rememberMe);
      return AuthResult(success: true, message: 'Logged in.', user: user);
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    }
  }

  Future<void> logout() async {
    try {
      if (await TokenStorage.get() != null) await _api.post('/logout', {});
    } catch (_) {
      // Clear local credentials even if the server is unreachable.
    } finally {
      await TokenStorage.clear();
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut().catchError((_) {});
      }
      await GoogleSignIn().signOut().catchError((_) => null);
    }
  }

  Future<Map<String, dynamic>?> me() async {
    if (await TokenStorage.get() == null) return null;
    try {
      final response = await _api.get('/me');
      final data = _asMap(response);
      return _asMap(data?['user']);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await TokenStorage.clear();
        return null;
      }
      rethrow;
    }
  }

  Future<AuthResult> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _api.put('/profile', data);
      return AuthResult(
        success: true,
        message: _message(response, 'Profile updated.'),
        user: _asMap(_asMap(response)?['user']),
      );
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    }
  }

  Future<AuthResult> changePassword(String current, String newPass) async {
    try {
      final response = await _api.put('/password', {
        'current_password': current,
        'password': newPass,
        'password_confirmation': newPass,
      });
      return AuthResult(
          success: true, message: _message(response, 'Password changed.'));
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    }
  }

  static Map<String, dynamic>? _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;

  static String _message(dynamic value, String fallback) {
    final message = _asMap(value)?['message'];
    return message is String ? message : fallback;
  }

  static String _accountStatusMessage(dynamic status) => switch (status) {
        'pending' => 'Your account is pending administrator approval.',
        'rejected' => 'Your account application has been rejected.',
        'suspended' =>
          'Your account has been suspended. Please contact support.',
        _ => 'This JEAP account is not active.',
      };
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}
