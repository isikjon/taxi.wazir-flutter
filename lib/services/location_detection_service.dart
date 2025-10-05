import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationDetectionService {
  static final LocationDetectionService _instance = LocationDetectionService._internal();
  factory LocationDetectionService() => _instance;
  LocationDetectionService._internal();

  StreamController<Map<String, dynamic>> _locationStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get locationStream => _locationStreamController.stream;

  StreamSubscription<Position>? _locationSubscription;
  bool _isMonitoring = false;
  
  double? _pickupLat;
  double? _pickupLon;
  double? _destinationLat;
  double? _destinationLon;
  
  static const double _arrivalRadius = 100.0;

  void startMonitoring({
    required double pickupLat,
    required double pickupLon,
    double? destinationLat,
    double? destinationLon,
  }) {
    _pickupLat = pickupLat;
    _pickupLon = pickupLon;
    _destinationLat = destinationLat;
    _destinationLon = destinationLon;
    
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    print('🔍 [LocationDetection] Начинаем мониторинг близости к точкам');
    
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen(_checkProximity);
  }

  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
    print('🔍 [LocationDetection] Останавливаем мониторинг близости');
  }

  void _checkProximity(Position position) {
    if (_pickupLat == null || _pickupLon == null) return;

    final currentLat = position.latitude;
    final currentLon = position.longitude;

    final distanceToPickup = Geolocator.distanceBetween(
      currentLat, currentLon,
      _pickupLat!, _pickupLon!,
    );

    final distanceToDestination = _destinationLat != null && _destinationLon != null
        ? Geolocator.distanceBetween(
            currentLat, currentLon,
            _destinationLat!, _destinationLon!,
          )
        : null;

    final event = <String, dynamic>{
      'current_lat': currentLat,
      'current_lon': currentLon,
      'distance_to_pickup': distanceToPickup,
      'distance_to_destination': distanceToDestination,
      'near_pickup': distanceToPickup <= _arrivalRadius,
      'near_destination': distanceToDestination != null && distanceToDestination <= _arrivalRadius,
    };

    _locationStreamController.add(event);

    if (distanceToPickup <= _arrivalRadius) {
      print('✅ [LocationDetection] Прибыли к точке А (${distanceToPickup.toStringAsFixed(1)} м)');
    }

    if (distanceToDestination != null && distanceToDestination <= _arrivalRadius) {
      print('✅ [LocationDetection] Прибыли к точке Б (${distanceToDestination.toStringAsFixed(1)} м)');
    }
  }

  bool isNearPickup(double currentLat, double currentLon) {
    if (_pickupLat == null || _pickupLon == null) return false;
    
    final distance = Geolocator.distanceBetween(
      currentLat, currentLon,
      _pickupLat!, _pickupLon!,
    );
    
    return distance <= _arrivalRadius;
  }

  bool isNearDestination(double currentLat, double currentLon) {
    if (_destinationLat == null || _destinationLon == null) return false;
    
    final distance = Geolocator.distanceBetween(
      currentLat, currentLon,
      _destinationLat!, _destinationLon!,
    );
    
    return distance <= _arrivalRadius;
  }

  double getDistanceToPickup(double currentLat, double currentLon) {
    if (_pickupLat == null || _pickupLon == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      currentLat, currentLon,
      _pickupLat!, _pickupLon!,
    );
  }

  double getDistanceToDestination(double currentLat, double currentLon) {
    if (_destinationLat == null || _destinationLon == null) return double.infinity;
    
    return Geolocator.distanceBetween(
      currentLat, currentLon,
      _destinationLat!, _destinationLon!,
    );
  }

  void dispose() {
    stopMonitoring();
    _locationStreamController.close();
  }
}
