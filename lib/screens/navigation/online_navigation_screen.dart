import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../main.dart' show sdkContext;
import '../../styles/app_colors.dart';
import '../../services/driver_status_service.dart';
import '../../services/route_service.dart';
import '../../services/location_detection_service.dart';
import '../../services/order_service.dart';
import '../../services/websocket_service.dart';
import '../../widgets/order_widget.dart';

class OnlineNavigationScreen extends StatefulWidget {
  const OnlineNavigationScreen({super.key});

  @override
  State<OnlineNavigationScreen> createState() => _OnlineNavigationScreenState();
}

class _OnlineNavigationScreenState extends State<OnlineNavigationScreen> with WidgetsBindingObserver {
  late sdk.MapWidgetController _mapController;
  late sdk.TrafficRouter _routeManager;

  sdk.Map? _map;
  sdk.NavigationManager? _navigationManager;
  sdk.MyLocationMapObjectSource? _locationSource;
  
  sdk.ManeuverController? _maneuverController;
  sdk.SpeedLimitController? _speedLimitController;
  sdk.ZoomController? _zoomController;
  sdk.CompassController? _compassController;
  sdk.MyLocationController? _myLocationController;
  sdk.DashboardController? _dashboardController;
  sdk.TrafficLineController? _trafficLineController;
  sdk.TrafficController? _trafficController;
  sdk.ParkingController? _parkingController;
  
  bool _isNavigationActive = false;
  bool _isLocationPermissionGranted = false;
  bool _areWidgetsReady = false;
  bool _isOnline = false;

  final RouteService _routeService = RouteService();
  final LocationDetectionService _locationDetectionService = LocationDetectionService();
  final OrderService _orderService = OrderService();
  final WebSocketService _webSocketService = WebSocketService();
  
  Map<String, dynamic>? _currentOrder;
  OrderWidgetState _orderWidgetState = OrderWidgetState.accepted;
  String? _estimatedArrival;
  String? _currentOrderStatus;
  String? _balanceErrorMessage;
  double? _requiredAmount;
  double? _currentBalance;
  
