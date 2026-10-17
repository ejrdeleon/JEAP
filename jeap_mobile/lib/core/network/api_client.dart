import 'dart:convert';
import 'dart:io';
import 'package:jeap_mobile/core/storage/token_storage.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';

class ApiClient {
  final String baseUrl;

  const ApiClient({
    this.baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://jeap.store/api/v1',
    ),
  });

  Future<Map<String, String>> get _headers async => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (await TokenStorage.get() case final token?)
          'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);
  Future<dynamic> postImage(String path, String filePath) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final file = File(filePath);
      final filename = file.uri.pathSegments.last.replaceAll('"', '');
      final extension = filename.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
      final boundary = '----JEAP${DateTime.now().microsecondsSinceEpoch}';
      final request = await client.openUrl('POST', Uri.parse('$baseUrl$path'));
      final headers = await _headers;
      for (final entry in headers.entries) {
        if (entry.key.toLowerCase() != 'content-type') {
          request.headers.set(entry.key, entry.value);
        }
      }
      request.headers.set(
        'Content-Type',
        'multipart/form-data; boundary=$boundary',
      );
      request.add(utf8.encode(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="proof"; filename="$filename"\r\n'
        'Content-Type: $contentType\r\n\r\n',
      ));
      request.add(await file.readAsBytes());
      request.add(utf8.encode('\r\n--$boundary--\r\n'));

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();
      dynamic json;
      try {
        json = jsonDecode(raw);
      } catch (_) {
        json = null;
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: (json is Map ? json['message'] as String? : null) ??
            'Request failed (${response.statusCode})',
        errors: json is Map ? json['errors'] as Map<String, dynamic>? : null,
      );
    } on SocketException {
      throw const ApiException(message: 'No connection to server');
    } finally {
      client.close();
    }
  }
  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _send('PUT', path, body: body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  Future<dynamic> _send(String method, String path,
      {Map<String, dynamic>? body}) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);

    try {
      final uri = Uri.parse('$baseUrl$path');
      final request = await client.openUrl(method, uri);

      (await _headers).forEach((k, v) => request.headers.set(k, v));

      if (body != null) request.write(jsonEncode(body));

      final response = await request.close();
      final raw = await response.transform(utf8.decoder).join();

      dynamic json;
      try {
        json = jsonDecode(raw);
      } catch (_) {
        json = null;
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json;
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: (json is Map ? json['message'] as String? : null) ??
            'Request failed (${response.statusCode})',
        errors: json is Map ? json['errors'] as Map<String, dynamic>? : null,
      );
    } on SocketException {
      throw const ApiException(message: 'No connection to server');
    } finally {
      client.close();
    }
  }
}
