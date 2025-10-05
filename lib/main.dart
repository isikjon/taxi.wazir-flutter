import 'dart:io';

import 'package:eco_taxi/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'services/auth_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/websocket_service.dart';
import 'services/location_service.dart';
import 'services/navigation_service.dart';
import 'styles/app_theme.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/main/main_app_screen.dart';

late sdk.Context sdkContext;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.white, // фон статус-бара
      statusBarIconBrightness: Brightness.dark, // иконки тёмные
    ),
  );

  try {
    // Инициализируем Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase инициализирован');

    // Инициализируем Firebase Messaging
    await FirebaseMessagingService().initialize();
    print('✅ Firebase Messaging инициализирован');
  } catch (e) {
    print('❌ Ошибка инициализации Firebase: $e');
  }

  try {
    // Загружаем ключ из assets
    final keyData = await rootBundle.loadString('assets/dgissdk.key');
    final apiKey = keyData.trim();

    if (apiKey.isEmpty || apiKey == 'YOUR_2GIS_API_KEY_HERE') {
      throw Exception(
        '2GIS API ключ не настроен. Замените содержимое файла assets/dgissdk.key на ваш реальный ключ',
      );
    }

    final iosKey  = const sdk.KeyFromAsset('dgissdk_ios.key');
    final androidKey  = const sdk.KeyFromAsset('dgissdk.key');

    final key =  sdk.KeySource.fromAsset(Platform.isAndroid ? androidKey : iosKey);

    // Инициализируем SDK
    sdkContext = await sdk.DGis.initialize(keySource: key);
    print(
      '2GIS SDK инициализирован успешно с ключом: ${apiKey.substring(0, 8)}...',
    );

    // Инициализируем сервис навигации
    NavigationService().initialize(sdkContext);
  } catch (e) {
    print('Ошибка инициализации 2GIS SDK: $e');
    // Не прерываем запуск приложения, просто логируем ошибку
    sdkContext = await sdk.DGis.initialize();
  }

  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowMaterialGrid: false,
      title: 'Eco Такси',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      requestPermission();
      requestLocationPermission();
    });
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();

      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });

      if (isLoggedIn) {
        _initializeServices();
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WebSocketService().connect();
        LocationService().requestLocationPermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoggedIn) {
      return const MainAppScreen();
    } else {
      return const PhoneAuthScreen();
    }
  }

  void requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  Future<void> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Проверяем, включены ли службы геолокации
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Геолокация выключена. Попросите пользователя включить её.');
      return;
    }

    // Проверяем текущее разрешение
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Разрешение отклонено');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        'Разрешение отклонено навсегда. Пользователю нужно включить в настройках',
      );
      return;
    }

    print('Разрешение на геолокацию получено');
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    print('Текущая позиция: ${position.latitude}, ${position.longitude}');
  }
}
