import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/phone_utils.dart';

class DevinoSmsService {
  static const String _baseUrl = 'https://phoneverification.devinotele.com';
  static const String _apiKey = '8YF4D4R8k094r8uR3nwiEnsRuwIXRW67';
  
  static DevinoSmsService? _instance;
  static DevinoSmsService get instance => _instance ??= DevinoSmsService._();
  DevinoSmsService._();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-ApiKey': _apiKey,
  };

  Future<Map<String, dynamic>> sendSmsCode(String phoneNumber) async {
    try {
      // Нормализуем номер телефона для Devino 2FA API
      // Пробуем оригинальный формат кыргызского номера
      final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber).replaceFirst('+', '');
      
      print('📱 [Devino 2FA] Исходный номер: $phoneNumber');
      print('📱 [Devino 2FA] Нормализованный номер: $normalizedPhone');
      print('📱 [Devino 2FA] API URL: $_baseUrl/GenerateCode');
      
      // Проверяем интернет соединение
      try {
        final connectivityResponse = await http.get(
          Uri.parse('https://www.google.com'),
        ).timeout(const Duration(seconds: 5));
        
        if (connectivityResponse.statusCode != 200) {
          print('⚠️ [Devino 2FA] Проблемы с интернет соединением');
          return {
            'success': false,
            'error': 'Проблемы с интернет соединением',
          };
        }
      } catch (e) {
        print('⚠️ [Devino 2FA] Нет интернет соединения: $e');
        return {
          'success': false,
          'error': 'Нет интернет соединения',
        };
      }

      // Отправляем запрос на генерацию кода через 2FA API
      final requestBody = {
        'DestinationNumber': normalizedPhone,
      };

      print('📤 [Devino 2FA] Отправка запроса: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/GenerateCode'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📤 [Devino 2FA] Ответ сервера: ${response.statusCode}');
      print('📤 [Devino 2FA] Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['Code'] == 0) {
          // SMS код успешно отправлен через Devino 2FA
          print('✅ [Devino 2FA] SMS код отправлен успешно');
          
          return {
            'success': true,
            'messageId': 'devino_2fa_${DateTime.now().millisecondsSinceEpoch}',
            'phoneNumber': normalizedPhone,
            'data': responseData,
            'provider': 'devino_2fa',
            'description': responseData['Description'],
          };
        } else {
          print('❌ [Devino 2FA] API ошибка: ${responseData['Code']} - ${responseData['Description']}');
          return {
            'success': false,
            'error': 'Devino 2FA API ошибка: ${responseData['Description']}',
          };
        }
      } else {
        print('❌ [Devino 2FA] HTTP ошибка: ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP ошибка: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [Devino 2FA] Ошибка отправки SMS: $e');
      
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getSmsStatus(String messageId, String phoneNumber) async {
    try {
      final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber).replaceFirst('+', '');
      
      print('📱 [Devino] Проверка статуса SMS: $messageId для $normalizedPhone');

      final response = await http.get(
        Uri.parse('$_baseUrl/sms/status?messageId=$messageId&msisdn=$normalizedPhone'),
        headers: _headers,
      ).timeout(const Duration(seconds: 30));

      print('📱 [Devino] Статус ответ: ${response.statusCode}');
      print('📱 [Devino] Статус тело: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['code'] == 0 && responseData['messages'].isNotEmpty) {
          final message = responseData['messages'][0];
          
          return {
            'success': true,
            'status': message['status'],
            'statusTime': message['statusTime'],
            'data': responseData,
          };
        } else {
          return {
            'success': false,
            'error': 'Не удалось получить статус',
            'code': responseData['code'],
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ошибка: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print('❌ [Devino] Ошибка получения статуса: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }



  // Проверка SMS кода через Devino 2FA API
  Future<Map<String, dynamic>> checkSmsCode(String phoneNumber, String code) async {
    try {
      final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber).replaceFirst('+', '');
      
      print('📱 [Devino 2FA] Проверка кода: $code для номера: $normalizedPhone');
      
      final requestBody = {
        'DestinationNumber': normalizedPhone,
        'Code': code,
      };

      print('📤 [Devino 2FA] Отправка запроса проверки: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/CheckCode'),
        headers: _headers,
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      print('📤 [Devino 2FA] Ответ проверки: ${response.statusCode}');
      print('📤 [Devino 2FA] Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['Code'] == 0) {
          print('✅ [Devino 2FA] Код проверен успешно');
          return {
            'success': true,
            'valid': true,
            'data': responseData,
          };
        } else {
          print('❌ [Devino 2FA] Код неверный: ${responseData['Code']} - ${responseData['Description']}');
          return {
            'success': false,
            'valid': false,
            'error': 'Devino 2FA API ошибка: ${responseData['Description']}',
          };
        }
      } else {
        print('❌ [Devino 2FA] HTTP ошибка проверки: ${response.statusCode}');
        return {
          'success': false,
          'valid': false,
          'error': 'HTTP ошибка: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [Devino 2FA] Ошибка проверки кода: $e');
      return {
        'success': false,
        'valid': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  String getSmsStatusDescription(String status) {
    switch (status) {
      case '0':
        return 'Отправлено';
      case '1':
        return 'Доставлено';
      case '2':
        return 'Не доставлено';
      case '3':
        return 'В очереди';
      case '4':
        return 'Отклонено';
      case '5':
        return 'Истек срок действия';
      default:
        return 'Неизвестный статус: $status';
    }
  }
}
