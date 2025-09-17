class BalanceData {
  final double currentBalance;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int totalOrders;
  final DateTime lastUpdated;

  BalanceData({
    required this.currentBalance,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalOrders,
    required this.lastUpdated,
  });

  factory BalanceData.fromJson(Map<String, dynamic> json) {
    return BalanceData(
      currentBalance: (json['balance'] ?? json['current_balance'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weekly_earnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] ?? 0.0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      lastUpdated: DateTime.tryParse(json['last_updated'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'balance': currentBalance,
      'weekly_earnings': weeklyEarnings,
      'monthly_earnings': monthlyEarnings,
      'total_orders': totalOrders,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime createdAt;
  final String status;
  final String? orderId;
  final String? reference;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.createdAt,
    required this.status,
    this.orderId,
    this.reference,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? json['transaction_id'] ?? '',
      type: json['type'] ?? 'unknown',
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'] ?? json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? json['date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'completed',
      orderId: json['order_id'],
      reference: json['reference'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'order_id': orderId,
      'reference': reference,
    };
  }

  String get formattedAmount {
    if (amount >= 0) {
      return '+${amount.toStringAsFixed(0)} сом';
    } else {
      return '${amount.toStringAsFixed(0)} сом';
    }
  }

  String get formattedDate {
    // Формат дд.мм.гг как требуется
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year.toString().substring(2);
    return '$day.$month.$year';
  }

  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'order':
      case 'заказ':
        return 'Заказ';
      case 'topup':
      case 'пополнение':
        return 'Пополнение';
      case 'withdrawal':
      case 'вывод':
        return 'Вывод средств';
      case 'bonus':
      case 'бонус':
        return 'Бонус';
      case 'commission':
      case 'комиссия':
        return 'Комиссия';
      default:
        return 'Транзакция';
    }
  }
}

class TransactionList {
  final List<Transaction> transactions;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasMore;

  TransactionList({
    required this.transactions,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
  });

  factory TransactionList.fromJson(Map<String, dynamic> json) {
    final List<dynamic> transactionsJson = json['transactions'] ?? json['data'] ?? [];
    final transactions = transactionsJson
        .map((item) => Transaction.fromJson(item))
        .toList();

    return TransactionList(
      transactions: transactions,
      totalCount: json['total_count'] ?? json['total'] ?? transactions.length,
      currentPage: json['current_page'] ?? json['page'] ?? 1,
      totalPages: json['total_pages'] ?? json['pages'] ?? 1,
      hasMore: json['has_more'] ?? json['has_next'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'total_count': totalCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'has_more': hasMore,
    };
  }
}

class DriverStats {
  final double totalEarnings;
  final double weeklyEarnings;
  final double monthlyEarnings;
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double averageOrderValue;
  final double rating;
  final int totalRides;

  DriverStats({
    required this.totalEarnings,
    required this.weeklyEarnings,
    required this.monthlyEarnings,
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.averageOrderValue,
    required this.rating,
    required this.totalRides,
  });

  factory DriverStats.fromJson(Map<String, dynamic> json) {
    return DriverStats(
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weekly_earnings'] ?? 0.0).toDouble(),
      monthlyEarnings: (json['monthly_earnings'] ?? 0.0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      completedOrders: json['completed_orders'] ?? 0,
      cancelledOrders: json['cancelled_orders'] ?? 0,
      averageOrderValue: (json['average_order_value'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalRides: json['total_rides'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earnings': totalEarnings,
      'weekly_earnings': weeklyEarnings,
      'monthly_earnings': monthlyEarnings,
      'total_orders': totalOrders,
      'completed_orders': completedOrders,
      'cancelled_orders': cancelledOrders,
      'average_order_value': averageOrderValue,
      'rating': rating,
      'total_rides': totalRides,
    };
  }
}
