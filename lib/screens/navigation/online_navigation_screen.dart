import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:geolocator/geolocator.dart';
import '../../main.dart' show sdkContext;
import '../../styles/app_colors.dart';
import '../../services/driver_status_service.dart';

class OnlineNavigationScreen extends StatefulWidget {
  const OnlineNavigationScreen({super.key});

  @override
  State<OnlineNavigationScreen> createState() => _OnlineNavigationScreenState();
}

class _OnlineNavigationScreenState extends State<OnlineNavigationScreen> with WidgetsBindingObserver {
  late sdk.MapWidgetController _mapController;
  sdk.Map? _map;
  sdk.NavigationManager? _navigationManager;
  sdk.MyLocationMapObjectSource? _locationSource;
  
  // Контроллеры для виджетов 2ГИС
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
  String _currentStatus = 'Инициализация...';
  bool _isFreeRoamActive = false;
  bool _isOnline = false;

  // Переменные для навигации
  sdk.TrafficRouter? _trafficRouter;
  sdk.RouteMapObjectSource? _routeSource;
  
  // Логирование
  final List<String> _logs = [];
  
  // Heartbeat для подтверждения активности
  Timer? _heartbeatTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _addLog('🚀 Инициализация экрана навигации');
    _goOnline();
    _initializeMap();
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
    if (mounted) {
      setState(() {
        _currentStatus = status;
      });
    }
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
      
      // Устанавливаем таймаут для инициализации карты
      bool mapReceived = false;
      
      _mapController.getMapAsync((map) {
        if (!mapReceived) {
          mapReceived = true;
          _addLog('🎯 Карта получена: успешно');
          _map = map;
          _setupMapSources();
        }
      });
      
      // Таймаут 10 секунд
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
      
      // Настройка источника местоположения
      _locationSource = sdk.MyLocationMapObjectSource(sdkContext);
      _map!.addSource(_locationSource!);
      _addLog('✅ Источник местоположения добавлен');
      
      // Инициализация TrafficRouter для построения маршрутов
      _trafficRouter = sdk.TrafficRouter(sdkContext);
      _routeSource = sdk.RouteMapObjectSource(sdkContext, sdk.RouteVisualizationType.normal);
      _map!.addSource(_routeSource!);
      _addLog('✅ TrafficRouter и RouteSource инициализированы');
      
      // Инициализация NavigationManager
      _initializeNavigationManager();
      
      // Проверка разрешений на геолокацию
      _checkLocationPermissions();
      
      // Центрирование карты
      _centerMapOnCurrentLocation();
      
      
      _addLog('✅ Карта полностью инициализирована');
      
      // Инициализируем виджеты после небольшой задержки
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
      
      // Добавляем карту в NavigationManager только если карта доступна
      if (_map != null) {
        _navigationManager!.mapManager.addMap(_map!);
        _addLog('✅ Карта добавлена в NavigationManager');
      } else {
        _addLog('⚠️ Карта недоступна для NavigationManager');
      }
      
      _addLog('✅ NavigationManager готов к работе');
      
      // Запускаем режим свободной навигации
      _startFreeRoam();
      
    } catch (e) {
      _addLog('❌ Ошибка инициализации NavigationManager: $e');
      // Не бросаем исключение, продолжаем работу
    }
  }

  void _startFreeRoam() {
    try {
      if (_navigationManager != null) {
        _navigationManager!.startFreeRoam();
        _isFreeRoamActive = true;
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
      // Центрируем на Бишкеке как fallback
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
        // Создаем контроллеры для виджетов 2ГИС
        _maneuverController = sdk.ManeuverController(navigationManager: _navigationManager!);
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






  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _addLog('🔙 Кнопка назад нажата - выход с линии');
        await _goOffline();
        return true;
      },
      child: MaterialApp(
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
          // 2GIS карта на весь экран с виджетами
          sdk.MapWidget(
            sdkContext: sdkContext,
            controller: _mapController,
            mapOptions: sdk.MapOptions(
              position: sdk.CameraPosition(
                point: sdk.GeoPoint(
                  latitude: sdk.Latitude(42.8746), // Бишкек
                  longitude: sdk.Longitude(74.5698),
                ),
                zoom: sdk.Zoom(12.0),
              ),
            ),
            child: Stack(
              children: [
                // Виджеты 2ГИС навигации
                if (_areWidgetsReady) ...[
                  // 1. ManeuverWidget для отображения информации о следующем манёвре
                  if (_maneuverController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 80,
                      left: 16,
                      child: sdk.ManeuverWidget(
                        controller: _maneuverController!,
                      ),
                    ),
                  
                  // 2. SpeedLimitWidget для отображения текущей скорости и скоростного ограничения
                  if (_speedLimitController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 140,
                      right: 16,
                      child: sdk.SpeedLimitWidget(
                        controller: _speedLimitController!,
                      ),
                    ),
                  
                  // 3. NavigationZoomWidget для масштабирования карты
                  if (_zoomController != null)
                    Positioned(
                      bottom: 220,
                      right: 16,
                      child: sdk.NavigationZoomWidget(
                        controller: _zoomController!,
                      ),
                    ),
                  
                  // 4. NavigationCompassWidget для отображения угла поворота карты
                  if (_compassController != null)
                    Positioned(
                      bottom: 340,
                      right: 16,
                      child: sdk.NavigationCompassWidget(
                        controller: _compassController!,
                      ),
                    ),
                  
                  // 5. NavigationMyLocationWidget для управления слежением за местоположением
                  if (_myLocationController != null)
                    Positioned(
                      bottom: 400,
                      right: 16,
                      child: sdk.NavigationMyLocationWidget(
                        controller: _myLocationController!,
                      ),
                    ),
                  
                  // 6. TrafficLineWidget для отображения уровня пробок на маршруте
                  if (_trafficLineController != null)
                    Positioned(
                      bottom: 140,
                      left: 16,
                      child: sdk.TrafficLineWidget(
                        controller: _trafficLineController!,
                      ),
                    ),
                  
                  // 7. DashboardWidget для отображения информации в режиме свободной навигации
                  if (_dashboardController != null)
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        constraints: const BoxConstraints(
                          minHeight: 60,
                          maxHeight: 120,
                        ),
                        child: sdk.DashboardWidget(
                          controller: _dashboardController!,
                          onHeaderChangeSize: (size) {},
                        ),
                      ),
                    ),
                  
                  // 8. NavigationTrafficWidget для управления видимостью пробок на карте
                  if (_trafficController != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 260,
                      left: 16,
                      child: sdk.NavigationTrafficWidget(
                        controller: _trafficController!,
                      ),
                    ),
                  
                  // 9. NavigationParkingWidget для управления видимостью парковок на карте
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
          
          // Кнопка закрытия
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
          
        ],
      ),
      ),
      ),
    );
  }
}
