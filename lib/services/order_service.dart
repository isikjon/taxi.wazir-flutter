import 'package:dio/dio.dart';
import '../models/order_model.dart';
import '../config/api_config.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final Dio _dio = Dio();
  String get _baseUrl => ApiConfig.baseUrl;


  Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status, int driverId) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/api/orders/$orderId/status',
        data: {
          'status': status,
          'driver_id': driverId,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  Future<OrderModel> getOrder(int orderId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/orders/$orderId');
      return OrderModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get order: $e');
    }
  }

  Future<List<OrderModel>> getDriverOrders(int driverId) async {
    try {
      final response = await _dio.get('$_baseUrl/api/drivers/$driverId/orders');
      final List<dynamic> ordersData = response.data;
      return ordersData.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get driver orders: $e');
    }
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'accepted', driverId);
  }

  Future<Map<String, dynamic>> startNavigationToA(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'navigating_to_a', driverId);
  }

  Future<Map<String, dynamic>> arrivedAtA(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'arrived_at_a', driverId);
  }

  Future<Map<String, dynamic>> startNavigationToB(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'navigating_to_b', driverId);
  }

  Future<Map<String, dynamic>> completeOrder(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'completed', driverId);
  }

  Future<Map<String, dynamic>> cancelOrder(int orderId, int driverId) async {
    return await updateOrderStatus(orderId, 'cancelled', driverId);
  }
}
