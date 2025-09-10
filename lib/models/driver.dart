class Driver {
  final int id;
  final String firstName;
  final String lastName;
  final String phone;
  final String carModel;
  final String carNumber;
  final double balance;
  final String tariff;
  final bool isActive;
  final bool isOnline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Driver({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.carModel,
    required this.carNumber,
    required this.balance,
    required this.tariff,
    required this.isActive,
    required this.isOnline,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      carModel: json['car_model'],
      carNumber: json['car_number'],
      balance: (json['balance'] ?? 0.0).toDouble(),
      tariff: json['tariff'] ?? 'Эконом',
      isActive: json['is_active'] ?? true,
      isOnline: json['is_online'] ?? false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'car_model': carModel,
      'car_number': carNumber,
      'balance': balance,
      'tariff': tariff,
      'is_active': isActive,
      'is_online': isOnline,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
