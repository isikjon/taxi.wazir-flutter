import 'dart:async';
import '../models/order_model.dart';
import '../models/location_model.dart';
import 'order_service.dart';
import 'websocket_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  dynamic _navigationManager;
  dynamic _trafficRouter;
  dynamic _locationService;
  dynamic _map;

  OrderModel? _currentOrder;
  String _currentStatus = 'idle';
  LocationModel? _currentLocation;
  LocationModel? _pointA;
  LocationModel? _pointB;

  final StreamController<String> _statusController = StreamController<String>.broadcast();
  final StreamController<LocationModel> _locationController = StreamController<LocationModel>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<LocationModel> get locationStream => _locationController.stream;

  String get currentStatus => _currentStatus;
  OrderModel? get currentOrder => _currentOrder;

  void initialize(dynamic map) {
    _map = map;
    try {
      _navigationManager = null;
      _trafficRouter = null;
      _locationService = null;
      _startLocationTracking();
    } catch (e) {
      print('Navigation initialization error: $e');
    }
  }

  void _startLocationTracking() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentOrder != null) {
        _checkArrival();
      }
    });
  }

  void _checkArrival() {
    if (_currentLocation == null || _currentOrder == null) return;

    if (_currentStatus == 'navigating_to_a' && _pointA != null) {
      if (_currentLocation!.isNear(_pointA!, 1.0)) {
        _onArrivedAtA();
      }
    } else if (_currentStatus == 'navigating_to_b' && _pointB != null) {
      if (_currentLocation!.isNear(_pointB!, 1.0)) {
        _onArrivedAtB();
      }
    }
  }

  Future<void> startNavigation(OrderModel order, int driverId) async {
    _currentOrder = order;
    _pointA = LocationModel(
      latitude: order.pickupLatitude!,
      longitude: order.pickupLongitude!,
      timestamp: DateTime.now(),
    );
    _pointB = LocationModel(
      latitude: order.destinationLatitude!,
      longitude: order.destinationLongitude!,
      timestamp: DateTime.now(),
    );

    await _buildRouteToA();
    await _startNavigationToA(driverId);
  }

  Future<void> _buildRouteToA() async {
    print('Building route to point A');
  }

  Future<void> _buildRouteToB() async {
    print('Building route to point B');
  }

  Future<void> _startNavigationToA(int driverId) async {
    _currentStatus = 'navigating_to_a';
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
    
    if (_currentOrder != null) {
      await OrderService().startNavigationToA(_currentOrder!.id, driverId);
      await WebSocketService().sendOrderStatus(_currentOrder!.id, 'navigating_to_a');
    }
  }

  Future<void> _onArrivedAtA() async {
    if (_currentOrder == null) return;

    _currentStatus = 'arrived_at_a';
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
    
    await OrderService().arrivedAtA(_currentOrder!.id, _currentOrder!.driverId!);
    await WebSocketService().sendOrderStatus(_currentOrder!.id, 'arrived_at_a');

    await Future.delayed(const Duration(seconds: 2));
    await _startNavigationToB();
  }

  Future<void> _startNavigationToB() async {
    if (_currentOrder == null) return;

    await _buildRouteToB();
    
    _currentStatus = 'navigating_to_b';
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
    
    await OrderService().startNavigationToB(_currentOrder!.id, _currentOrder!.driverId!);
    await WebSocketService().sendOrderStatus(_currentOrder!.id, 'navigating_to_b');
  }

  Future<void> _onArrivedAtB() async {
    if (_currentOrder == null) return;

    _currentStatus = 'completed';
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
    
    await OrderService().completeOrder(_currentOrder!.id, _currentOrder!.driverId!);
    await WebSocketService().sendOrderStatus(_currentOrder!.id, 'completed');

    _stopNavigation();
  }

  Future<void> cancelNavigation(int driverId) async {
    if (_currentOrder != null) {
      await OrderService().cancelOrder(_currentOrder!.id, driverId);
      await WebSocketService().sendOrderStatus(_currentOrder!.id, 'cancelled');
    }
    
    _stopNavigation();
  }

  Future<void> cancelCurrentOrder() async {
    if (_currentOrder != null && _currentOrder!.driverId != null) {
      await cancelNavigation(_currentOrder!.driverId!);
    } else {
      _stopNavigation();
    }
  }

  void _stopNavigation() {
    _currentOrder = null;
    _currentStatus = 'idle';
    _pointA = null;
    _pointB = null;
    if (!_statusController.isClosed) {
      _statusController.add(_currentStatus);
    }
  }

  void dispose() {
    if (!_statusController.isClosed) {
      _statusController.close();
    }
    if (!_locationController.isClosed) {
      _locationController.close();
    }
    _stopNavigation();
  }
}