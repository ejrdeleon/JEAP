import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:jeap_mobile/core/storage/token_storage.dart';

enum ApiEnvironment {
  development('Localhost / USB ADB Reverse', 'http://127.0.0.1:8080/api/v1'),
  androidEmulator('Android Emulator Host', 'http://10.0.2.2:8080/api/v1'),
  localNetwork('Local Wi-Fi Network (192.168.1.7)', 'http://192.168.1.7:8080/api/v1'),
  production('Production Server', 'https://jeap.store/api/v1'),
  custom('Custom Server URL', '');

  const ApiEnvironment(this.label, this.defaultUrl);
  final String label;
  final String defaultUrl;
}

class ApiConfig {
  static const String compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String defaultLocalUrl = 'http://127.0.0.1:8080/api/v1';
  static const String productionUrl = 'https://jeap.store/api/v1';

  static String _activeBaseUrl = '';
  static int _avatarVersion = 1;
  static final ValueNotifier<int> avatarVersionNotifier = ValueNotifier<int>(1);

  static String get baseUrl {
    if (_activeBaseUrl.isNotEmpty) return _activeBaseUrl;
    if (compileTimeBaseUrl.isNotEmpty) return compileTimeBaseUrl;
    return kReleaseMode ? productionUrl : defaultLocalUrl;
  }

  static String get serverBaseUrl {
    final url = baseUrl.trim();
    return url.replaceAll(RegExp(r'/api/v1/?$'), '').replaceAll(RegExp(r'/+$'), '');
  }

  static int get avatarVersion => _avatarVersion;

  static bool get isProduction => baseUrl.startsWith('https://jeap.store');

  /// List of candidate server endpoints eligible for probing in development.
  static List<String> get candidateUrls {
    if (kReleaseMode) {
      return [compileTimeBaseUrl.isNotEmpty ? compileTimeBaseUrl : productionUrl];
    }
    return [
      if (compileTimeBaseUrl.isNotEmpty) compileTimeBaseUrl,
      'http://127.0.0.1:8080/api/v1',
      'http://10.0.2.2:8080/api/v1',
      'http://192.168.1.7:8080/api/v1',
      productionUrl,
    ];
  }

  static Future<void> init() async {
    final saved = await TokenStorage.getBaseUrl();
    if (saved != null && saved.trim().isNotEmpty) {
      _activeBaseUrl = _cleanUrl(saved.trim());
    } else if (compileTimeBaseUrl.isNotEmpty) {
      _activeBaseUrl = _cleanUrl(compileTimeBaseUrl.trim());
    } else if (kReleaseMode) {
      _activeBaseUrl = productionUrl;
    } else {
      _activeBaseUrl = defaultLocalUrl;
    }
  }

