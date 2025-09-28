import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'websocket_service.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamController<Position> _locationController = StreamController.broadcast();
  Stream<Position> get locationStream => _locationController.stream;

  Timer? _locationTimer;
  Position? _currentPosition;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;

  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status == PermissionStatus.granted;
  }

  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ [Location] Нет разрешения на геолокацию');
        return null;
      }

      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        print('❌ [Location] Служба геолокации отключена');
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      print('❌ [Location] Ошибка получения местоположения: $e');
      return null;
    }
  }

  void startLocationTracking() {
    if (_isTracking) return;

    _isTracking = true;
    print('🔍 [Location] Начинаем отслеживание местоположения');

    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      final position = await getCurrentPosition();
      if (position != null) {
        _locationController.add(position);
        _sendLocationToServer(position);
      }
    });
  }

  void stopLocationTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    print('🔍 [Location] Останавливаем отслеживание местоположения');
  }

  void _sendLocationToServer(Position position) {
    try {
      WebSocketService().sendMessage({
        'type': 'location_update',
        'location': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        }
      });
    } catch (e) {
      print('❌ [Location] Ошибка отправки местоположения: $e');
    }
  }

  double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  bool isNearLocation(
    double currentLat, double currentLon,
    double targetLat, double targetLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(currentLat, currentLon, targetLat, targetLon);
    return distance <= radiusMeters;
  }

  Future<double> getDistanceToPoint(double targetLat, double targetLon) async {
    if (_currentPosition == null) {
      final position = await getCurrentPosition();
      if (position == null) return 0.0;
    }

    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      targetLat,
      targetLon,
    );
  }

  void dispose() {
    stopLocationTracking();
    _locationController.close();
  }
}
