enum OrderStatus {
  toPay,
  toShip,
  sellerPreparing,
  riderPickup,
  sortingCenter,
  assignedRider,
  outForDelivery,
  delivered,
  completed,
  cancelled,
  returnRefund,
}

extension OrderStatusLabel on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.toPay:
        return 'To Pay';
      case OrderStatus.toShip:
        return 'To Ship';
      case OrderStatus.sellerPreparing:
        return 'Seller Preparing';
      case OrderStatus.riderPickup:
        return 'Rider Pickup';
      case OrderStatus.sortingCenter:
        return 'Sorting Center';
      case OrderStatus.assignedRider:
        return 'Assigned Rider';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returnRefund:
        return 'Return / Refund';
    }
  }

  static OrderStatus fromString(String s) {
    final lower = s.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
    switch (lower) {
      case 'topay':
      case 'to_pay':
      case 'pending':
        return OrderStatus.toPay;
      case 'toship':
      case 'to_ship':
      case 'confirmed':
        return OrderStatus.toShip;
      case 'sellerpreparing':
      case 'seller_preparing':
      case 'preparing':
      case 'processing':
        return OrderStatus.sellerPreparing;
      case 'riderpickup':
      case 'rider_pickup':
      case 'ready_for_pickup':
      case 'readyforpickup':
      case 'shipped':
        return OrderStatus.riderPickup;
      case 'sortingcenter':
      case 'sorting_center':
      case 'in_transit':
        return OrderStatus.sortingCenter;
      case 'assignedrider':
      case 'assigned_rider':
        return OrderStatus.assignedRider;
      case 'outfordelivery':
      case 'out_for_delivery':
        return OrderStatus.outForDelivery;
      case 'delivered':
        return OrderStatus.delivered;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
      case 'canceled':
        return OrderStatus.cancelled;
      case 'returnrefund':
      case 'return_refund':
        return OrderStatus.returnRefund;
      default:
        return OrderStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == lower,
          orElse: () => OrderStatus.toPay,
        );
    }
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final String? imageUrl;
  final double price;
  final int quantity;
  final Map<String, String> variations;
  double? rating;
  String? review;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.variations = const {},
    this.rating,
    this.review,
  });

  double get subtotal => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    Map<String, String> variations = {};
    if (json['variations'] is Map) {
      variations = (json['variations'] as Map)
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    } else if (json['variant'] != null &&
        json['variant'].toString().isNotEmpty) {
      variations = {'Variant': json['variant'].toString()};
    }

    return OrderItem(
      productId: (json['product_id'] ?? '').toString(),
      productName: (json['product_name'] ?? json['name'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: (json['image_url'] ?? json['image']) as String?,
      variations: variations,
      rating: (json['rating'] as num?)?.toDouble(),
      review: json['review'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
        'variations': variations,
      };
}

class Order {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final OrderStatus status;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String paymentMethod;
  final String? voucherCode;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.status,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.voucherCode,
    required this.createdAt,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    String addressStr = '';
    if (json['delivery_address'] != null) {
      addressStr = json['delivery_address'].toString();
    } else if (json['address'] is Map) {
      final a = json['address'] as Map;
      addressStr = [
        a['address_line'],
        a['barangay'],
        a['city'],
        a['province'],
        a['postal_code']
      ].where((e) => e != null && e.toString().isNotEmpty).join(', ');
    }

    final total =
        (json['total'] ?? json['total_amount'] as num?)?.toDouble() ?? 0.0;
    final fee =
        (json['delivery_fee'] ?? json['shipping_fee'] as num?)?.toDouble() ??
            0.0;
    final discount =
        (json['discount'] ?? json['discount_amount'] as num?)?.toDouble() ??
            0.0;
    final subtotal =
        (json['subtotal'] as num?)?.toDouble() ?? (total - fee + discount);

    return Order(
      id: json['id'].toString(),
      orderNumber: (json['order_number'] ?? '') as String,
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: OrderStatusLabel.fromString((json['status'] ?? '') as String),
      subtotal: subtotal,
      discount: discount,
      deliveryFee: fee,
      total: total,
      deliveryAddress: addressStr,
      paymentMethod: (json['payment_method'] ?? '') as String,
      voucherCode: json['voucher_code'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}
