class LogisticsParcel {
  final String trackingNumber;
  final String orderNumber;
  final String status;
  final String recipientName;
  final String recipientPhone;
  final String destinationAddress;
  final String originHub;
  final int itemsCount;
  final double totalAmount;
  final String paymentMethod;
  final String? createdAt;
  final List<String> allowedActions;

  const LogisticsParcel({
    required this.trackingNumber,
    required this.orderNumber,
    required this.status,
    required this.recipientName,
    required this.recipientPhone,
    required this.destinationAddress,
    required this.originHub,
    required this.itemsCount,
    required this.totalAmount,
    required this.paymentMethod,
    this.createdAt,
    this.allowedActions = const [],
  });

  factory LogisticsParcel.fromJson(Map<String, dynamic> json) {
    return LogisticsParcel(
      trackingNumber: json['tracking_number']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      recipientName: json['recipient_name']?.toString() ?? 'Customer',
      recipientPhone: json['recipient_phone']?.toString() ?? '',
      destinationAddress: json['destination_address']?.toString() ?? '',
      originHub: json['origin_hub']?.toString() ?? 'JEAP Central Warehouse',
      itemsCount: json['items_count'] is int ? json['items_count'] : 1,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'COD',
      createdAt: json['created_at']?.toString(),
      allowedActions: (json['allowed_actions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class LogisticsHubStats {
  final int incoming;
  final int received;
  final int awaitingSorting;
  final int readyForDispatch;
  final int outgoing;

  const LogisticsHubStats({
    required this.incoming,
    required this.received,
    required this.awaitingSorting,
    required this.readyForDispatch,
    required this.outgoing,
  });

  factory LogisticsHubStats.fromJson(Map<String, dynamic> json) {
    return LogisticsHubStats(
      incoming: json['incoming'] as int? ?? 0,
      received: json['received'] as int? ?? 0,
      awaitingSorting: json['awaiting_sorting'] as int? ?? 0,
      readyForDispatch: json['ready_for_dispatch'] as int? ?? 0,
      outgoing: json['outgoing'] as int? ?? 0,
    );
  }
}

class LogisticsActivity {
  final String trackingNumber;
  final String orderNumber;
  final String status;
  final String action;
  final String timestamp;
  final String? location;

  const LogisticsActivity({
    required this.trackingNumber,
    required this.orderNumber,
    required this.status,
    required this.action,
    required this.timestamp,
    this.location,
  });

  factory LogisticsActivity.fromJson(Map<String, dynamic> json) {
    return LogisticsActivity(
      trackingNumber: json['tracking_number']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      location: json['location']?.toString(),
    );
  }
}
