import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static const String _directionsApiUrl = 'https://maps.googleapis.com/maps/api/directions/json';
  
  /// Получить текущее местоположение пользователя
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Службы геолокации отключены');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Разрешение на геолокацию отклонено');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Разрешение на геолокацию отклонено навсегда');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Создать случайную точку назначения в радиусе 50 метров
  Map<String, double> generateRandomDestination(double currentLat, double currentLng) {
    final random = Random();
    
    // 50 метров в градусах (приблизительно)
    const double radiusInDegrees = 0.00045; // ~50 метров
    
    // Генерируем случайный угол и расстояние
    final double angle = random.nextDouble() * 2 * pi;
    final double distance = random.nextDouble() * radiusInDegrees;
    
    // Вычисляем новые координаты
    final double destLat = currentLat + (distance * cos(angle));
    final double destLng = currentLng + (distance * sin(angle));
    
    return {
      'latitude': destLat,
      'longitude': destLng,
    };
  }

  /// Построить маршрут от текущего местоположения до случайной точки
  Future<Map<String, dynamic>> buildRoute(Position currentPosition) async {
    try {
      // Генерируем случайную точку назначения
      final destination = generateRandomDestination(
        currentPosition.latitude, 
        currentPosition.longitude,
      );

      // Строим маршрут через Google Directions API
      final String url = '$_directionsApiUrl?'
          'origin=${currentPosition.latitude},${currentPosition.longitude}&'
          'destination=${destination['latitude']},${destination['longitude']}&'
          'mode=driving&'
          'key=${ApiConfig.googleMapsApiKey}';

      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          
          return {
            'success': true,
            'route': route,
            'distance': leg['distance']['text'],
            'duration': leg['duration']['text'],
            'distanceValue': leg['distance']['value'], // в метрах
            'durationValue': leg['duration']['value'], // в секундах
            'polyline': route['overview_polyline']['points'],
            'startLocation': {
              'lat': currentPosition.latitude,
              'lng': currentPosition.longitude,
            },
            'endLocation': {
              'lat': destination['latitude']!,
              'lng': destination['longitude']!,
            },
            'steps': leg['steps'],
          };
        } else {
          throw Exception('Не удалось построить маршрут: ${data['status']}');
        }
      } else {
        throw Exception('Ошибка API: ${response.statusCode}');
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Декодировать polyline из Google Maps
  List<Map<String, double>> decodePolyline(String polyline) {
    List<Map<String, double>> coordinates = [];
    int index = 0;
    int len = polyline.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;

      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      coordinates.add({
        'latitude': lat / 1E5,
        'longitude': lng / 1E5,
      });
    }

    return coordinates;
  }

  /// Вычислить расстояние между двумя точками
  double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
  }

  /// Проверить, находится ли пользователь в пункте назначения (в радиусе 10 метров)
  bool isAtDestination(Position currentPosition, Map<String, double> destination) {
    final distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      destination['latitude']!,
      destination['longitude']!,
    );
    return distance <= 10.0; // 10 метров
  }
}
