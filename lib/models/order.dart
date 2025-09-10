class Order {
  final int id;
  final String fromAddress;
  final String toAddress;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String status;
  final double price;
  final String? clientPhone;
  final String? clientName;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  Order({
    required this.id,
    required this.fromAddress,
    required this.toAddress,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.status,
    required this.price,
    this.clientPhone,
    this.clientName,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      fromAddress: json['from_address'],
      toAddress: json['to_address'],
      fromLat: (json['from_lat'] ?? 0.0).toDouble(),
      fromLng: (json['from_lng'] ?? 0.0).toDouble(),
      toLat: (json['to_lat'] ?? 0.0).toDouble(),
      toLng: (json['to_lng'] ?? 0.0).toDouble(),
      status: json['status'],
      price: (json['price'] ?? 0.0).toDouble(),
      clientPhone: json['client_phone'],
      clientName: json['client_name'],
      createdAt: DateTime.parse(json['created_at']),
      acceptedAt: json['accepted_at'] != null ? DateTime.parse(json['accepted_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from_address': fromAddress,
      'to_address': toAddress,
      'from_lat': fromLat,
      'from_lng': fromLng,
      'to_lat': toLat,
      'to_lng': toLng,
      'status': status,
      'price': price,
      'client_phone': clientPhone,
      'client_name': clientName,
      'created_at': createdAt.toIso8601String(),
      'accepted_at': acceptedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}
