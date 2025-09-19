import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../../models/order_model.dart';
import '../../services/navigation_service.dart';
// import '../../services/order_service.dart';
// import '../../styles/app_theme.dart';
import '../../styles/app_colors.dart';
import '../../main.dart' show sdkContext;

class NavigationScreen extends StatefulWidget {
  final OrderModel order;
  final int driverId;

  const NavigationScreen({
    super.key,
    required this.order,
    required this.driverId,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  late NavigationService _navigationService;
  String _currentStatus = 'idle';
  String _statusText = '';
  late sdk.MapWidgetController _mapController;
  late sdk.NavigationManager _navigationManager;
  sdk.Map? _map;
  StreamSubscription? _navStateSubscription;

  @override
  void initState() {
    super.initState();
    _navigationService = NavigationService();
    _setupNavigation();
    _initializeMapAndNavigation();
  }

  void _setupNavigation() {
    _navigationService.initialize(null);
    _navigationService.statusStream.listen((status) {
      setState(() {
        _currentStatus = status;
        _statusText = _getStatusText(status);
      });
      if (status == 'completed' || status == 'cancelled') {
        Navigator.of(context).pop();
      }
    });
    _navigationService.startNavigation(widget.order, widget.driverId);
  }

  void _initializeMapAndNavigation() {
    try {
      _mapController = sdk.MapWidgetController();
      _navigationManager = sdk.NavigationManager(sdkContext);
      
      _mapController.getMapAsync((map) {
        _map = map;
        _navigationManager.mapManager.addMap(map);
        _setupLocationSource();
        _subscribeNavigationState();
        _startNavigation();
      });
    } catch (e) {
      print('Ошибка инициализации карты и навигации: $e');
    }
  }

  void _setupLocationSource() {
    if (_map != null) {
      try {
        final locationSource = sdk.MyLocationMapObjectSource(sdkContext);
        _map!.addSource(locationSource);
        
        _centerMapOnCurrentLocation();
      } catch (e) {
        print('Ошибка настройки источника местоположения: $e');
      }
    }
  }

  void _centerMapOnCurrentLocation() async {
    try {
      final camera = _map!.camera;
      final targetPoint = sdk.GeoPoint(
        latitude: sdk.Latitude(42.8746),
        longitude: sdk.Longitude(74.5698),
      );
      
      await camera.move(
        targetPoint,
        sdk.Zoom(18.0),
        sdk.Tilt(0.0),
        sdk.Bearing(0.0),
      );
    } catch (e) {
      print('Ошибка центрирования карты: $e');
    }
  }

  void _startNavigation() {
    try {
      final order = widget.order;

      // Сначала ведем к точке A (подача)
      final routeToA = sdk.RouteBuildOptions(
        finishPoint: sdk.RouteSearchPoint(
          coordinates: sdk.GeoPoint(
            latitude: sdk.Latitude(order.pickupLatitude!),
            longitude: sdk.Longitude(order.pickupLongitude!),
          ),
        ),
        routeSearchOptions: sdk.RouteSearchOptions.car(
          sdk.CarRouteSearchOptions(),
        ),
      );

      _navigationManager.start(routeToA);
    } catch (e) {
      print('Ошибка запуска навигации: $e');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'navigating_to_a':
        return 'Едем к точке А';
      case 'arrived_at_a':
        return 'Прибыли в точку А';
      case 'navigating_to_b':
        return 'Едем к точке Б';
      case 'completed':
        return 'Заказ завершен';
      default:
        return 'Ожидание';
    }
  }

  void _subscribeNavigationState() {
    try {
      _navStateSubscription = _navigationManager.uiModel.stateChannel.listen((state) {
        // Когда доехали до точки A — строим маршрут до B
        if (_currentStatus == 'navigating_to_a' || _currentStatus == 'idle') {
          // Переводим наш сервис в состояние «едем к А» при старте навигации
          if (_currentStatus == 'idle') {
            setState(() {
              _currentStatus = 'navigating_to_a';
              _statusText = _getStatusText(_currentStatus);
            });
          }
        }
      });
    } catch (e) {
      // Если канал недоступен в текущей версии SDK — просто не подписываемся
      print('Не удалось подписаться на состояние навигации: $e');
    }
  }

  Future<void> _cancelOrder() async {
    try {
      await _navigationService.cancelCurrentOrder();
    } catch (e) {
      print('Ошибка отмены заказа: $e');
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          sdk.MapWidget(
            sdkContext: sdkContext,
            mapOptions: sdk.MapOptions(
              position: sdk.CameraPosition(
                point: sdk.GeoPoint(
                  latitude: sdk.Latitude(42.8746),
                  longitude: sdk.Longitude(74.5698),
                ),
                zoom: sdk.Zoom(18.0),
              ),
            ),
            controller: _mapController,
          ),
          
          // 2GIS UI Widgets «из коробки» — обернуты в Theme для корректного colorScheme
          Positioned(
            bottom: 120,
            right: 16,
            child: Material(
              type: MaterialType.transparency,
              child: Theme(
                data: Theme.of(context),
                child: Column(
                  children: [
                    // ZoomWidget - масштабирование
                    const sdk.ZoomWidget(),
                    const SizedBox(height: 8),
                    
                    // CompassWidget - компас  
                    const sdk.CompassWidget(),
                    const SizedBox(height: 8),
                    
                    // MyLocationWidget - текущее местоположение
                    const sdk.MyLocationWidget(),
                  ],
                ),
              ),
            ),
          ),
          
          // Indoor / Traffic — верхние контролы
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
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
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_taxi,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Заказ #${widget.order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _cancelOrder,
                        icon: const Icon(Icons.close, color: Colors.red),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _statusText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Theme(
                        data: Theme.of(context),
                        child: const sdk.IndoorWidget(),
                      ),
                      const SizedBox(width: 8),
                      Theme(
                        data: Theme.of(context),
                        child: const sdk.TrafficWidget(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Навигационные UI-виджеты будут добавлены после проверки версии SDK и ключа
        ],
      ),
    );
  }

  @override
  void dispose() {
    _navigationService.dispose();
    try {
      _navStateSubscription?.cancel();
      _navigationManager.stop();
      if (_map != null) {
        _navigationManager.mapManager.removeMap(_map!);
      }
    } catch (_) {}
    super.dispose();
  }
}