// import 'package:flutter/material.dart';
// import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
// import 'package:geolocator/geolocator.dart';
// import 'dart:math' as math;
//
// class TaxiMapPage extends StatefulWidget {
//   @override
//   _TaxiMapPageState createState() => _TaxiMapPageState();
// }
//
// class _TaxiMapPageState extends State<TaxiMapPage> {
//   late final sdk.MapWidgetController _mapWidgetController;
//
//   sdk.Context? sdkContext;
//   sdk.Map? mapController;
//   sdk.TrafficRouter? trafficRouter;
//   sdk.RouteMapObjectSource? routeMapObjectSource;
//
//   Position? currentPosition;
//   bool isLocationPermissionGranted = false;
//   bool isLoadingLocation = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _mapWidgetController = sdk.MapWidgetController();
//
//     // Инициализация SDK (синхронная)
//     sdkContext = sdk.DGis.initialize();
//
//     // Инициализация компонентов для маршрутов
//     trafficRouter = sdk.TrafficRouter(sdkContext!);
//     routeMapObjectSource = sdk.RouteMapObjectSource(
//       sdkContext!,
//       sdk.RouteVisualizationType.normal,
//     );
//
//     // Сразу запрашиваем разрешение
//     _requestLocationPermission();
//   }
//
//   // Запрос разрешения на геолокацию
//   Future<void> _requestLocationPermission() async {
//     // ... (код без изменений) ...
//     try {
//       LocationPermission permission = await Geolocator.checkPermission();
//
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }
//
//       if (permission == LocationPermission.deniedForever) {
//         _showPermissionDeniedDialog();
//         if (mounted) setState(() => isLoadingLocation = false);
//         return;
//       }
//
//       if (permission == LocationPermission.whileInUse ||
//           permission == LocationPermission.always) {
//         if (mounted) setState(() => isLocationPermissionGranted = true);
//         await _getCurrentLocation();
//       } else {
//         if (mounted) setState(() => isLoadingLocation = false);
//       }
//     } catch (e) {
//       print('Ошибка при запросе разрешения: $e');
//       if (mounted) setState(() => isLoadingLocation = false);
//     }
//   }
//
//   // Получение текущего местоположения
//   Future<void> _getCurrentLocation() async {
//     // ... (код без изменений) ...
//     try {
//       Position position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//         timeLimit: Duration(seconds: 10),
//       );
//
//       if (!mounted) return;
//       setState(() {
//         currentPosition = position;
//         isLoadingLocation = false;
//       });
//
//       _initializeMap();
//
//     } catch (e) {
//       print('Ошибка при получении местоположения: $e');
//       _showLocationErrorDialog();
//       if (mounted) setState(() => isLoadingLocation = false);
//     }
//   }
//
//   // Инициализация карты после получения местоположения
//   Future<void> _initializeMap() async {
//     // ... (код без изменений) ...
//     mapController = await _mapWidgetController.getMap();
//     if (mapController != null) {
//       _showUserLocationOnMap();
//       _buildTestRoute();
//     }
//   }
//
//   // Показать местоположение пользователя на карте
//   void _showUserLocationOnMap() {
//     // ... (код без изменений) ...
//     if (currentPosition != null && mapController != null) {
//       final userLocation = sdk.GeoPoint(
//         latitude: currentPosition!.latitude,
//         longitude: currentPosition!.longitude,
//       );
//       mapController!.camera.move(
//         sdk.CameraPosition(
//           point: userLocation,
//           zoom: sdk.Zoom(16),
//         ),
//       );
//     }
//   }
//
//   // Построение тестового маршрута
//   Future<void> _buildTestRoute() async {
//     // ... (код без изменений) ...
//     if (currentPosition == null || mapController == null || trafficRouter == null) return;
//
//     try {
//       final startPoint = sdk.RouteSearchPoint(
//         coordinates: sdk.GeoPoint(
//           latitude: currentPosition!.latitude,
//           longitude: currentPosition!.longitude,
//         ),
//       );
//       final finishPoint = sdk.RouteSearchPoint(
//         coordinates: _calculateDestination(
//           currentPosition!.latitude,
//           currentPosition!.longitude,
//           100.0,
//           45.0,
//         ),
//       );
//       final carOptions = sdk.CarRouteSearchOptions();
//       final taxiOptions = sdk.TaxiRouteSearchOptions(car: carOptions);
//       final routeSearchOptions = sdk.RouteSearchOptions.taxi(taxiOptions: taxiOptions);
//
//       if (routeMapObjectSource != null) {
//         mapController!.addSource(routeMapObjectSource!);
//       }
//
//       final routesResult = await trafficRouter!.findRoute(
//         startPoint: startPoint,
//         finishPoint: finishPoint,
//         routeSearchOptions: routeSearchOptions,
//       );
//
//       if (routesResult.routes.isNotEmpty) {
//         routeMapObjectSource!.clear();
//         for (int i = 0; i < routesResult.routes.length; i++) {
//           routeMapObjectSource!.addObject(
//             object: sdk.RouteMapObject(
//                 route: routesResult.routes[i],
//                 primary: i == 0,
//                 routeIndex: sdk.RouteIndex(i)
//             ),
//           );
//         }
//         print('Тестовый маршрут построен!');
//         _showRouteInfo(routesResult.routes.first);
//       } else {
//         _showNoRouteDialog();
//       }
//     } catch (e) {
//       print('Ошибка при построении маршрута: $e');
//       _showRouteErrorDialog();
//     }
//   }
//
//   // Остальная часть кода (диалоги, _calculateDestination, build) без изменений
//   // Расчет конечной точки
//   sdk.GeoPoint _calculateDestination(
//       double startLat, double startLon, double distanceMeters, double bearingDegrees
//       ) {
//     const double earthRadius = 6371000;
//     double bearingRad = bearingDegrees * (math.pi / 180);
//     double startLatRad = startLat * (math.pi / 180);
//     double startLonRad = startLon * (math.pi / 180);
//
//     double endLatRad = math.asin(
//       math.sin(startLatRad) * math.cos(distanceMeters / earthRadius) +
//           math.cos(startLatRad) *
//               math.sin(distanceMeters / earthRadius) *
//               math.cos(bearingRad),
//     );
//
//     double endLonRad =
//         startLonRad +
//             math.atan2(
//               math.sin(bearingRad) *
//                   math.sin(distanceMeters / earthRadius) *
//                   math.cos(startLatRad),
//               math.cos(distanceMeters / earthRadius) -
//                   math.sin(startLatRad) * math.sin(endLatRad),
//             );
//
//     return sdk.GeoPoint(
//       latitude: endLatRad * (180 / math.pi),
//       longitude: endLonRad * (180 / math.pi),
//     );
//   }
//
//   // Диалоги
//   void _showPermissionDeniedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Разрешение отклонено'),
//         content: Text(
//           'Для работы приложения необходим доступ к местоположению.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showLocationErrorDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Ошибка геолокации'),
//         content: Text('Не удалось получить местоположение.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _getCurrentLocation();
//             },
//             child: Text('Повторить'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showNoRouteDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Маршрут не найден'),
//         content: Text('Не удалось построить маршрут.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showRouteErrorDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Ошибка построения маршрута'),
//         content: Text('Произошла ошибка при построении маршрута.'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('OK'),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _buildTestRoute();
//             },
//             child: Text('Повторить'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showRouteInfo(sdk.TrafficRoute route) {
//     final duration = 10;
//     final minutes = (duration / 60).round();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Маршрут построен: примерно $minutes мин.',
//         ),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Тестовый маршрут такси'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Stack(
//         children: [
//           if (sdkContext != null)
//             sdk.MapWidget(
//               sdkContext: sdkContext!,
//               mapOptions: sdk.MapOptions(),
//               controller: _mapWidgetController,
//             )
//           else
//             Center(child: CircularProgressIndicator()),
//           if (isLoadingLocation)
//             Container(
//               color: Colors.white,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text(
//                       'Получение местоположения...',
//                       style: TextStyle(fontSize: 18),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           if (!isLoadingLocation && !isLocationPermissionGranted)
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.location_off, size: 64, color: Colors.grey),
//                   SizedBox(height: 16),
//                   Text(
//                     'Доступ к местоположению запрещен',
//                     style: TextStyle(fontSize: 18, color: Colors.grey[600]),
//                   ),
//                   TextButton(
//                     onPressed: _requestLocationPermission,
//                     child: Text('Запросить разрешение'),
//                   ),
//                 ],
//               ),
//             )
//         ],
//       ),
//       floatingActionButton:
//       !isLoadingLocation && isLocationPermissionGranted
//           ? FloatingActionButton(
//         onPressed: _buildTestRoute,
//         child: Icon(Icons.navigation),
//         tooltip: 'Построить новый маршрут',
//       )
//           : null,
//     );
//   }
// }