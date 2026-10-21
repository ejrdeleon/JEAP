import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/core/storage/auth_session.dart';
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
    var exchanged = false;
    GoogleSignInAccount? googleUser;
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId:
            const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID').isNotEmpty
                ? const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID')
                : null,
      );
      googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return const AuthResult(success: false, message: 'Sign-in cancelled.');
      }
      final googleTokens = await googleUser.authentication;
      final idToken = googleTokens.idToken;
      final accessToken = googleTokens.accessToken;

      if ((idToken == null || idToken.isEmpty) &&
          (accessToken == null || accessToken.isEmpty)) {
        return const AuthResult(
          success: false,
          message: 'Google authentication tokens could not be retrieved.',
        );
      }

      // If Firebase is configured, link credential
      if (Firebase.apps.isNotEmpty && idToken != null && idToken.isNotEmpty) {
        try {
          await FirebaseAuth.instance.signInWithCredential(
            GoogleAuthProvider.credential(
              idToken: idToken,
              accessToken: accessToken,
            ),
          );
        } catch (_) {}
      }

      final nameParts = (googleUser.displayName ?? '').trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Google';
      final lastName =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

      final response = await _api.post('/auth/google', {
        if (idToken != null && idToken.isNotEmpty) 'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
        'email': googleUser.email,
        'first_name': firstName,
        'last_name': lastName,
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
      await AuthSession.instance.setUser(user);
      exchanged = true;
      return AuthResult(success: true, message: 'Logged in.', user: user);
    } on ApiException catch (error) {
      return AuthResult(success: false, message: error.firstError);
    } on PlatformException catch (error) {
      return AuthResult(
        success: false,
        message: error.message ?? 'Google sign-in could not be completed.',
      );
    } on AuthException catch (error) {
      return AuthResult(success: false, message: error.message);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Google sign-in error: ${e.toString()}',
      );
    } finally {
      if (!exchanged) {
        if (Firebase.apps.isNotEmpty) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
        }
        try {
          await GoogleSignIn().signOut();
        } catch (_) {}
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
      await AuthSession.instance.setUser(user);
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
      await AuthSession.instance.clear();
      if (Firebase.apps.isNotEmpty) {
        await FirebaseAuth.instance.signOut().catchError((_) {});
      }
      await GoogleSignIn().signOut().catchError((_) => null);
    }
  }

  Future<Map<String, dynamic>?> me() async {
    if (await TokenStorage.get() == null) {
      await AuthSession.instance.clear();
      return null;
    }
    try {
      final response = await _api.get('/me');
      final data = _asMap(response);
      final user = _asMap(data?['user']);
      await AuthSession.instance.setUser(user);
      return user;
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await TokenStorage.clear();
        await AuthSession.instance.clear();
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