  final List<String> _logs = [];
  Timer? _heartbeatTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _addLog('🚀 Инициализация экрана навигации');
    _goOnline();
    _initializeMap();
    _initializeOrderHandling();
    _routeManager = sdk.TrafficRouter(sdkContext);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _addLog('🔄 Очистка ресурсов');
    _goOffline();
    if (_navigationManager != null && _isNavigationActive) {
      _navigationManager!.stop();
    }
    _routeService.dispose();
    _locationDetectionService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _addLog('📱 Приложение свернуто/закрыто - выход с линии');
        _goOffline();
        break;
      case AppLifecycleState.resumed:
        if (_isOnline) {
          _addLog('📱 Приложение восстановлено - возврат на линию');
          _goOnline();
        }
        break;
    }
  }

  void _addLog(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final logMessage = '[$timestamp] $message';
    print(logMessage);
    
    if (mounted) {
      setState(() {
        _logs.add(logMessage);
        if (_logs.length > 50) {
          _logs.removeAt(0);
        }
      });
    }
  }


  void _updateStatus(String status) {
    _addLog('📊 Статус: $status');
  }

  Future<void> _goOnline() async {
    if (_isOnline) return;
    
    try {
      _addLog('🟢 Выход на линию...');
      final result = await DriverStatusService().goOnline();
      if (result['success']) {
        setState(() {
          _isOnline = true;
        });
        _addLog('✅ Статус "на линии" установлен');
        _startHeartbeat();
      } else {
        _addLog('❌ Ошибка установки статуса: ${result['error']}');
      }
    } catch (e) {
      _addLog('❌ Ошибка выхода на линию: $e');
    }
  }

  Future<void> _goOffline() async {
    if (!_isOnline) return;
    
    try {
      _heartbeatTimer?.cancel();
      _addLog('🔴 Выход с линии...');
      final result = await DriverStatusService().goOffline();
      if (result['success']) {
        setState(() {
          _isOnline = false;
        });
        _addLog('✅ Статус "с линии" установлен');
      } else {
        _addLog('❌ Ошибка установки статуса: ${result['error']}');
      }
    } catch (e) {
      _addLog('❌ Ошибка выхода с линии: $e');
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline) {
        _addLog('💓 Heartbeat - подтверждение активности');
        DriverStatusService().goOnline();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _initializeMap() async {
    try {
      _addLog('🗺️ Начало инициализации карты');
      _updateStatus('Инициализация карты...');
      
      _mapController = sdk.MapWidgetController();
      _addLog('✅ MapWidgetController создан');
      
      bool mapReceived = false;
      
      _mapController.getMapAsync((map) {
        if (!mapReceived) {
          mapReceived = true;
          _addLog('🎯 Карта получена: успешно');
          _map = map;
          _setupMapSources();
        }
      });
      
      await Future.delayed(const Duration(seconds: 10));
      if (!mapReceived) {
        _addLog('⚠️ Таймаут инициализации карты, продолжаем без карты');
        _updateStatus('Карта не загружена');
      }
      
    } catch (e) {
      _addLog('❌ Ошибка инициализации карты: $e');
      _updateStatus('Ошибка инициализации карты');
    }
  }

  Future<void> _setupMapSources() async {
    if (_map == null) {
      _addLog('❌ Карта не инициализирована');
      return;
    }

    try {
      _addLog('🔧 Настройка источников карты');
      _updateStatus('Настройка карты...');
      
      _locationSource = sdk.MyLocationMapObjectSource(sdkContext);
      _map!.addSource(_locationSource!);
      _addLog('✅ Источник местоположения добавлен');
      
      _routeService.initialize(_map!);
      _addLog('✅ RouteService инициализирован');
      
      _initializeNavigationManager();
      _checkLocationPermissions();
      _centerMapOnCurrentLocation();
      
      _addLog('✅ Карта полностью инициализирована');
      
      Future.delayed(const Duration(milliseconds: 1000), () {
        _initializeWidgets();
      });
      
      _updateStatus('Готов к работе');
      
    } catch (e) {
      _addLog('❌ Ошибка настройки источников карты: $e');
      _updateStatus('Ошибка настройки карты');
    }
  }

  Future<void> _initializeNavigationManager() async {
    try {
      _addLog('🧭 Инициализация NavigationManager');
      
      _navigationManager = sdk.NavigationManager(sdkContext);
      _addLog('✅ NavigationManager создан');
      
      if (_map != null) {
        _navigationManager!.mapManager.addMap(_map!);
        _addLog('✅ Карта добавлена в NavigationManager');
      } else {
        _addLog('⚠️ Карта недоступна для NavigationManager');
      }
      
      _addLog('✅ NavigationManager готов к работе');
      _startFreeRoam();
      
    } catch (e) {
      _addLog('❌ Ошибка инициализации NavigationManager: $e');
    }
  }

  void _startFreeRoam() {
    try {
      if (_navigationManager != null) {
        _navigationManager!.startFreeRoam();
        _addLog('✅ Режим свободной навигации запущен');
        _updateStatus('Свободная навигация активна');
      }
    } catch (e) {
      _addLog('❌ Ошибка запуска свободной навигации: $e');
    }
  }

  Future<void> _checkLocationPermissions() async {
    try {
      _addLog('🔐 Проверка разрешений на геолокацию');
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      _addLog('📍 Сервис геолокации: ${serviceEnabled ? "включен" : "отключен"}');
      
      if (!serviceEnabled) {
        _addLog('⚠️ Сервис геолокации отключен');
        _updateStatus('Включите геолокацию');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      _addLog('🔑 Текущее разрешение: $permission');
      
      if (permission == LocationPermission.denied) {
        _addLog('📝 Запрос разрешения на геолокацию');
        permission = await Geolocator.requestPermission();
        _addLog('🔑 Новое разрешение: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        _addLog('❌ Разрешение на геолокацию отклонено навсегда');
        _updateStatus('Разрешение отклонено');
        return;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        setState(() {
          _isLocationPermissionGranted = true;
        });
        _addLog('✅ Разрешение на геолокацию получено');
      }
      
    } catch (e) {
      _addLog('❌ Ошибка проверки разрешений: $e');
    }
  }

  Future<void> _centerMapOnCurrentLocation() async {
    if (!_isLocationPermissionGranted || _map == null) {
      _addLog('⚠️ Невозможно центрировать карту - нет разрешений или карта не инициализирована');
      return;
    }

    try {
      _addLog('🎯 Получение текущего местоположения');
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _addLog('📍 Координаты: ${position.latitude}, ${position.longitude}');
      
      final camera = _map!.camera;
      await camera.move(
        sdk.GeoPoint(
          latitude: sdk.Latitude(position.latitude),
          longitude: sdk.Longitude(position.longitude),
        ),
        sdk.Zoom(16.0),
        sdk.Tilt(0.0),
        sdk.Bearing(0.0),
      );
      
      _addLog('✅ Карта центрирована на текущем местоположении');
      
    } catch (e) {
      _addLog('❌ Ошибка центрирования карты: $e');
      await _centerMapOnBishkek();
    }
  }

  Future<void> _centerMapOnBishkek() async {
    try {
      _addLog('🏙️ Центрирование на Бишкеке (fallback)');
      
      final camera = _map!.camera;
      await camera.move(
        sdk.GeoPoint(
          latitude: sdk.Latitude(42.8746),
          longitude: sdk.Longitude(74.5698),
        ),
        sdk.Zoom(12.0),
        sdk.Tilt(0.0),
        sdk.Bearing(0.0),
      );
      
      _addLog('✅ Карта центрирована на Бишкеке');
      
    } catch (e) {
      _addLog('❌ Ошибка центрирования на Бишкеке: $e');
    }
  }

  void _initializeWidgets() {
    try {
      _addLog('🎛️ Инициализация 2GIS виджетов');
      
      if (_navigationManager != null && _map != null) {
        _maneuverController = sdk.ManeuverController(navigationManager: _navigationManager!);
        _maneuverController = sdk.ManeuverController(
          navigationManager: _navigationManager!,
        );
        _speedLimitController = sdk.SpeedLimitController(navigationManager: _navigationManager!);
        _zoomController = sdk.ZoomController(map: _map!);
        _compassController = sdk.CompassController(map: _map!);
        _myLocationController = sdk.MyLocationController(map: _map!);
        _dashboardController = sdk.DashboardController(navigationManager: _navigationManager!, map: _map!);
        _trafficLineController = sdk.TrafficLineController(navigationManager: _navigationManager!);
        _trafficController = sdk.TrafficController(map: _map!);
        _parkingController = sdk.ParkingController(map: _map!);
        
        _addLog('✅ Контроллеры виджетов созданы');
      }
      
      setState(() {
        _areWidgetsReady = true;
      });
      
      _addLog('✅ 2GIS виджеты готовы к работе');
      
    } catch (e) {
      _addLog('❌ Ошибка инициализации виджетов: $e');
    }
  }

  void _initializeOrderHandling() {
    _webSocketService.messageStream.listen(_handleWebSocketMessage);
    _orderService.orderStream.listen(_handleOrderUpdate);
    _routeService.routeStream.listen(_handleRouteUpdate);
    _locationDetectionService.locationStream.listen(_handleLocationUpdate);
  }

  void _handleWebSocketMessage(Map<String, dynamic> message) {
    if (!mounted) return;
    
    if (message['type'] == 'new_order') {
      final orderData = message['data'];
      setState(() {
        _currentOrder = orderData;
        _orderWidgetState = OrderWidgetState.newOrder;
      });
      _addLog('📦 Получен новый заказ: ${orderData['order_number']}');
    } else if (message['type'] == 'order_status_update') {
      final orderData = message['data'];
      _handleOrderUpdate(orderData);
    }
  }

  void _handleOrderUpdate(Map<String, dynamic> order) {
    if (!mounted) return;
    
    if (order.isNotEmpty) {
      setState(() {
        _currentOrder = order;
        _currentOrderStatus = _getStatusText(order['status']);
        _orderWidgetState = _getOrderWidgetState(order['status']);
      });
      
      final status = order['status'];
      if (status == 'accepted') {
        _startLocationMonitoring();
      } else if (status == 'navigating_to_a') {
        _startNavigationToClient();
      } else if (status == 'navigating_to_b') {
        _startNavigationToDestination();
      } else if (status == 'completed') {
        _locationDetectionService.stopMonitoring();
        _routeService.clearRoute();
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _currentOrder = null;
              _orderWidgetState = OrderWidgetState.newOrder;
            });
          }
        });
      }
    } else {
      setState(() {
        _currentOrder = null;
        _orderWidgetState = OrderWidgetState.newOrder;
      });
      _locationDetectionService.stopMonitoring();
      _routeService.clearRoute();
    }
  }

  OrderWidgetState _getOrderWidgetState(String? status) {
    switch (status) {
      case 'received':
        return OrderWidgetState.newOrder;
      case 'accepted':
        return OrderWidgetState.accepted;
      case 'navigating_to_a':
        return OrderWidgetState.navigatingToA;
      case 'arrived_at_a':
        return OrderWidgetState.arrivedAtA;
      case 'navigating_to_b':
        return OrderWidgetState.navigatingToB;
      case 'completed':
        return OrderWidgetState.completed;
      default:
        return OrderWidgetState.newOrder;
    }
  }

  void _handleRouteUpdate(Map<String, dynamic> route) {
    if (!mounted) return;
    
    if (route.isNotEmpty) {
      setState(() {
        _estimatedArrival = _routeService.getEstimatedArrival();
      });
    }
  }

  void _handleLocationUpdate(Map<String, dynamic> location) {
    if (!mounted || _currentOrder == null) return;
    
    final status = _currentOrder!['status'];
    final nearPickup = location['near_pickup'] as bool;
    final nearDestination = location['near_destination'] as bool;
    
    if (status == 'navigating_to_a' && nearPickup) {
      setState(() {
        _orderWidgetState = OrderWidgetState.arrivedAtA;
      });
      _addLog('📍 Прибыли к клиенту');
    } else if (status == 'navigating_to_b' && nearDestination) {
      setState(() {
        _orderWidgetState = OrderWidgetState.completed;
      });
      _addLog('📍 Прибыли к точке назначения');
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'accepted':
        return 'Заказ принят';
      case 'navigating_to_a':
        return 'Едем к клиенту';
      case 'arrived_at_a':
        return 'Прибыли к клиенту';
      case 'navigating_to_b':
        return 'Везем клиента';
      case 'completed':
        return 'Заказ завершен';
      default:
        return 'Ожидание заказов';
    }
  }

  Future<void> _acceptOrder() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.acceptOrder(_currentOrder!['id']);
      _addLog('✅ Заказ принят: ${_currentOrder!['order_number']}');
    } catch (e) {
      if (e is InsufficientBalanceException) {
        setState(() {
          _orderWidgetState = OrderWidgetState.insufficientBalance;
          _balanceErrorMessage = e.message;
          _requiredAmount = e.requiredAmount;
          _currentBalance = e.currentBalance;
        });
        _addLog('❌ Недостаточно средств: ${e.message}');
      } else {
        _addLog('❌ Ошибка принятия заказа: $e');
      }
    }
  }

  Future<void> _rejectOrder() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.rejectOrder(_currentOrder!['id']);
      setState(() {
        _currentOrder = null;
        _orderWidgetState = OrderWidgetState.newOrder;
        _balanceErrorMessage = null;
        _requiredAmount = null;
        _currentBalance = null;
      });
      _addLog('❌ Заказ отклонен: ${_currentOrder!['order_number']}');
    } catch (e) {
      _addLog('❌ Ошибка отклонения заказа: $e');
    }
  }

  Future<void> _startNavigationToA() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.updateOrderStatusToServer('navigating_to_a');
      _startNavigationToClient();
      _addLog('🧭 Начинаем навигацию к клиенту');
    } catch (e) {
      _addLog('❌ Ошибка начала навигации: $e');
    }
  }

  Future<void> _arrivedAtClient() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.updateOrderStatusToServer('arrived_at_a');
      _addLog('📍 Прибыли к клиенту');

    } catch (e) {
      _addLog('❌ Ошибка обновления статуса: $e');
    }
  }

  Future<void> _startTrip() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.updateOrderStatusToServer('navigating_to_b');
      _startNavigationToDestination();
      _addLog('🚗 Начинаем поездку');
    } catch (e) {
      _addLog('❌ Ошибка начала поездки: $e');
    }
  }

  Future<void> _completeOrder() async {
    if (_currentOrder == null) return;
    
    try {
      await _orderService.updateOrderStatusToServer('completed');
      _navigationManager!.stop();
      _addLog('✅ Заказ завершен: ${_currentOrder!['order_number']}');
    } catch (e) {
      _addLog('❌ Ошибка завершения заказа: $e');
    }
  }

  Future<void> _startNavigationToClient() async {
    if (_currentOrder == null) return;
    
    final pickupLat = _currentOrder!['pickup_latitude'];
    final pickupLon = _currentOrder!['pickup_longitude'];
    
    if (pickupLat != null && pickupLon != null) {
      await _routeService.buildRouteToClient(pickupLat, pickupLon);
      _startLocationMonitoring();

      final options = sdk.RouteBuildOptions(
        finishPoint: sdk.RouteSearchPoint(
          coordinates: sdk.GeoPoint(
            latitude: sdk.Latitude(pickupLat),
            longitude: sdk.Longitude(pickupLon),
          ),
        ),
        routeSearchOptions: sdk.RouteSearchOptions.car(
          sdk.CarRouteSearchOptions(),
        ),
      );

       _navigationManager!.start(options);
      // _startSimulationToDestination(pickupLat, pickupLon);


      setState(() {
        _isNavigationActive = true;
      });
    }
  }

  Future<void> _startNavigationToDestination() async {
    if (_currentOrder == null) return;
    
    final destinationLat = _currentOrder!['destination_latitude'];
    final destinationLon = _currentOrder!['destination_longitude'];
    
    if (destinationLat != null && destinationLon != null) {
      await _routeService.buildRouteToDestination(destinationLat, destinationLon);

      final options = sdk.RouteBuildOptions(
        finishPoint: sdk.RouteSearchPoint(
          coordinates: sdk.GeoPoint(
            latitude: sdk.Latitude(destinationLat),
            longitude: sdk.Longitude(destinationLon),
          ),
        ),
        routeSearchOptions: sdk.RouteSearchOptions.car(
          sdk.CarRouteSearchOptions(),
        ),
      );

       _navigationManager!.start(options);

      // _startSimulationToDestination(destinationLat, destinationLon);

      setState(() {
        _isNavigationActive = true;
      });


    }
  }

  void _startLocationMonitoring() {
    if (_currentOrder == null) return;
    
    final pickupLat = _currentOrder!['pickup_latitude'];
    final pickupLon = _currentOrder!['pickup_longitude'];
    final destinationLat = _currentOrder!['destination_latitude'];
    final destinationLon = _currentOrder!['destination_longitude'];
    
    if (pickupLat != null && pickupLon != null) {
      _locationDetectionService.startMonitoring(
        pickupLat: pickupLat,
        pickupLon: pickupLon,
        destinationLat: destinationLat,
        destinationLon: destinationLon,
      );
    }
  }

  Future<void> _startSimulationToDestination(double lat, double lon) async {
    if (_navigationManager == null) return;

    final pickupLat = _currentOrder!['pickup_latitude'];
    final pickupLon = _currentOrder!['pickup_longitude'];
    final destinationLat = _currentOrder!['destination_latitude'];
    final destinationLon = _currentOrder!['destination_longitude'];

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final startPoint = sdk.RouteSearchPoint(
        coordinates: sdk.GeoPoint(
          latitude: sdk.Latitude(destinationLat),
          longitude: sdk.Longitude(destinationLon),
        ),
      );

      // final startPoint = sdk.RouteSearchPoint(
      //   coordinates: sdk.GeoPoint(
      //     latitude: sdk.Latitude(pickupLat),
      //     longitude: sdk.Longitude(pickupLon),
      //   ),
      // );

      final finishPoint = sdk.RouteSearchPoint(
        coordinates: sdk.GeoPoint(
          latitude: sdk.Latitude(lat),
          longitude: sdk.Longitude(lon),
        ),
      );

      final routeSearchOptions =
      sdk.RouteSearchOptions.car(sdk.CarRouteSearchOptions());

      final routeMapSource = sdk.RouteMapObjectSource(
        sdkContext,
        sdk.RouteVisualizationType.normal,
      );
      _map!.addSource(routeMapSource);

      // Строим маршрут через TrafficRouter
      final routes = await _routeManager
          .findRoute(startPoint, finishPoint, routeSearchOptions)
          .value;

      if (routes.isEmpty) {
        debugPrint("❌ Маршрут не найден");
        return;
      }

      // Берём первый маршрут
      final mainRoute = routes.first;

      // Добавляем на карту (основной + альтернативные)
      for (var i = 0; i < routes.length; i++) {
        final route = routes[i];
        routeMapSource.addObject(
          sdk.RouteMapObject(route, i == 0, sdk.RouteIndex(i)),
        );
      }

      // Настройка скорости симуляции (10 м/с ≈ 36 км/ч)
      _navigationManager?.simulationSettings.speedMode =
          sdk.SimulationSpeedMode.overSpeed(
            sdk.SimulationAutoWithOverSpeed(10),
          );

      // 🚗 Запускаем симуляцию по построенному маршруту
      final routeBuildOptions = sdk.RouteBuildOptions(
        finishPoint: finishPoint,
        routeSearchOptions: routeSearchOptions,
      );

       _navigationManager!.startSimulation(routeBuildOptions, mainRoute);

      setState(() => _isNavigationActive = true);
      debugPrint("✅ Симуляция маршрута запущена");
    } catch (e) {
      debugPrint("❌ Ошибка при запуске симуляции: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _addLog('🔙 Кнопка назад нажата - выход с линии');
        await _goOffline();
        return true;
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            secondary: AppColors.primary,
            surface: Colors.white,
            background: Colors.white,
            error: Colors.red,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            onBackground: Colors.black,
            onError: Colors.white,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
        body: Stack(
        children: [
          sdk.MapWidget(
            sdkContext: sdkContext,
            controller: _mapController,
            mapOptions: sdk.MapOptions(
              position: sdk.CameraPosition(
                point: sdk.GeoPoint(
                      latitude: sdk.Latitude(40.512911),
                  longitude: sdk.Longitude(72.806679
                  ),
                ),
                zoom: sdk.Zoom(12.0),
              ),
            ),
            child: Stack(
              children: [
                if (_areWidgetsReady) ...[
                  if (_isNavigationActive && _maneuverController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 80,
                      left: 16,
                      child: sdk.ManeuverWidget(
                        controller: _maneuverController!,
                      ),
                    ),
                  
                  if (_speedLimitController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 100,
                      right: 16,
                      child: sdk.SpeedLimitWidget(
                        controller: _speedLimitController!,
                      ),
                    ),
                  
                  if (_zoomController != null)
                    Positioned(
                      bottom: 220,
                      right: 16,
                      child: sdk.NavigationZoomWidget(
                        controller: _zoomController!,
                      ),
                    ),
                  //
                  // if (_compassController != null)
                  //   Positioned(
                  //     bottom: 340,
                  //     right: 16,
                  //     child: sdk.NavigationCompassWidget(
                  //       controller: _compassController!,
                  //     ),
                  //   ),
                  
                  if (_myLocationController != null)
                    Positioned(
                      bottom: 400,
                      right: 16,
                      child: sdk.NavigationMyLocationWidget(
                        controller: _myLocationController!,
                      ),
                    ),
                  
                  if (_trafficLineController != null)
                    Positioned(
                      bottom: _currentOrder == null ? 140 : 300,
                      left: 16,
                      child: sdk.TrafficLineWidget(
                        controller: _trafficLineController!,
                      ),
                    ),
                  
                  // if (_dashboardController != null)
                  //   Positioned(
                  //     bottom: 20,
                  //     left: 20,
                  //     right: 20,
                  //     child: Container(
                  //       constraints: const BoxConstraints(
                  //         minHeight: 60,
                  //         maxHeight: 120,
                  //       ),
                  //       child: sdk.DashboardWidget(
                  //         controller: _dashboardController!,
                  //         onHeaderChangeSize: (size) {},
                  //       ),
                  //     ),
                  //   ),
                  
                  if (_trafficController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 260,
                      left: 16,
                      child: sdk.NavigationTrafficWidget(
                        controller: _trafficController!,
                      ),
                    ),
                  
                  if (_parkingController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 320,
                      left: 16,
                      child: sdk.NavigationParkingWidget(
                        controller: _parkingController!,
                      ),
                    ),
                ],
              ],
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () async {
                  _addLog('❌ Кнопка закрытия нажата - выход с линии');
                  await _goOffline();
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.close, color: Colors.black),
              ),
            ),
          ),
          
              
              if (_currentOrder != null)
                OrderWidget(
                  orderData: _currentOrder!,
                  state: _orderWidgetState,
                  onAccept: _acceptOrder,
                  onReject: _rejectOrder,
                  onArrivedAtClient: _arrivedAtClient,
                  onStartTrip: _startTrip,
                  onCompleted: _completeOrder,
                  onStartNavigationToA: _startNavigationToA,
                  estimatedArrival: _estimatedArrival,
                  currentStatus: _currentOrderStatus,
                  balanceErrorMessage: _balanceErrorMessage,
                  requiredAmount: _requiredAmount,
                  currentBalance: _currentBalance,
                ),
        ],
      ),
      ),
      ),
    );
  }
}
