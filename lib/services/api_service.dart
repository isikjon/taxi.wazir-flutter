import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/phone_utils.dart';
import 'devino_sms_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  ApiService._();

  // Регистрация нового водителя
  Future<Map<String, dynamic>> registerDriver(Map<String, dynamic> userData) async {
    try {
      // Нормализуем номер телефона в данных пользователя
      if (userData['user'] != null && userData['user']['phoneNumber'] != null) {
        final String originalPhone = userData['user']['phoneNumber'];
        final String normalizedPhone = PhoneUtils.normalizePhoneNumber(originalPhone);
        userData['user']['phoneNumber'] = normalizedPhone;
        print('📝 Registration - Original phone: $originalPhone');
        print('📝 Registration - Normalized phone: $normalizedPhone');
      }
      
      print('Sending registration data: $userData');
      
      final response = await http.post(
        Uri.parse(ApiConfig.getEndpointUrl('driver_register')),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(userData),
      );

      print('Registration response status: ${response.statusCode}');
      print('Registration response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка регистрации: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Авторизация водителя (пробуем разные эндпоинты)
  Future<Map<String, dynamic>> loginDriver(String phoneNumber, String smsCode) async {
    // Нормализуем номер телефона
    final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    print('🔑 Original phone: $phoneNumber');
    print('🔑 Normalized phone: $normalizedPhone');
    
    // Используем правильный эндпоинт для логина
    final List<Map<String, dynamic>> loginEndpoints = [
      {'path': '/api/drivers/login', 'params': {'phoneNumber': normalizedPhone, 'smsCode': smsCode}},
    ];

    for (Map<String, dynamic> config in loginEndpoints) {
      try {
        final String endpoint = config['path'];
        final Map<String, dynamic> params = config['params'];
        
        print('🔑 Trying login endpoint: ${ApiConfig.baseUrl}$endpoint');
        print('🔑 Login attempt for: $normalizedPhone with code: $smsCode');
        print('🔑 Using params: $params');
        
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}$endpoint'),
          headers: ApiConfig.defaultHeaders,
          body: json.encode(params),
        );

        print('🔑 Login [$endpoint] status: ${response.statusCode}');
        print('🔑 Login [$endpoint] body: ${response.body}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Логин успешен через: $endpoint');
          final data = json.decode(response.body);
          return {
            'success': true,
            'data': data,
            'isNewUser': data['isNewUser'] ?? data['is_new_user'] ?? false,
            'endpoint': endpoint,
          };
        } else if (response.statusCode != 404) {
          // Если не 404, значит эндпоинт найден, но есть другая ошибка
          String errorMessage = 'Ошибка авторизации';
          
          try {
            final errorData = json.decode(response.body);
            if (errorData['detail'] != null) {
              errorMessage = errorData['detail'];
            } else if (errorData['error'] != null) {
              errorMessage = errorData['error'];
            } else if (errorData['message'] != null) {
              errorMessage = errorData['message'];
            }
          } catch (e) {
            // Если не удалось распарсить JSON, используем стандартное сообщение
            if (response.statusCode == 400) {
              errorMessage = 'Неверный или истекший SMS код';
            } else if (response.statusCode == 401) {
              errorMessage = 'Ошибка авторизации';
            } else if (response.statusCode == 403) {
              errorMessage = 'Доступ запрещен';
            } else if (response.statusCode == 500) {
              errorMessage = 'Внутренняя ошибка сервера';
            }
          }
          
          return {
            'success': false,
            'error': errorMessage,
            'details': response.body,
            'endpoint': endpoint,
            'statusCode': response.statusCode,
          };
        }
      } catch (e) {
        print('❌ Login error [${config['path']}]: $e');
        continue;
      }
    }
    
    return {
      'success': false,
      'error': 'Не найден рабочий эндпоинт для авторизации. Проверьте документацию API.',
    };
  }

  // Отправка SMS кода через Backend API
  Future<Map<String, dynamic>> sendSmsCode(String phoneNumber) async {
    try {
      final normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      print('📱 [ApiService] Отправка SMS через Backend API для: $normalizedPhone');

      final response = await http.post(
        Uri.parse(ApiConfig.getEndpointUrl('sms_send')),
        headers: ApiConfig.defaultHeaders,
        body: json.encode({'phoneNumber': normalizedPhone}),
      );

      print('📱 [ApiService] SMS response status: ${response.statusCode}');
      print('📱 [ApiService] SMS response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ [ApiService] SMS успешно отправлен через Backend');
          return {
            'success': true,
            'data': responseData,
          };
        } else {
          print('❌ [ApiService] Backend вернул ошибку: ${responseData['detail']}');
          return {
            'success': false,
            'error': responseData['detail'] ?? 'Ошибка отправки SMS',
          };
        }
      } else {
        print('❌ [ApiService] HTTP ошибка: ${response.statusCode}');
        return {
          'success': false,
          'error': 'HTTP ошибка: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ [ApiService] Критическая ошибка отправки SMS: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Получить список таксопарков
  Future<Map<String, dynamic>> getParks() async {
    try {
      print('Fetching parks list');
      
      final response = await http.get(
        Uri.parse(ApiConfig.getEndpointUrl('taxiparks')),
        headers: ApiConfig.defaultHeaders,
      );

      print('Parks response status: ${response.statusCode}');
      print('Parks response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка загрузки парков: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Parks fetch error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Проверить статус SMS
  Future<Map<String, dynamic>> checkSmsStatus(String phoneNumber) async {
    try {
      // Нормализуем номер телефона
      final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
      print('📱 SMS Status - Original phone: $phoneNumber');
      print('📱 SMS Status - Normalized phone: $normalizedPhone');
      
      final response = await http.get(
        Uri.parse('${ApiConfig.getEndpointUrl('sms_status')}?phoneNumber=$normalizedPhone'),
        headers: ApiConfig.defaultHeaders,
      );

      print('SMS Status response status: ${response.statusCode}');
      print('SMS Status response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка проверки статуса SMS: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('SMS Status check error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Тестовое подключение к серверу
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('📶 Testing connection to server: $baseUrl');
      
      // Проверяем документацию API
      final docsResponse = await http.get(
        Uri.parse('$baseUrl/docs'),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.connectionTimeout);
      
      print('📶 Docs endpoint status: ${docsResponse.statusCode}');
      
      // Проверяем корневой эндпоинт
      final rootResponse = await http.get(
        Uri.parse(baseUrl),
        headers: ApiConfig.defaultHeaders,
      ).timeout(ApiConfig.connectionTimeout);
      
      print('📶 Root endpoint status: ${rootResponse.statusCode}');
      print('📶 Root response: ${rootResponse.body.substring(0, rootResponse.body.length > 200 ? 200 : rootResponse.body.length)}...');
      
      // Проверяем openapi.json для получения списка эндпоинтов
      try {
        final openapiResponse = await http.get(
          Uri.parse('$baseUrl/openapi.json'),
          headers: ApiConfig.defaultHeaders,
        ).timeout(ApiConfig.connectionTimeout);
        
        if (openapiResponse.statusCode == 200) {
          print('📶 OpenAPI spec found! Parsing endpoints...');
          final apiSpec = json.decode(openapiResponse.body);
          final paths = apiSpec['paths'] as Map<String, dynamic>?;
          if (paths != null) {
            print('📶 Available API endpoints:');
            paths.keys.take(10).forEach((path) {
              print('  - $path');
            });
          }
        }
      } catch (e) {
        print('📶 No OpenAPI spec found: $e');
      }

      if (rootResponse.statusCode == 200 || docsResponse.statusCode == 200) {
        return {
          'success': true,
          'data': {
            'status': 'Connected',
            'server': baseUrl,
            'docs_available': docsResponse.statusCode == 200,
            'root_status': rootResponse.statusCode,
          },
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка подключения: Root(${rootResponse.statusCode}), Docs(${docsResponse.statusCode})',
        };
      }
    } catch (e) {
      print('📶 Connection test error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Получить список таксопарков (обновленные эндпоинты)
  Future<Map<String, dynamic>> getTaxiparks() async {
    try {
      print('Fetching taxiparks list from new API');
      
      final response = await http.get(
        Uri.parse(ApiConfig.getEndpointUrl('taxiparks')),
        headers: ApiConfig.defaultHeaders,
      );

      print('Taxiparks response status: ${response.statusCode}');
      print('Taxiparks response body: ${response.body}');

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': json.decode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Ошибка загрузки таксопарков: ${response.statusCode}',
          'details': response.body,
        };
      }
    } catch (e) {
      print('Taxiparks fetch error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  // Получить информацию о API из документации
  static Future<void> printApiInfo() async {
    print('\n🌐 =============== API INFO ===============');
    print('🌐 Base URL: ${ApiConfig.baseUrl}');
    print('🌐 Environment: ${ApiConfig.currentEnvironment}');
    print('🌐 Documentation: ${ApiConfig.baseUrl}/docs');
    print('🌐 Available endpoints:');
    
    ApiConfig.endpoints.forEach((key, value) {
      print('  - $key: ${ApiConfig.baseUrl}$value');
    });
    
    print('🌐 ==========================================\n');
    
    // Тестируем подключение
    final testResult = await ApiService.instance.testConnection();
    if (testResult['success']) {
      print('✅ Server connection: OK');
    } else {
      print('❌ Server connection failed: ${testResult['error']}');
    }
    print('');
  }
}