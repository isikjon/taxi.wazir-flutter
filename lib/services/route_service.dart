import 'dart:async';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:geolocator/geolocator.dart';
import '../main.dart' show sdkContext;

class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  sdk.TrafficRouter? _trafficRouter;
  sdk.RouteMapObjectSource? _routeSource;
  sdk.Map? _map;
  
  StreamController<Map<String, dynamic>> _routeStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get routeStream => _routeStreamController.stream;

  Map<String, dynamic>? _currentRoute;
  Map<String, dynamic>? get currentRoute => _currentRoute;

  void initialize(sdk.Map map) {
    _map = map;
    _trafficRouter = sdk.TrafficRouter(sdkContext);
    _routeSource = sdk.RouteMapObjectSource(sdkContext, sdk.RouteVisualizationType.normal);
    _map!.addSource(_routeSource!);
    print('✅ [RouteService] Инициализирован с картой');
  }

  Future<Map<String, dynamic>?> buildRouteToClient(
    double clientLat, double clientLon,
  ) async {
    try {
      final currentPos = await _getCurrentPosition();
      if (currentPos == null) {
        print('❌ [RouteService] Текущее местоположение неизвестно');
        return null;
      }

      return await _buildRoute(
        currentPos.latitude,
        currentPos.longitude,
        clientLat,
        clientLon,
        'to_client',
      );
    } catch (e) {
      print('❌ [RouteService] Ошибка построения маршрута к клиенту: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> buildRouteToDestination(
    double destinationLat, double destinationLon,
  ) async {
    try {
      final currentPos = await _getCurrentPosition();
      if (currentPos == null) {
        print('❌ [RouteService] Текущее местоположение неизвестно');
        return null;
      }

      return await _buildRoute(
        currentPos.latitude,
        currentPos.longitude,
        destinationLat,
        destinationLon,
        'to_destination',
      );
    } catch (e) {
      print('❌ [RouteService] Ошибка построения маршрута к назначению: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _buildRoute(
    double startLat, double startLon,
    double endLat, double endLon,
    String routeType,
  ) async {
    if (_trafficRouter == null || _routeSource == null) {
      print('❌ [RouteService] TrafficRouter или RouteSource не инициализированы');
      return null;
    }

    try {
      print('🔍 [RouteService] Строим маршрут $routeType от ($startLat, $startLon) до ($endLat, $endLon)');

      final startPoint = sdk.RouteSearchPoint(
        coordinates: sdk.GeoPoint(
          latitude: sdk.Latitude(startLat),
          longitude: sdk.Longitude(startLon),
        ),
      );

      final endPoint = sdk.RouteSearchPoint(
        coordinates: sdk.GeoPoint(
          latitude: sdk.Latitude(endLat),
          longitude: sdk.Longitude(endLon),
        ),
      );

      final routeSearchOptions = sdk.RouteSearchOptions.car(
        sdk.CarRouteSearchOptions(),
      );

      final routesFuture = _trafficRouter!.findRoute(
        startPoint,
        endPoint,
        routeSearchOptions,
      );

      final routes = await routesFuture.value;
      
      if (routes.isNotEmpty) {
        final route = routes.first;
        
        _routeSource!.clear();
        _routeSource!.addObject(sdk.RouteMapObject(route, true, sdk.RouteIndex(0)));
        
        final routeInfo = {
          'type': routeType,
          'start_lat': startLat,
          'start_lon': startLon,
          'end_lat': endLat,
          'end_lon': endLon,
          'distance': 0.0,
          'duration': 0,
          'route': route,
        };

        _currentRoute = routeInfo;
        _routeStreamController.add(routeInfo);
        
        print('✅ [RouteService] Маршрут $routeType построен успешно');
        print('📏 [RouteService] Маршрут построен');
        print('⏱️ [RouteService] Маршрут готов');
        
        return routeInfo;
      } else {
        print('❌ [RouteService] Маршрут $routeType не найден');
        return null;
      }
    } catch (e) {
      print('❌ [RouteService] Ошибка построения маршрута $routeType: $e');
      return null;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ [RouteService] Сервис геолокации отключен');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('❌ [RouteService] Разрешение на геолокацию отклонено');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('❌ [RouteService] Разрешение на геолокацию отклонено навсегда');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ [RouteService] Ошибка получения местоположения: $e');
      return null;
    }
  }

  void clearRoute() {
    if (_routeSource != null) {
      _routeSource!.clear();
    }
    _currentRoute = null;
    _routeStreamController.add({});
    print('🔍 [RouteService] Маршрут очищен');
  }

  bool isNearLocation(
    double currentLat, double currentLon,
    double targetLat, double targetLon,
    double radiusMeters,
  ) {
    final distance = Geolocator.distanceBetween(
      currentLat, currentLon,
      targetLat, targetLon,
    );
    return distance <= radiusMeters;
  }

  String? getEstimatedArrival() {
    if (_currentRoute == null) return null;
    
    final duration = _currentRoute!['duration'] as int;
    final minutes = (duration / 60).ceil();
    
    if (minutes <= 1) {
      return 'Прибытие через 1 минуту';
    } else if (minutes < 60) {
      return 'Прибытие через $minutes минут';
    } else {
      final hours = (minutes / 60).floor();
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return 'Прибытие через $hours час${hours == 1 ? '' : hours < 5 ? 'а' : 'ов'}';
      } else {
        return 'Прибытие через $hours ч $remainingMinutes мин';
      }
    }
  }

  void dispose() {
    clearRoute();
    _routeStreamController.close();
  }
}
