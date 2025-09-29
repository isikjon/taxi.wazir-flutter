import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocket? _webSocket;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        print('❌ [WebSocket] Данные водителя не найдены');
        return;
      }

      final driver = json.decode(driverData);
      final driverId = driver['id'];
      
      print('🔍 [WebSocket] Подключаемся к WebSocket для водителя: $driverId');

      final wsUrl = 'ws://new.superadmin.taxi.wazir.kg/ws/orders/driver/$driverId';
      print('🔍 [WebSocket] URL: $wsUrl');
      
      _webSocket = await WebSocket.connect(wsUrl);
      _isConnected = true;
      _reconnectAttempts = 0;
      
      print('✅ [WebSocket] Подключение установлено');
      
      _webSocket!.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );
      
    } catch (e) {
      print('❌ [WebSocket] Ошибка подключения: $e');
      _scheduleReconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      print('🔍 [WebSocket] Получено сообщение: $message');
      
      final data = json.decode(message);
      print('🔍 [WebSocket] Парсинг данных: $data');
      
      if (data['type'] == 'new_order') {
        print('🔍 [WebSocket] Новый заказ получен');
        final orderData = data['data'];
        OrderService().setCurrentOrder(orderData);
      } else if (data['type'] == 'order_status_update') {
        print('🔍 [WebSocket] Обновление статуса заказа');
        final orderData = data['data'];
        OrderService().setCurrentOrder(orderData);
      }
      
      _messageController.add(data);
    } catch (e) {
      print('❌ [WebSocket] Ошибка обработки сообщения: $e');
    }
  }

  void _handleError(dynamic error) {
    print('❌ [WebSocket] Ошибка WebSocket: $error');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _handleDisconnection() {
    print('🔍 [WebSocket] Соединение закрыто');
    _isConnected = false;
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ [WebSocket] Превышено максимальное количество попыток переподключения');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    
    print('🔍 [WebSocket] Переподключение через ${delay.inSeconds} секунд (попытка $_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_webSocket != null && _isConnected) {
      try {
        _webSocket!.add(json.encode(message));
        print('🔍 [WebSocket] Сообщение отправлено: $message');
      } catch (e) {
        print('❌ [WebSocket] Ошибка отправки сообщения: $e');
      }
    } else {
      print('❌ [WebSocket] WebSocket не подключен');
    }
  }

  void disconnect() {
    print('🔍 [WebSocket] Отключение WebSocket');
    _reconnectTimer?.cancel();
    _webSocket?.close();
    _isConnected = false;
  }


  void dispose() {
    disconnect();
    _messageController.close();
  }
}
