import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  StreamController<Map<String, dynamic>> _orderStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get orderStream => _orderStreamController.stream;

  Map<String, dynamic>? _currentOrder;
  Map<String, dynamic>? get currentOrder => _currentOrder;

  void updateOrderStatus(String status) {
    if (_currentOrder != null) {
      _currentOrder!['status'] = status;
      _orderStreamController.add(_currentOrder!);
    }
  }

  void setCurrentOrder(Map<String, dynamic> order) {
    _currentOrder = order;
    _orderStreamController.add(order);
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    _orderStreamController.add({});
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        throw Exception('Данные водителя не найдены');
      }

      final driver = json.decode(driverData);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/driver/orders/$orderId/accept'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'driver_id': driver['id'],
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          updateOrderStatus('accepted');
          return result;
        }
      }
      
      throw Exception('Ошибка принятия заказа: ${response.body}');
    } catch (e) {
      print('❌ Ошибка принятия заказа: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        throw Exception('Данные водителя не найдены');
      }

      final driver = json.decode(driverData);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/driver/orders/$orderId/reject'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'driver_id': driver['id'],
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          clearCurrentOrder();
          return result;
        }
      }
      
      throw Exception('Ошибка отклонения заказа: ${response.body}');
    } catch (e) {
      print('❌ Ошибка отклонения заказа: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrderStatusToServer(String status) async {
    if (_currentOrder == null) return {};

    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        throw Exception('Данные водителя не найдены');
      }

      final driver = json.decode(driverData);
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/driver/orders/${_currentOrder!['id']}/status'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'driver_id': driver['id'],
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          updateOrderStatus(status);
          return result;
        }
      }
      
      throw Exception('Ошибка обновления статуса: ${response.body}');
    } catch (e) {
      print('❌ Ошибка обновления статуса заказа: $e');
      rethrow;
    }
  }

  void dispose() {
    _orderStreamController.close();
  }
}