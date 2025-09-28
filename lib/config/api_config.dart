class ApiConfig {
  static const String productionBaseUrl = 'http://192.168.1.4:8500';
  // static const String productionBaseUrl = 'https://superadmin.taxi.wazir.kg';
  static const String developmentBaseUrl = 'http://192.168.1.4:8500';
  static const String testBaseUrl = 'http://192.168.1.4:8500';
  
  static const ApiEnvironment currentEnvironment = ApiEnvironment.production;
  
  static String get baseUrl {
    switch (currentEnvironment) {
      case ApiEnvironment.production:
        return productionBaseUrl;
      case ApiEnvironment.development:
        return developmentBaseUrl;
      case ApiEnvironment.test:
        return productionBaseUrl; 
    }
  }

  static const Map<String, String> endpoints = {
    'test': '/',
    'sms_send': '/api/sms/send',
    'sms_status': '/api/sms/status',
    'driver_login': '/api/drivers/login',
    'driver_register': '/api/drivers/register',
    'driver_status': '/api/drivers/status',
    'taxiparks': '/api/parks',
    'auth_login': '/api/drivers/login',
    'auth_me': '/api/drivers/me',
    'photo_control_submit': '/api/photo-control/submit',
    'photo_control_status': '/api/photo-control/status',
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
