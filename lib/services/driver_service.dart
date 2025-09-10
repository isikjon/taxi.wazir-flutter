import 'package:dio/dio.dart';
import 'api_service.dart';

class DriverService {
  static Future<Map<String, dynamic>> getDriverProfile() async {
    try {
      final response = await ApiService.get('/driver/profile');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Профиль водителя не найден');
      } else {
        throw Exception('Ошибка получения профиля: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  static Future<Map<String, dynamic>> updateDriverStatus(bool isOnline) async {
    try {
      final response = await ApiService.post('/driver/status', data: {
        'is_online': isOnline,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else {
        throw Exception('Ошибка обновления статуса: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final response = await ApiService.get('/driver/orders');
      return List<Map<String, dynamic>>.from(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else {
        throw Exception('Ошибка получения заказов: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  static Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    try {
      final response = await ApiService.post('/driver/orders/$orderId/accept');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заказ не найден');
      } else {
        throw Exception('Ошибка принятия заказа: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  static Future<Map<String, dynamic>> completeOrder(String orderId) async {
    try {
      final response = await ApiService.post('/driver/orders/$orderId/complete');
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Необходима авторизация');
      } else if (e.response?.statusCode == 404) {
        throw Exception('Заказ не найден');
      } else {
        throw Exception('Ошибка завершения заказа: ${e.message}');
      }
    } catch (e) {
      throw Exception('Неизвестная ошибка: $e');
    }
  }
}
