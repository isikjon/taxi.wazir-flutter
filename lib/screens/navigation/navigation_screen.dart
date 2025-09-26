import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:geolocator/geolocator.dart';
import '../../models/order_model.dart';
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
  late sdk.MapWidgetController _mapController;
  sdk.Map? _map;
  sdk.MyLocationMapObjectSource? _locationSource;
  bool _isLocationCentered = false;
  
  // 2GIS виджеты не требуют контроллеров в версии 12.8.0

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initializeMap() {
    try {
      _mapController = sdk.MapWidgetController();
      
      _mapController.getMapAsync((map) {
        print('Карта получена: $map');
        _map = map;
        if (_map != null) {
          _setupMapSources();
        }
      });
    } catch (e) {
      print('Ошибка инициализации карты: $e');
    }
  }

  void _setupMapSources() {
    if (_map != null) {
      try {
        print('Настройка источников карты...');
        
        // Настройка источника местоположения
        _locationSource = sdk.MyLocationMapObjectSource(sdkContext);
        _map!.addSource(_locationSource!);
        print('Источник местоположения добавлен');
        
        // Инициализируем 2GIS виджеты
        _initialize2GISWidgets();
        
        // Принудительно центрируем на Оше
        _centerMapOnOrderLocation();
        
        // Дополнительно центрируем через небольшую задержку
        Future.delayed(const Duration(milliseconds: 500), () {
          _centerMapOnOrderLocation();
        });
      } catch (e) {
        print('Ошибка настройки источников карты: $e');
      }
    } else {
      print('Карта не инициализирована!');
    }
  }

  void _initialize2GISWidgets() {
    try {
      print('2GIS виджеты готовы к использованию...');
      // В версии 12.8.0 виджеты не требуют инициализации контроллеров
    } catch (e) {
      print('Ошибка инициализации 2GIS виджетов: $e');
    }
  }

  void _centerMapOnOrderLocation() async {
    try {
      final camera = _map!.camera;
      // Принудительно устанавливаем координаты Оша
      final targetPoint = sdk.GeoPoint(
        latitude: sdk.Latitude(40.5283), // Город Ош
        longitude: sdk.Longitude(72.7985),
      );
      
      await camera.move(
        targetPoint,
        sdk.Zoom(20.0), // Максимальный зум
        sdk.Tilt(0.0),
        sdk.Bearing(0.0),
      );
      print('Карта центрирована на городе Ош');
    } catch (e) {
      print('Ошибка центрирования карты: $e');
    }
  }

  void _centerOnMyLocation() async {
    try {
      if (_map != null) {
        // Проверяем разрешения на геолокацию
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          print('Геолокация отключена');
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            print('Разрешение на геолокацию отклонено');
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          print('Разрешение на геолокацию отклонено навсегда');
          return;
        }

        // Получаем текущее местоположение
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('Текущее местоположение: ${position.latitude}, ${position.longitude}');

        // Центрируем карту на текущем местоположении с максимальным зумом
        final camera = _map!.camera;
        await camera.move(
          sdk.GeoPoint(
            latitude: sdk.Latitude(position.latitude),
            longitude: sdk.Longitude(position.longitude),
          ),
          sdk.Zoom(20.0), // Максимальный зум
          sdk.Tilt(0.0),
          sdk.Bearing(0.0),
        );
    
    setState(() {
          _isLocationCentered = true;
        });
        
        print('Карта центрирована на местоположении с максимальным зумом');
      }
    } catch (e) {
      print('Ошибка центрирования на местоположении: $e');
      // В случае ошибки центрируем на Оше
      if (_map != null) {
        final camera = _map!.camera;
        await camera.move(
          sdk.GeoPoint(
            latitude: sdk.Latitude(40.5283),
            longitude: sdk.Longitude(72.7985),
          ),
          sdk.Zoom(20.0),
          sdk.Tilt(0.0),
          sdk.Bearing(0.0),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        body: Stack(
            children: [
            // 2GIS карта с виджетами внутри
            SizedBox.expand(
              child: sdk.MapWidget(
                sdkContext: sdkContext,
                controller: _mapController,
                mapOptions: sdk.MapOptions(
                  position: sdk.CameraPosition(
                    point: sdk.GeoPoint(
                      latitude: sdk.Latitude(40.5283), // Город Ош, Кыргызстан
                      longitude: sdk.Longitude(72.7985),
                    ),
                    zoom: sdk.Zoom(20.0), // Максимальный зум
                  ),
                ),
                child: Stack(
                  children: [
                    // 2GIS стандартные виджеты внутри MapWidget
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 80,
                      right: 16,
                      child: sdk.TrafficWidget(),
                    ),
                      
                    Positioned(
                      bottom: 120,
                      right: 16,
                      child: sdk.ZoomWidget(),
                    ),
                      
                    Positioned(
                      bottom: 200,
                      right: 16,
                      child: sdk.CompassWidget(),
                    ),
                      
                    Positioned(
                      bottom: 280,
                      right: 16,
                      child: sdk.MyLocationWidget(),
                    ),
                  ],
                ),
              ),
            ),
          
          // Кнопка закрытия в левом верхнем углу
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
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
                      onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.black),
          ),
        ),
      ),
          
          // Кнопка определения маршрута в правом нижнем углу
          Positioned(
            bottom: 20,
            right: 20,
      child: Container(
        decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
            ),
          ],
        ),
              child: IconButton(
                onPressed: _centerOnMyLocation,
                icon: Icon(
                  _isLocationCentered ? Icons.my_location : Icons.navigation,
                  color: Colors.white,
                ),
                tooltip: 'Определить маршрут',
                    ),
                  ),
                ),
              ],
        ),
      ),
    );
  }
}
