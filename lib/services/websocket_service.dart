import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/order_model.dart';
import '../config/api_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  final StreamController<OrderModel> _orderController = StreamController<OrderModel>.broadcast();
  final StreamController<Map<String, dynamic>> _statusController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<OrderModel> get orderStream => _orderController.stream;
  Stream<Map<String, dynamic>> get statusStream => _statusController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String driverId, int taxiparkId) async {

    try {
      // Преобразуем HTTPS в WSS для WebSocket
      final wsUrl = ApiConfig.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/orders'),
      );

      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'new_order':
          final orderData = data['data'];
          final order = OrderModel.fromJson(orderData);
          _orderController.add(order);
          break;
        case 'order_status_changed':
          _statusController.add(data);
          break;
        case 'connection_established':
          break;
        case 'error':
          break;
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  void _handleError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
  }

  void _handleDisconnect() {
    print('WebSocket disconnected');
    _isConnected = false;
  }

  Future<void> sendOrderStatus(int orderId, String status) async {
    if (!_isConnected || _channel == null) return;

    final message = {
      'type': 'order_status_update',
      'order_id': orderId,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> sendLocationUpdate(double latitude, double longitude) async {
    if (!_isConnected || _channel == null) return;

    final message = {
      'type': 'driver_location_update',
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(message));
  }

  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }

  void dispose() {
    _orderController.close();
    _statusController.close();
    disconnect();
  }
}
