import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/websocket_service.dart';
import 'services/order_service.dart';
import 'styles/app_theme.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/main/main_app_screen.dart';
import 'screens/order/new_order_screen.dart';
import 'screens/order/order_execution_screen.dart';

late sdk.Context sdkContext;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Инициализируем Firebase
    await Firebase.initializeApp();
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
      throw Exception('2GIS API ключ не настроен. Замените содержимое файла assets/dgissdk.key на ваш реальный ключ');
    }
    
    // Инициализируем SDK
    sdkContext = await sdk.DGis.initialize();
    print('2GIS SDK инициализирован успешно с ключом: ${apiKey.substring(0, 8)}...');
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
      title: 'Eco Такси',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/new_order': (context) => const NewOrderScreen(orderData: {}),
        '/order_execution': (context) => const OrderExecutionScreen(),
      },
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
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      final driverData = await AuthService.getCurrentDriver();
      
      setState(() {
        _isLoggedIn = isLoggedIn;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isLoggedIn) {
      return const MainAppScreen();
    } else {
      return const PhoneAuthScreen();
    }
  }
}

