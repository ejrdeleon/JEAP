class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? errors;

  const ApiException({required this.message, this.statusCode, this.errors});

  /// Returns the first Laravel validation error message if present.
  String get firstError {
    if (errors == null || errors!.isEmpty) return message;
    final first = errors!.values.first;
    if (first is List && first.isNotEmpty) return first.first.toString();
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
