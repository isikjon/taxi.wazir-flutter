class OrderModel {
  final int id;
  final String orderNumber;
  final String clientName;
  final String clientPhone;
  final String pickupAddress;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String destinationAddress;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double price;
  final double? distance;
  final int? duration;
  final String status;
  final int? driverId;
  final int taxiparkId;
  final String? tariff;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? arrivedAtA;
  final DateTime? startedToB;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.clientName,
    required this.clientPhone,
    required this.pickupAddress,
    this.pickupLatitude,
    this.pickupLongitude,
    required this.destinationAddress,
    this.destinationLatitude,
    this.destinationLongitude,
    required this.price,
    this.distance,
    this.duration,
    required this.status,
    this.driverId,
    required this.taxiparkId,
    this.tariff,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    this.acceptedAt,
    this.arrivedAtA,
    this.startedToB,
    this.completedAt,
    this.cancelledAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      clientName: json['client_name'] ?? '',
      clientPhone: json['client_phone'] ?? '',
      pickupAddress: json['pickup_address'] ?? '',
      pickupLatitude: json['pickup_latitude']?.toDouble(),
      pickupLongitude: json['pickup_longitude']?.toDouble(),
      destinationAddress: json['destination_address'] ?? '',
      destinationLatitude: json['destination_latitude']?.toDouble(),
      destinationLongitude: json['destination_longitude']?.toDouble(),
      price: (json['price'] ?? 0.0).toDouble(),
      distance: json['distance']?.toDouble(),
      duration: json['duration'],
      status: json['status'] ?? 'received',
      driverId: json['driver_id'],
      taxiparkId: json['taxipark_id'] ?? 0,
      tariff: json['tariff'],
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      arrivedAtA: json['arrived_at_a'] != null ? DateTime.parse(json['arrived_at_a']) : null,
      startedToB: json['started_to_b'] != null ? DateTime.parse(json['started_to_b']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'client_name': clientName,
      'client_phone': clientPhone,
      'pickup_address': pickupAddress,
      'pickup_latitude': pickupLatitude,
      'pickup_longitude': pickupLongitude,
      'destination_address': destinationAddress,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      'price': price,
      'distance': distance,
      'duration': duration,
      'status': status,
      'driver_id': driverId,
      'taxipark_id': taxiparkId,
      'tariff': tariff,
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'arrived_at_a': arrivedAtA?.toIso8601String(),
      'started_to_b': startedToB?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'cancelled_at': cancelledAt?.toIso8601String(),
    };
  }

  OrderModel copyWith({
    int? id,
    String? orderNumber,
    String? clientName,
    String? clientPhone,
    String? pickupAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    String? destinationAddress,
    double? destinationLatitude,
    double? destinationLongitude,
    double? price,
    double? distance,
    int? duration,
    String? status,
    int? driverId,
    int? taxiparkId,
    String? tariff,
    String? paymentMethod,
    String? notes,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? arrivedAtA,
    DateTime? startedToB,
    DateTime? completedAt,
    DateTime? cancelledAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLatitude: pickupLatitude ?? this.pickupLatitude,
      pickupLongitude: pickupLongitude ?? this.pickupLongitude,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      price: price ?? this.price,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      status: status ?? this.status,
      driverId: driverId ?? this.driverId,
      taxiparkId: taxiparkId ?? this.taxiparkId,
      tariff: tariff ?? this.tariff,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      arrivedAtA: arrivedAtA ?? this.arrivedAtA,
      startedToB: startedToB ?? this.startedToB,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
