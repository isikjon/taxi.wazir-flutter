import 'dart:async';
import 'location_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  bool _isNavigating = false;
  Timer? _navigationTimer;
  Map<String, dynamic>? _currentRoute;

  bool get isNavigating => _isNavigating;
  Map<String, dynamic>? get currentRoute => _currentRoute;

  void initialize(dynamic context) {
    print('✅ [Navigation] Сервис навигации инициализирован');
  }

  Future<Map<String, dynamic>?> buildRoute(
    double startLat, double startLon,
    double endLat, double endLon,
  ) async {
    try {
      print('🔍 [Navigation] Строим маршрут от ($startLat, $startLon) до ($endLat, $endLon)');

      final distance = LocationService().calculateDistance(startLat, startLon, endLat, endLon);
      final duration = (distance / 50 * 60).round();

      _currentRoute = {
        'start_lat': startLat,
        'start_lon': startLon,
        'end_lat': endLat,
        'end_lon': endLon,
        'distance': distance,
        'duration': duration,
        'points': [
          {'lat': startLat, 'lon': startLon},
          {'lat': endLat, 'lon': endLon},
        ]
      };

      print('✅ [Navigation] Маршрут построен успешно');
      return _currentRoute;
    } catch (e) {
      print('❌ [Navigation] Ошибка построения маршрута: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> buildRouteToClient(
    double clientLat, double clientLon,
  ) async {
    final currentPos = LocationService().currentPosition;
    if (currentPos == null) {
      print('❌ [Navigation] Текущее местоположение неизвестно');
      return null;
    }

    return await buildRoute(
      currentPos.latitude,
      currentPos.longitude,
      clientLat,
      clientLon,
    );
  }

  Future<Map<String, dynamic>?> buildRouteToDestination(
    double destinationLat, double destinationLon,
  ) async {
    final currentPos = LocationService().currentPosition;
    if (currentPos == null) {
      print('❌ [Navigation] Текущее местоположение неизвестно');
      return null;
    }

    return await buildRoute(
      currentPos.latitude,
      currentPos.longitude,
      destinationLat,
      destinationLon,
    );
  }

  void startNavigation() {
    if (_isNavigating || _currentRoute == null) return;

    _isNavigating = true;
    print('🔍 [Navigation] Начинаем навигацию');

    _navigationTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      _checkNavigationProgress();
    });
  }

  void stopNavigation() {
    if (!_isNavigating) return;

    _isNavigating = false;
    _navigationTimer?.cancel();
    _navigationTimer = null;
    print('🔍 [Navigation] Останавливаем навигацию');
  }

  void _checkNavigationProgress() {
    if (_currentRoute == null) return;

    final currentPos = LocationService().currentPosition;
    if (currentPos == null) return;

    try {
      final endLat = _currentRoute!['end_lat'];
      final endLon = _currentRoute!['end_lon'];
      
      final distanceToEnd = LocationService().calculateDistance(
        currentPos.latitude,
        currentPos.longitude,
        endLat,
        endLon,
      );

      print('🔍 [Navigation] Расстояние до конца маршрута: ${distanceToEnd.toStringAsFixed(0)} м');

      if (distanceToEnd < 50) {
        print('✅ [Navigation] Прибыли в точку назначения');
        stopNavigation();
      }
    } catch (e) {
      print('❌ [Navigation] Ошибка проверки прогресса: $e');
    }
  }

  double? getRouteDistance() {
    return _currentRoute?['distance'];
  }

  int? getRouteDuration() {
    return _currentRoute?['duration'];
  }

  List<Map<String, double>>? getRoutePoints() {
    return _currentRoute?['points']?.cast<Map<String, double>>();
  }

  void clearRoute() {
    _currentRoute = null;
    stopNavigation();
    print('🔍 [Navigation] Маршрут очищен');
  }

  void dispose() {
    stopNavigation();
  }
}