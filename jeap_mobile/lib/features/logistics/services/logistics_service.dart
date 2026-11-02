import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/features/logistics/models/logistics_parcel.dart';

class LogisticsService {
  final ApiClient _client;

  LogisticsService({ApiClient? client}) : _client = client ?? const ApiClient();

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final res = await _client.get('/logistics/dashboard');
      if (res is Map && res['success'] == true) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (_) {}
    return null;
  }

  Future<LogisticsParcel?> getParcel(String identifier) async {
    try {
      final res = await _client.get('/logistics/parcels/$identifier');
      if (res is Map && res['success'] == true) {
        return LogisticsParcel.fromJson(
            Map<String, dynamic>.from(res['data'] as Map));
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> scanParcel({
    required String identifier,
    required String action,
    String? destinationHub,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'identifier': identifier,
        'action': action,
        if (destinationHub != null) 'destination_hub': destinationHub,
        if (notes != null) 'notes': notes,
      };
      final res = await _client.post('/logistics/scan', body);
      if (res is Map && res['success'] == true) {
        return {
          'success': true,
          'message': res['message'] ?? 'Parcel scanned successfully',
          'data': res['data'],
        };
      }
      return {
        'success': false,
        'message': (res is Map ? res['message'] : null) ?? 'Failed to process parcel scan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error during scan: $e',
      };
    }
  }

  Future<List<LogisticsActivity>> getAuditLog() async {
    try {
      final res = await _client.get('/logistics/audit-log');
      if (res is Map && res['success'] == true) {
        final list = res['data'] as List?;
        if (list != null) {
          return list
              .whereType<Map>()
              .map((e) => LogisticsActivity.fromJson(
                  Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }
}
