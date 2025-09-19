import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'services/auth_service.dart';
import 'styles/app_theme.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/main/main_app_screen.dart';

late sdk.Context sdkContext;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    sdkContext = await sdk.DGis.initialize();
    print('2GIS SDK инициализирован успешно');
  } catch (e) {
    print('Ошибка инициализации 2GIS SDK: $e');
    rethrow;
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
  String? _savedPhoneNumber;

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
        _savedPhoneNumber = driverData?['phoneNumber'];
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

