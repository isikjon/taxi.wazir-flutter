import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/navigation_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  GoogleMapController? _mapController;
  final NavigationService _navigationService = NavigationService();
  
  Position? _currentPosition;
  Map<String, dynamic>? _routeData;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _error;
  
  // Состояние навигации
  bool _navigationStarted = false;
  StreamSubscription<Position>? _positionStream;
  String _currentInstruction = 'Подготовка маршрута...';
  String _distanceRemaining = '';
  String _timeRemaining = '';
  double _currentSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeNavigation();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _initializeNavigation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Получаем текущее местоположение
      final position = await _navigationService.getCurrentLocation();
      
      // Строим маршрут
      final routeData = await _navigationService.buildRoute(position);
      
      if (routeData['success']) {
        setState(() {
          _currentPosition = position;
          _routeData = routeData;
          _isLoading = false;
          _currentInstruction = 'Проедьте ${routeData['distance']} чтобы протестировать навигацию';
          _distanceRemaining = routeData['distance'];
          _timeRemaining = routeData['duration'];
        });

        _setupMapData();
      } else {
        setState(() {
          _error = routeData['error'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupMapData() {
    if (_routeData == null) return;

    // Создаем polyline для маршрута
    final polylinePoints = _navigationService.decodePolyline(_routeData!['polyline']);
    final polyline = Polyline(
      polylineId: const PolylineId('route'),
      points: polylinePoints.map((point) => 
        LatLng(point['latitude']!, point['longitude']!)
      ).toList(),
      color: AppColors.primary,
      width: 5,
    );

    // Создаем маркеры
    final startMarker = Marker(
      markerId: const MarkerId('start'),
      position: LatLng(
        _routeData!['startLocation']['lat'],
        _routeData!['startLocation']['lng'],
      ),
      infoWindow: const InfoWindow(title: 'Старт'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    final endMarker = Marker(
      markerId: const MarkerId('end'),
      position: LatLng(
        _routeData!['endLocation']['lat'],
        _routeData!['endLocation']['lng'],
      ),
      infoWindow: const InfoWindow(title: 'Финиш'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _polylines = {polyline};
      _markers = {startMarker, endMarker};
    });
  }

  void _startNavigation() {
    if (_navigationStarted) return;
    
    setState(() {
      _navigationStarted = true;
      _currentInstruction = 'Навигация запущена. Следуйте по маршруту.';
    });

    // Начинаем отслеживание позиции
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Обновляем каждые 5 метров
      ),
    ).listen(_onPositionUpdate);
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;

    setState(() {
      _currentPosition = position;
      _currentSpeed = position.speed * 3.6; // м/с в км/ч
    });

    // Проверяем, достигли ли пункта назначения
    if (_routeData != null) {
      final destination = {
        'latitude': (_routeData!['endLocation']['lat'] as num).toDouble(),
        'longitude': (_routeData!['endLocation']['lng'] as num).toDouble(),
      };

      if (_navigationService.isAtDestination(position, destination)) {
        _finishNavigation();
      } else {
        // Обновляем оставшееся расстояние
        final remainingDistance = _navigationService.calculateDistance(
          position.latitude,
          position.longitude,
          destination['latitude']!,
          destination['longitude']!,
        );
        
        setState(() {
          _distanceRemaining = '${remainingDistance.round()} м';
        });
      }
    }

    // Обновляем камеру карты
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  void _finishNavigation() {
    _positionStream?.cancel();
    
    setState(() {
      _navigationStarted = false;
      _currentInstruction = 'Навигация завершена! Тест пройден успешно.';
      _distanceRemaining = '0 м';
    });

    // Показываем диалог завершения
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Тест завершен!'),
        content: const Text(
          'Навигация протестирована успешно.\nВы готовы к работе на линии!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pop(); // Возвращаемся на главный экран
            },
            child: const Text('Завершить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 20),
              Text(
                'Подготовка навигации...',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              Text(
                'Ошибка навигации',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Вернуться'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Карта на весь экран
          GoogleMap(
            onMapCreated: (controller) => _mapController = controller,
            initialCameraPosition: CameraPosition(
              target: LatLng(
                _currentPosition?.latitude ?? 42.8746,
                _currentPosition?.longitude ?? 74.5698,
              ),
              zoom: 18.0,
              tilt: 60.0, // 3D эффект
            ),
            mapType: MapType.normal,
            polylines: _polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          // Верхняя панель с инструкциями
          _buildTopPanel(),
          
          // Нижняя панель с кнопками
          _buildBottomPanel(),
        ],
      ),
    );
  }

  Widget _buildTopPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Тестовая навигация',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _currentInstruction,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_distanceRemaining.isNotEmpty || _timeRemaining.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      if (_distanceRemaining.isNotEmpty) ...[
                        Icon(Icons.straighten, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _distanceRemaining,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (_timeRemaining.isNotEmpty && _distanceRemaining.isNotEmpty)
                        const SizedBox(width: AppSpacing.md),
                      if (_timeRemaining.isNotEmpty) ...[
                        Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _timeRemaining,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Показатель скорости
                if (_navigationStarted) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.speed, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        '${_currentSpeed.toStringAsFixed(0)} км/ч',
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                
                // Кнопка запуска/остановки навигации
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _navigationStarted ? null : _startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _navigationStarted 
                          ? Colors.grey 
                          : AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _navigationStarted ? 'Навигация активна' : 'Начать тест',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
