import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class DriverStatusService {
  static final DriverStatusService _instance = DriverStatusService._internal();
  factory DriverStatusService() => _instance;
  DriverStatusService._internal();

  Future<Map<String, dynamic>> updateOnlineStatus(String status) async {
    try {
      final driverData = await AuthService.getCurrentDriver();
      if (driverData == null) {
        return {
          'success': false,
          'error': 'Водитель не авторизован',
        };
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/driver/api/online-status'),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'driver_id': driverData['id'],
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка обновления статуса: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  Future<Map<String, dynamic>> goOnline() async {
    return await updateOnlineStatus('online');
  }

  Future<Map<String, dynamic>> goOffline() async {
    return await updateOnlineStatus('offline');
  }
}
