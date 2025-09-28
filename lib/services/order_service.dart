import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import 'location_service.dart';
import 'navigation_service.dart';

class InsufficientBalanceException implements Exception {
  final String message;
  final double requiredAmount;
  final double currentBalance;

  InsufficientBalanceException(this.message, {
    required this.requiredAmount,
    required this.currentBalance,
  });

  @override
  String toString() => message;
}

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  StreamController<Map<String, dynamic>> _orderStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get orderStream => _orderStreamController.stream;

  Map<String, dynamic>? _currentOrder;
  Map<String, dynamic>? get currentOrder => _currentOrder;

  StreamSubscription<Position>? _locationSubscription;
  bool _isMonitoringLocation = false;

  void updateOrderStatus(String status) {
    if (_currentOrder != null) {
      _currentOrder!['status'] = status;
      _orderStreamController.add(_currentOrder!);
    }
  }

  void setCurrentOrder(Map<String, dynamic> order) {
    _currentOrder = order;
    _orderStreamController.add(order);
    _startLocationMonitoring();
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    _orderStreamController.add({});
    _stopLocationMonitoring();
  }

  Future<Map<String, dynamic>> acceptOrder(int orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        throw Exception('Данные водителя не найдены');
      }

      final driver = json.decode(driverData);
      final requestBody = {
        'driver_id': int.parse(driver['id'].toString()),
        'status': 'accepted',
      };
      
      print('🔍 [OrderService] Accepting order $orderId');
      print('🔍 [OrderService] Driver ID: ${driver['id']} (type: ${driver['id'].runtimeType})');
      print('🔍 [OrderService] Request body: $requestBody');
      print('🔍 [OrderService] JSON body: ${json.encode(requestBody)}');
      print('🔍 [OrderService] URL: ${ApiConfig.baseUrl}/driver/api/orders/$orderId/status');
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/driver/api/orders/$orderId/status'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestBody),
      );

      print('🔍 [OrderService] Response status: ${response.statusCode}');
      print('🔍 [OrderService] Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          updateOrderStatus('accepted');
          return result;
        } else {
          // Проверяем, является ли это ошибкой недостаточного баланса
          if (result['error_code'] == 'INSUFFICIENT_BALANCE') {
            throw InsufficientBalanceException(
              result['error'] ?? 'Недостаточно средств на балансе',
              requiredAmount: result['required_amount']?.toDouble() ?? 0.0,
              currentBalance: result['current_balance']?.toDouble() ?? 0.0,
            );
          } else {
            throw Exception('Ошибка принятия заказа: ${result['error'] ?? result['message'] ?? 'Неизвестная ошибка'}');
          }
        }
      } else {
        final errorBody = response.body;
        print('❌ [OrderService] HTTP Error ${response.statusCode}: $errorBody');
        throw Exception('HTTP ${response.statusCode}: $errorBody');
      }
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
        Uri.parse('${ApiConfig.baseUrl}/driver/api/orders/$orderId/status'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'driver_id': int.parse(driver['id'].toString()),
          'status': 'cancelled',
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

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    return rejectOrder(orderId);
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
        Uri.parse('${ApiConfig.baseUrl}/driver/api/orders/${_currentOrder!['id']}/status'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'driver_id': int.parse(driver['id'].toString()),
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

  void _startLocationMonitoring() {
    if (_isMonitoringLocation || _currentOrder == null) return;

    _isMonitoringLocation = true;
    print('🔍 [OrderService] Начинаем мониторинг местоположения для заказа');

    _locationSubscription = LocationService().locationStream.listen((position) {
      _checkLocationBasedStatus(position);
    });
  }

  void _stopLocationMonitoring() {
    if (!_isMonitoringLocation) return;

    _isMonitoringLocation = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    print('🔍 [OrderService] Останавливаем мониторинг местоположения');
  }

  void _checkLocationBasedStatus(Position position) {
    if (_currentOrder == null) return;

    final status = _currentOrder!['status'];
    final pickupLat = _currentOrder!['pickup_latitude'];
    final pickupLon = _currentOrder!['pickup_longitude'];
    final destinationLat = _currentOrder!['destination_latitude'];
    final destinationLon = _currentOrder!['destination_longitude'];

    if (pickupLat == null || pickupLon == null) return;

    const double arrivalRadius = 50.0;

    switch (status) {
      case 'accepted':
      case 'navigating_to_a':
        if (LocationService().isNearLocation(
          position.latitude, position.longitude,
          pickupLat, pickupLon,
          arrivalRadius,
        )) {
          print('✅ [OrderService] Прибыли к клиенту (точка А)');
          updateOrderStatus('arrived_at_a');
        }
        break;

      case 'navigating_to_b':
        if (destinationLat != null && destinationLon != null) {
          if (LocationService().isNearLocation(
            position.latitude, position.longitude,
            destinationLat, destinationLon,
            arrivalRadius,
          )) {
            print('✅ [OrderService] Прибыли к точке назначения (точка Б)');
            updateOrderStatus('completed');
          }
        }
        break;
    }
  }

  Future<void> startNavigationToClient() async {
    if (_currentOrder == null) return;

    final pickupLat = _currentOrder!['pickup_latitude'];
    final pickupLon = _currentOrder!['pickup_longitude'];

    if (pickupLat == null || pickupLon == null) {
      print('❌ [OrderService] Координаты точки А не найдены');
      return;
    }

    try {
      final route = await NavigationService().buildRouteToClient(pickupLat, pickupLon);
      if (route != null) {
        NavigationService().startNavigation();
        updateOrderStatus('navigating_to_a');
        print('✅ [OrderService] Начинаем навигацию к клиенту');
      }
    } catch (e) {
      print('❌ [OrderService] Ошибка построения маршрута к клиенту: $e');
    }
  }

  Future<void> startNavigationToDestination() async {
    if (_currentOrder == null) return;

    final destinationLat = _currentOrder!['destination_latitude'];
    final destinationLon = _currentOrder!['destination_longitude'];

    if (destinationLat == null || destinationLon == null) {
      print('❌ [OrderService] Координаты точки Б не найдены');
      return;
    }

    try {
      final route = await NavigationService().buildRouteToDestination(destinationLat, destinationLon);
      if (route != null) {
        NavigationService().startNavigation();
        updateOrderStatus('navigating_to_b');
        print('✅ [OrderService] Начинаем навигацию к точке назначения');
      }
    } catch (e) {
      print('❌ [OrderService] Ошибка построения маршрута к точке назначения: $e');
    }
  }

  void dispose() {
    _stopLocationMonitoring();
    _orderStreamController.close();
  }
}