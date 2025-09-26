import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_button.dart';

class OrderExecutionScreen extends StatefulWidget {
  @override
  State<OrderExecutionScreen> createState() => _OrderExecutionScreenState();
}

class _OrderExecutionScreenState extends State<OrderExecutionScreen> {
  final OrderService _orderService = OrderService();
  sdk.DgisMapController? _mapController;
  sdk.TrafficRouter? _trafficRouter;
  sdk.RouteMapObjectSource? _routeSource;
  
  List<sdk.TrafficRoute> _routes = [];
  sdk.TrafficRoute? _currentRoute;
  bool _isNavigatingToClient = true;
  bool _isLoading = false;
  bool _hasArrivedAtClient = false;
  bool _hasArrivedAtDestination = false;
  
  double _totalDistance = 0.0;
  int _totalDuration = 0;
  double _currentDistance = 0.0;
  int _currentDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    try {
      final order = _orderService.currentOrder;
      if (order == null) return;

      final currentLocation = await _getCurrentLocation();
      final pickupPoint = sdk.GeoPoint(
        latitude: order['pickup_latitude'] ?? 0.0,
        longitude: order['pickup_longitude'] ?? 0.0,
      );
      final destinationPoint = sdk.GeoPoint(
        latitude: order['destination_latitude'] ?? 0.0,
        longitude: order['destination_longitude'] ?? 0.0,
      );

      _trafficRouter = sdk.TrafficRouter(sdk.DgisSdkContext());
      
      if (_isNavigatingToClient) {
        await _buildRouteToClient(currentLocation, pickupPoint);
      } else {
        await _buildRouteToDestination(pickupPoint, destinationPoint);
      }
    } catch (e) {
      print('❌ Ошибка инициализации карты: $e');
    }
  }

  Future<sdk.GeoPoint> _getCurrentLocation() async {
    return sdk.GeoPoint(latitude: 40.5283, longitude: 72.7985);
  }

  Future<void> _buildRouteToClient(sdk.GeoPoint start, sdk.GeoPoint end) async {
    try {
      final taxiOptions = sdk.TaxiRouteSearchOptions(
        car: sdk.CarRouteSearchOptions(),
      );
      
      final routeSearchOptions = sdk.RouteSearchOptions.taxi(taxiOptions);
      final startPoint = sdk.RouteSearchPoint(coordinates: start);
      final finishPoint = sdk.RouteSearchPoint(coordinates: end);

      final routes = await _trafficRouter!.findRoute(
        startPoint,
        finishPoint,
        routeSearchOptions,
      ).value;

      if (routes.isNotEmpty) {
        setState(() {
          _routes = routes;
          _currentRoute = routes.first;
          _currentDistance = _currentRoute!.totalDistance / 1000;
          _currentDuration = (_currentRoute!.totalDuration / 60).round();
        });

        await _displayRouteOnMap();
      }
    } catch (e) {
      print('❌ Ошибка построения маршрута к клиенту: $e');
    }
  }

  Future<void> _buildRouteToDestination(sdk.GeoPoint start, sdk.GeoPoint end) async {
    try {
      final taxiOptions = sdk.TaxiRouteSearchOptions(
        car: sdk.CarRouteSearchOptions(),
      );
      
      final routeSearchOptions = sdk.RouteSearchOptions.taxi(taxiOptions);
      final startPoint = sdk.RouteSearchPoint(coordinates: start);
      final finishPoint = sdk.RouteSearchPoint(coordinates: end);

      final routes = await _trafficRouter!.findRoute(
        startPoint,
        finishPoint,
        routeSearchOptions,
      ).value;

      if (routes.isNotEmpty) {
        setState(() {
          _routes = routes;
          _currentRoute = routes.first;
          _currentDistance = _currentRoute!.totalDistance / 1000;
          _currentDuration = (_currentRoute!.totalDuration / 60).round();
          _totalDistance += _currentDistance;
          _totalDuration += _currentDuration;
        });

        await _displayRouteOnMap();
      }
    } catch (e) {
      print('❌ Ошибка построения маршрута к назначению: $e');
    }
  }

  Future<void> _displayRouteOnMap() async {
    if (_currentRoute == null || _mapController == null) return;

    try {
      _routeSource = sdk.RouteMapObjectSource(
        sdk.DgisSdkContext(),
        sdk.RouteVisualizationType.NORMAL,
      );
      
      await _mapController!.addSource(_routeSource!);
      
      _routeSource!.addObject(
        sdk.RouteMapObject(_currentRoute!, true, 0),
      );

      final bounds = _currentRoute!.bounds;
      await _mapController!.setBounds(bounds, sdk.EdgeInsets.all(50));
    } catch (e) {
      print('❌ Ошибка отображения маршрута: $e');
    }
  }

  Future<void> _arriveAtClient() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.updateOrderStatusToServer('arrived_at_a');
      
      setState(() {
        _hasArrivedAtClient = true;
        _isNavigatingToClient = false;
      });

      final order = _orderService.currentOrder;
      if (order != null) {
        final destinationPoint = sdk.GeoPoint(
          latitude: order['destination_latitude'] ?? 0.0,
          longitude: order['destination_longitude'] ?? 0.0,
        );
        final pickupPoint = sdk.GeoPoint(
          latitude: order['pickup_latitude'] ?? 0.0,
          longitude: order['pickup_longitude'] ?? 0.0,
        );

        await _buildRouteToDestination(pickupPoint, destinationPoint);
      }
    } catch (e) {
      print('❌ Ошибка обновления статуса: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _orderService.updateOrderStatusToServer('completed');
      
      setState(() {
        _hasArrivedAtDestination = true;
      });

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      print('❌ Ошибка завершения заказа: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _orderService.currentOrder;
    if (order == null) {
      return Scaffold(
        body: Center(
          child: Text('Заказ не найден'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Выполнение заказа',
          style: AppTextStyles.h2.copyWith(color: AppColors.surface),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildOrderInfo(),
          Expanded(
            child: _buildMap(),
          ),
          _buildRouteInfo(),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildOrderInfo() {
    final order = _orderService.currentOrder!;
    
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      color: AppColors.primary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заказ №${order['order_number'] ?? order['id']}',
                style: AppTextStyles.h4.copyWith(color: AppColors.surface),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                _isNavigatingToClient ? 'Едем к клиенту' : 'Везем клиента',
                style: AppTextStyles.body.copyWith(color: AppColors.surface.withOpacity(0.8)),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.xs),
            ),
            child: Text(
              '${order['price']?.toStringAsFixed(0) ?? '0'} сом',
              style: AppTextStyles.h4.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      child: sdk.DgisMap(
        onMapReady: (sdk.DgisMapController controller) {
          _mapController = controller;
          _initializeMap();
        },
        style: sdk.MapStyle.vectorDark,
        initialCameraPosition: sdk.CameraPosition(
          target: sdk.GeoPoint(latitude: 40.5283, longitude: 72.7985),
          zoom: 13,
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem(
            'Расстояние',
            '${_currentDistance.toStringAsFixed(1)} км',
            Icons.straighten,
          ),
          _buildInfoItem(
            'Время',
            '$_currentDuration мин',
            Icons.access_time,
          ),
          if (_totalDistance > 0)
            _buildInfoItem(
              'Всего',
              '${_totalDistance.toStringAsFixed(1)} км',
              Icons.route,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.h4.copyWith(color: AppColors.text),
        ),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      child: CustomButton(
        text: _getActionButtonText(),
        onPressed: _isLoading ? null : _getActionButtonHandler(),
        backgroundColor: _getActionButtonColor(),
        textColor: AppColors.surface,
        isLoading: _isLoading,
      ),
    );
  }

  String _getActionButtonText() {
    if (_isNavigatingToClient) {
      return 'Прибыл к клиенту';
    } else {
      return 'Отвез клиента';
    }
  }

  Color _getActionButtonColor() {
    if (_isNavigatingToClient) {
      return AppColors.warning;
    } else {
      return AppColors.success;
    }
  }

  VoidCallback? _getActionButtonHandler() {
    if (_isNavigatingToClient) {
      return _arriveAtClient;
    } else {
      return _completeOrder;
    }
  }
}
