enum TaskStatus { pending, accepted, pickedUp, outForDelivery, delivered, failed }

class DeliveryTask {
  final String id;
  final String trackingNumber;
  final String contactName;
  final String contactPhone;
  final String deliveryAddress;
  final double codAmount;
  final double? latitude;
  final double? longitude;
  final TaskStatus status;
  final bool isPickup;

  const DeliveryTask({
    required this.id,
    required this.trackingNumber,
    required this.contactName,
    required this.contactPhone,
    required this.deliveryAddress,
    required this.codAmount,
    this.latitude,
    this.longitude,
    required this.status,
    this.isPickup = false,
  });

  factory DeliveryTask.fromApi(Map<String, dynamic> json) {
    final delivery = json['delivery'] is Map
        ? Map<String, dynamic>.from(json['delivery'] as Map)
        : json;
    final order = delivery['order'] is Map
        ? Map<String, dynamic>.from(delivery['order'] as Map)
        : <String, dynamic>{};
    final buyer = order['buyer'] is Map
        ? Map<String, dynamic>.from(order['buyer'] as Map)
        : <String, dynamic>{};
    final address = delivery['delivery_address'] is Map
        ? Map<String, dynamic>.from(delivery['delivery_address'] as Map)
        : <String, dynamic>{};
    final rawStatus = (delivery['status'] ?? json['status'] ?? 'pending')
        .toString()
        .toLowerCase();
    final status = switch (rawStatus) {
      'delivered' => TaskStatus.delivered,
      'failed' => TaskStatus.failed,
      'accepted' => TaskStatus.accepted,
      'picked_up' || 'collected' => TaskStatus.pickedUp,
      'out_for_delivery' || 'in_transit' => TaskStatus.outForDelivery,
      _ => TaskStatus.pending,
    };
    final kind =
        (delivery['type'] ?? json['type'] ?? json['task_type'] ?? '')
            .toString()
            .toLowerCase();

    return DeliveryTask(
      id: (json['id'] ?? delivery['id'] ?? '').toString(),
      trackingNumber:
          (delivery['tracking_number'] ?? json['tracking_number'] ?? '—')
              .toString(),
      contactName: (delivery['contact_name'] ??
              buyer['name'] ??
              delivery['recipient_name'] ??
              'Customer')
          .toString(),
      contactPhone: (delivery['contact_phone'] ??
              buyer['phone'] ??
              delivery['recipient_phone'] ??
              '')
          .toString(),
      deliveryAddress: (address['formatted_address'] ??
              address['address_line'] ??
              delivery['address'] ??
              'Address unavailable')
          .toString(),
      codAmount: double.tryParse(
              (order['cod_amount'] ?? delivery['cod_amount'] ?? 0).toString()) ??
          0,
      latitude: double.tryParse((address['latitude'] ?? '').toString()),
      longitude: double.tryParse((address['longitude'] ?? '').toString()),
      status: status,
      isPickup: kind == 'pickup' || kind == 'collection',
    );
  }
}
