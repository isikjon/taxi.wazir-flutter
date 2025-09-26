import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';
import '../utils/phone_utils.dart';

class BalanceService {
  static BalanceService? _instance;
  static BalanceService get instance => _instance ??= BalanceService._();
  BalanceService._();

  Future<Map<String, dynamic>> getDriverBalance([String? phoneNumber]) async {
    try {
      // Если номер телефона не передан, получаем из локальных данных
      if (phoneNumber == null) {
        final driverData = await AuthService.getCurrentDriver();
        if (driverData == null) {
          return {
            'success': false,
            'error': 'Водитель не авторизован',
          };
        }
        phoneNumber = driverData['phoneNumber'];
      }

      final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber!);
      print('💰 Получение баланса для водителя: $normalizedPhone');

      final encodedPhone = Uri.encodeComponent(normalizedPhone);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/drivers/balance?phoneNumber=$encodedPhone'),
        headers: ApiConfig.defaultHeaders,
      );

      print('💰 Balance response status: ${response.statusCode}');
      print('💰 Balance response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения баланса: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('💰 Balance fetch error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getDriverTransactions({
    String filter = 'all',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final driverData = await AuthService.getCurrentDriver();
      if (driverData == null) {
        return {
          'success': false,
          'error': 'Водитель не авторизован',
        };
      }

      final phoneNumber = driverData['phoneNumber'];
      final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      print('📊 Получение транзакций для водителя: $normalizedPhone, фильтр: $filter');

      String endpoint = '${ApiConfig.baseUrl}/api/drivers/transactions';
      Map<String, String> queryParams = {
        'phoneNumber': normalizedPhone,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (filter != 'all') {
        queryParams['filter'] = filter;
      }

      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      
      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      print('📊 Transactions response status: ${response.statusCode}');
      print('📊 Transactions response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения транзакций: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('📊 Transactions fetch error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    try {
      final driverData = await AuthService.getCurrentDriver();
      if (driverData == null) {
        return {
          'success': false,
          'error': 'Водитель не авторизован',
        };
      }

      final phoneNumber = driverData['phoneNumber'];
      final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      print('📈 Получение статистики для водителя: $normalizedPhone');

      final encodedPhone = Uri.encodeComponent(normalizedPhone);
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/drivers/stats?phoneNumber=$encodedPhone'),
        headers: ApiConfig.defaultHeaders,
      );

      print('📈 Stats response status: ${response.statusCode}');
      print('📈 Stats response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка получения статистики: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('📈 Stats fetch error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  Future<Map<String, dynamic>> requestBalanceTopup(double amount) async {
    try {
      final driverData = await AuthService.getCurrentDriver();
      if (driverData == null) {
        return {
          'success': false,
          'error': 'Водитель не авторизован',
        };
      }

      final phoneNumber = driverData['phoneNumber'];
      print('💳 Запрос пополнения баланса: $amount сом для $phoneNumber');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/drivers/balance/topup'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({
          'phoneNumber': phoneNumber,
          'amount': amount,
        }),
      );

      print('💳 Topup response status: ${response.statusCode}');
      print('💳 Topup response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка пополнения баланса: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('💳 Topup error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  static Future<void> printBalanceApiInfo() async {
    print('\n💰 =============== BALANCE API INFO ===============');
    print('💰 Base URL: ${ApiConfig.baseUrl}');
    print('💰 Available balance endpoints:');
    print('  - GET /api/drivers/balance?phoneNumber={phone}');
    print('  - GET /api/drivers/transactions?phoneNumber={phone}&filter={filter}');
    print('  - GET /api/drivers/stats?phoneNumber={phone}');
    print('  - POST /api/drivers/balance/topup');
    print('💰 ================================================\n');
  }
}
