class ApiConfig {
  // Основные URL серверов
  static const String productionBaseUrl = 'https://new.superadmin.taxi.wazir.kg';
  static const String developmentBaseUrl = 'http://127.0.0.1:8080';
  // static const String testBaseUrl = 'https://test.superadmin.taxi.wazir.kg';
  
  // Текущий режим (можно менять для тестирования)
  static const ApiEnvironment currentEnvironment = ApiEnvironment.production;
  
  // Получить текущий базовый URL
  static String get baseUrl {
    switch (currentEnvironment) {
      case ApiEnvironment.production:
        return productionBaseUrl;
      case ApiEnvironment.development:
        return developmentBaseUrl;
      case ApiEnvironment.test:
        return productionBaseUrl; // Используем продакшн как тест
    }
  }

  // API endpoints
  static const Map<String, String> endpoints = {
    'test': '/test',
    'sms_send': '/auth/send-sms',     // Исправлен на правильный эндпоинт
    'sms_status': '/auth/verify-sms', // Исправлен на правильный эндпоинт
    'driver_login': '/auth/login',    // Исправлен на правильный эндпоинт
    'driver_register': '/api/drivers/register',
    'taxiparks': '/superadmin/api/taxiparks/',
    'auth_login': '/auth/login',
    'auth_me': '/auth/me',
  };
  
  // Получить полный URL для эндпоинта
  static String getEndpointUrl(String endpoint) {
    final path = endpoints[endpoint];
    if (path == null) {
      throw ArgumentError('Unknown endpoint: $endpoint');
    }
    return '$baseUrl$path';
  }
  
  // HTTP заголовки по умолчанию
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'VoditelTaxiApp/1.0.0',
  };
  
  // Тайм-ауты
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  
  // Отладка
  static const bool enableLogging = true;
  static const bool enableDebugMode = true;
  
  // Google Maps API
  static const String googleMapsApiKey = 'AIzaSyCgctqtqKOus6A6cDJaOBqsyo4-3r3zuQA';
  
  // Метод для быстрого переключения режимов (для отладки)
  static void switchToDevelopment() {
    // В реальном приложении это можно сделать через настройки
    print('🔄 API переключен на development режим: $developmentBaseUrl');
  }
  
  static void switchToProduction() {
    // В реальном приложении это можно сделать через настройки
    print('🔄 API переключен на production режим: $productionBaseUrl');
  }
}

enum ApiEnvironment {
  production,
  development, 
 test,
}
