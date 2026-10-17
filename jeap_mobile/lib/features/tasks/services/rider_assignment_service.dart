import 'package:jeap_mobile/core/network/api_client.dart';
import 'package:jeap_mobile/core/network/api_exception.dart';
import 'package:jeap_mobile/features/tasks/models/delivery_task.dart';

class RiderAssignmentsResult {
  const RiderAssignmentsResult({required this.tasks, this.message});
  final List<DeliveryTask> tasks;
  final String? message;
}

class RiderAssignmentService {
  RiderAssignmentService({ApiClient? api}) : _api = api ?? const ApiClient();
  final ApiClient _api;

  Future<RiderAssignmentsResult> list() async {
    final response = await _api.get('/rider/assignments');
    if (response is! Map) {
      throw const ApiException(
          message: 'The server returned invalid assignments.');
    }
    final records = response['assignments'];
    if (records is! List) {
      throw const ApiException(
          message: 'The server returned invalid assignments.');
    }
    return RiderAssignmentsResult(
      tasks: records
          .whereType<Map>()
          .map((item) => DeliveryTask.fromApi(Map<String, dynamic>.from(item)))
          .toList(),
      message: response['message'] as String?,
    );
  }

  Future<void> accept(String id) => _action(id, 'accept');
  Future<void> confirmPickup(String id) => _action(id, 'scan');
  Future<void> startDelivery(String id) => _action(id, 'out-for-delivery');
  Future<void> completeDelivery(String id) => _action(id, 'deliver');
  Future<void> failDelivery(String id, String reason) =>
      _action(id, 'fail', {'reason': reason});

  Future<void> _action(String id, String action,
      [Map<String, dynamic>? body]) async {
    await _api.post('/rider/assignments/$id/$action', body ?? {});
  }
}
