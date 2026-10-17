import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase client values are supplied at build time. They are public app
/// identifiers; server credentials must never be passed to the mobile app.
class JeapFirebaseOptions {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _senderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty &&
      _projectId.isNotEmpty &&
      _senderId.isNotEmpty &&
      (kIsWeb
          ? _webAppId.isNotEmpty
          : _androidAppId.isNotEmpty || _iosAppId.isNotEmpty);

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError('Firebase client configuration is missing.');
    }
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: _apiKey,
        appId: _webAppId,
        messagingSenderId: _senderId,
        projectId: _projectId,
        authDomain: '$_projectId.firebaseapp.com',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (_androidAppId.isEmpty) {
          throw StateError('Firebase Android app ID is missing.');
        }
        return const FirebaseOptions(
          apiKey: _apiKey,
          appId: _androidAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
        );
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (_iosAppId.isEmpty) {
          throw StateError('Firebase iOS app ID is missing.');
        }
        return const FirebaseOptions(
          apiKey: _apiKey,
          appId: _iosAppId,
          messagingSenderId: _senderId,
          projectId: _projectId,
          iosBundleId: _iosBundleId,
        );
      default:
        throw UnsupportedError(
            'JEAP Google sign-in is supported on Android, iOS, and web.');
    }
  }
}