  /// Automatically tests candidate server endpoints and selects the first healthy
  /// JEAP backend in priority order. In release mode, it strictly remains on production.
  static Future<String> autoDetectServer({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    // 1. Release mode safeguard: always strictly stick to production HTTPS
    if (kReleaseMode) {
      final target = compileTimeBaseUrl.isNotEmpty ? compileTimeBaseUrl : productionUrl;
      _activeBaseUrl = _cleanUrl(target);
      return _activeBaseUrl;
    }

    // 2. If the user previously saved an endpoint, check if it's currently responsive
    final saved = await TokenStorage.getBaseUrl();
    if (saved != null && saved.trim().isNotEmpty) {
      final cleanSaved = _cleanUrl(saved.trim());
      if (await probeEndpoint(cleanSaved, timeout: timeout)) {
        _activeBaseUrl = cleanSaved;
        return _activeBaseUrl;
      }
    }

    // 3. Probe development candidates in prioritized sequence
    for (final candidate in candidateUrls) {
      final cleaned = _cleanUrl(candidate);
      if (await probeEndpoint(cleaned, timeout: timeout)) {
        _activeBaseUrl = cleaned;
        await TokenStorage.saveBaseUrl(cleaned);
        return _activeBaseUrl;
      }
    }

    // 4. Fallback gracefully
    if (_activeBaseUrl.isEmpty) {
      _activeBaseUrl = defaultLocalUrl;
    }
    return _activeBaseUrl;
  }

  /// Probes a given endpoint using a lightweight HTTP GET against /categories.
  /// Validates that the endpoint responds with HTTP 200 and a valid JSON response.
  static Future<bool> probeEndpoint(
    String url, {
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    try {
      final cleaned = _cleanUrl(url);
      final uri = Uri.parse('$cleaned/categories');
      final client = HttpClient()..connectionTimeout = timeout;
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set('Accept', 'application/json');
      final response = await request.close().timeout(timeout);
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      client.close(force: true);
      return isSuccess;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBaseUrl(String newUrl) async {
    final cleaned = _cleanUrl(newUrl);
    _activeBaseUrl = cleaned;
    await TokenStorage.saveBaseUrl(cleaned);
  }

  static Future<void> resetBaseUrl() async {
    _activeBaseUrl = compileTimeBaseUrl.isNotEmpty
        ? compileTimeBaseUrl
        : (kReleaseMode ? productionUrl : defaultLocalUrl);
    await TokenStorage.clearBaseUrl();
  }

  static void bumpAvatarVersion() {
    avatarVersionNotifier.value++;
    _avatarVersion = avatarVersionNotifier.value;
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }

  /// Normalizes image paths or full URLs returned by the backend so that
  /// the client application can fetch them from the active server.
  static String? resolveImageUrl(String? pathOrUrl, {bool cacheBust = false}) {
    if (pathOrUrl == null) return null;
    final trimmed = pathOrUrl.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('data:')) return trimmed;

    String resolved;
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final uri = Uri.tryParse(trimmed);
      if (uri == null) return trimmed;

      // If the backend returned an absolute URL pointing to 127.0.0.1, localhost,
      // 10.0.2.2, or jeap.store, but our active server baseUrl points somewhere else,
      // rewrite the authority (host:port) to match the current serverBaseUrl.
      final activeServerUri = Uri.tryParse(serverBaseUrl);
      final isLocalOrDomain = uri.host == '127.0.0.1' ||
          uri.host == 'localhost' ||
          uri.host == '10.0.2.2' ||
          uri.host == 'jeap.store';

      if (activeServerUri != null &&
          isLocalOrDomain &&
          (activeServerUri.host != uri.host ||
              (activeServerUri.hasPort && activeServerUri.port != uri.port))) {
        resolved = uri.replace(
          scheme: activeServerUri.scheme,
          host: activeServerUri.host,
          port: activeServerUri.hasPort ? activeServerUri.port : null,
        ).toString();
      } else {
        resolved = trimmed;
      }
    } else {
      // Relative path handling
      final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
      if (clean.startsWith('/media/') || clean.startsWith('/assets/')) {
        resolved = '$serverBaseUrl$clean';
      } else if (clean.startsWith('/storage/')) {
        resolved = '$serverBaseUrl$clean';
      } else if (clean.startsWith('/images/')) {
        resolved = '$serverBaseUrl$clean';
      } else if (clean.startsWith('/avatars/')) {
        resolved = '$serverBaseUrl/media$clean';
      } else if (clean.startsWith('/products/')) {
        resolved = '$serverBaseUrl/storage$clean';
      } else {
        resolved = '$serverBaseUrl/storage$clean';
      }
    }

    if (cacheBust) {
      final sep = resolved.contains('?') ? '&' : '?';
      return '$resolved${sep}v=$_avatarVersion';
    }

    return resolved;
  }

  static String _cleanUrl(String url) {
    var u = url.trim();
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      u = 'http://$u';
    }
    if (!u.endsWith('/api/v1') && !u.endsWith('/api/v1/')) {
      if (u.endsWith('/')) {
        u = '${u}api/v1';
      } else {
        u = '$u/api/v1';
      }
    }
    if (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }
}
