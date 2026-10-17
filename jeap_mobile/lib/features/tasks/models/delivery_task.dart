enum TaskStatus {
  pending,
  accepted,
  pickedUp,
  outForDelivery,
  delivered,
  failed
}

class DeliveryTask {
  final String id;
  final String trackingNumber;
  final String buyerName;
  final String buyerPhone;
  final String deliveryAddress;
  final double codAmount;
  final double latitude;
  final double longitude;
  final TaskStatus status;
  final bool isPickup;
  final String? awbPhotoPath;
  final String? podPhotoPath;

  const DeliveryTask({
    required this.id,
    required this.trackingNumber,
    required this.buyerName,
    required this.buyerPhone,
    required this.deliveryAddress,
    required this.codAmount,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.isPickup = false,
    this.awbPhotoPath,
    this.podPhotoPath,
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
    final rawStatus = (json['status'] ?? delivery['status'] ?? 'pending')
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
    final kind = (json['type'] ?? json['task_type'] ?? delivery['type'] ?? '')
        .toString()
        .toLowerCase();
    return DeliveryTask(
      id: (json['id'] ?? delivery['id'] ?? '').toString(),
      trackingNumber:
          (delivery['tracking_number'] ?? json['tracking_number'] ?? '—')
              .toString(),
      buyerName: (buyer['name'] ?? delivery['recipient_name'] ?? 'Customer')
          .toString(),
      buyerPhone:
          (buyer['phone'] ?? delivery['recipient_phone'] ?? '').toString(),
      deliveryAddress: (address['formatted_address'] ??
              address['address_line'] ??
              delivery['address'] ??
              'Address unavailable')
          .toString(),
      codAmount: double.tryParse(
              (order['cod_amount'] ?? delivery['cod_amount'] ?? 0)
                  .toString()) ??
          0,
      latitude: double.tryParse((address['latitude'] ?? '').toString()) ?? 0,
      longitude: double.tryParse((address['longitude'] ?? '').toString()) ?? 0,
      status: status,
      isPickup: kind == 'pickup' ||
          kind == 'collection' ||
          (kind.isEmpty &&
              (status == TaskStatus.pending || status == TaskStatus.accepted)),
    );
  }

  DeliveryTask copyWith({
    TaskStatus? status,
    String? awbPhotoPath,
    String? podPhotoPath,
  }) {
    return DeliveryTask(
      id: id,
      trackingNumber: trackingNumber,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
      deliveryAddress: deliveryAddress,
      codAmount: codAmount,
      latitude: latitude,
      longitude: longitude,
      status: status ?? this.status,
      isPickup: isPickup,
      awbPhotoPath: awbPhotoPath ?? this.awbPhotoPath,
      podPhotoPath: podPhotoPath ?? this.podPhotoPath,
    );
  }
}
