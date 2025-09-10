import 'api_service.dart';
import 'database_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final driver = await DatabaseService.getDriverByPhone(phone);
      
      if (driver != null) {
        final token = 'local_token_${driver['id']}';
        await ApiService.setToken(token);
        return {
          'access_token': token,
          'driver': driver,
          'isNewUser': false,
        };
      } else {
        // Создаем нового пользователя
        final newDriver = await _createNewDriver(phone);
        final token = 'local_token_${newDriver['id']}';
        await ApiService.setToken(token);
        return {
          'access_token': token,
          'driver': newDriver,
          'isNewUser': true,
        };
      }
    } catch (e) {
      throw Exception('Ошибка авторизации: $e');
    }
  }

  static Future<Map<String, dynamic>> _createNewDriver(String phone) async {
    // Создаем нового водителя в локальной БД
    final db = await DatabaseService.database;
    final result = await db.insert('drivers', {
      'first_name': '',
      'last_name': '',
      'phone': phone,
      'car_model': '',
      'car_number': '',
      'balance': 0.0,
      'tariff': 'Эконом',
      'taxipark_id': 1, // По умолчанию первый таксопарк
      'is_active': 1,
      'is_online': 0,
    });
    
    // Получаем созданного водителя
    final drivers = await db.query(
      'drivers',
      where: 'id = ?',
      whereArgs: [result],
    );
    
    return drivers.first;
  }

  static Future<void> logout() async {
    try {
      await ApiService.post('/auth/driver/logout');
    } catch (e) {
    } finally {
      await ApiService.clearToken();
    }
  }

  static Future<bool> isLoggedIn() async {
    await ApiService.loadToken();
    return ApiService.accessToken != null;
  }

  static Future<Map<String, dynamic>?> getCurrentDriver() async {
    try {
      final token = ApiService.accessToken;
      if (token != null && token.startsWith('local_token_')) {
        final driverId = int.parse(token.replaceFirst('local_token_', ''));
        final drivers = await DatabaseService.getDrivers();
        return drivers.firstWhere((d) => d['id'] == driverId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
