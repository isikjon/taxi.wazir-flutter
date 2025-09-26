import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/phone_utils.dart';
import '../styles/app_colors.dart';
import 'photo_verification_service.dart';

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  String? _fcmToken;

  Future<void> initialize() async {
    try {
      await _requestPermissions();
      await _getFcmToken();
      _setupMessageHandlers();
      print('✅ Firebase Messaging инициализирован');
    } catch (e) {
      print('❌ Ошибка инициализации Firebase Messaging: $e');
    }
  }

  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Разрешения на уведомления получены');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('⚠️ Предварительные разрешения на уведомления');
    } else {
      print('❌ Разрешения на уведомления отклонены');
    }
  }

  Future<void> _getFcmToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('📱 FCM Token: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenLocally();
        await _sendTokenToServer();
      }
    } catch (e) {
      print('❌ Ошибка получения FCM токена: $e');
    }
  }

  Future<void> _saveTokenLocally() async {
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _fcmToken!);
    }
  }

  Future<void> _sendTokenToServer() async {
    try {
      print('🔍 [FCM] Начинаем отправку FCM токена на сервер');
      print('🔍 [FCM] Токен: ${_fcmToken?.substring(0, 20)}...');
      
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      print('🔍 [FCM] Данные водителя из SharedPreferences: ${driverData != null ? "найдены" : "НЕ найдены"}');
      
      if (driverData == null || _fcmToken == null) {
        print('❌ [FCM] Нет данных водителя или FCM токена');
        return;
      }

      final driver = json.decode(driverData);
      final driverPhone = driver['phoneNumber'] ?? '';
      print('🔍 [FCM] Номер телефона из данных: $driverPhone');
      
      if (driverPhone.isEmpty) {
        print('❌ [FCM] Нет номера телефона водителя');
        return;
      }

      final normalizedPhone = PhoneUtils.normalizePhoneNumber(driverPhone);
      print('🔍 [FCM] Нормализованный номер: $normalizedPhone');
      
          final url = '${ApiConfig.baseUrl}/driver/update-fcm-token';
      print('🔍 [FCM] URL для отправки: $url');
      
      final requestBody = {
        'phone_number': normalizedPhone,
        'fcm_token': _fcmToken,
      };
      print('🔍 [FCM] Тело запроса: ${json.encode(requestBody)}');
      print('🔍 [FCM] Заголовки: ${ApiConfig.defaultHeaders}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestBody),
      );

      print('🔍 [FCM] Статус ответа: ${response.statusCode}');
      print('🔍 [FCM] Тело ответа: ${response.body}');
      print('🔍 [FCM] Заголовки ответа: ${response.headers}');

      if (response.statusCode == 200) {
        print('✅ [FCM] FCM токен успешно отправлен на сервер');
      } else {
        print('❌ [FCM] Ошибка отправки FCM токена на сервер: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('❌ [FCM] Ошибка отправки FCM токена на сервер: $e');
      print('❌ [FCM] Stack trace: ${StackTrace.current}');
    }
  }

  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🔍 [FCM] Получено уведомление в foreground');
    print('🔍 [FCM] Message ID: ${message.messageId}');
    print('🔍 [FCM] Title: ${message.notification?.title}');
    print('🔍 [FCM] Body: ${message.notification?.body}');
    print('🔍 [FCM] Data: ${message.data}');
    print('🔍 [FCM] From: ${message.from}');
    
    await _playNotificationSound();
    await _vibrateDevice();
    
    _showInAppNotification(message);
  }

  Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('🔍 [FCM] Получено уведомление в background');
    print('🔍 [FCM] Message ID: ${message.messageId}');
    print('🔍 [FCM] Title: ${message.notification?.title}');
    print('🔍 [FCM] Body: ${message.notification?.body}');
    print('🔍 [FCM] Data: ${message.data}');
    print('🔍 [FCM] From: ${message.from}');
    
    await _playNotificationSound();
    await _vibrateDevice();
    
    _navigateToRelevantScreen(message);
  }

  Future<void> _playNotificationSound() async {
    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      print('❌ Ошибка воспроизведения звука: $e');
    }
  }

  Future<void> _vibrateDevice() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      print('❌ Ошибка вибрации: $e');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    final context = _getCurrentContext();
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.notification?.title ?? 'Новое уведомление'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Открыть',
            textColor: AppColors.surface,
            onPressed: () => _navigateToRelevantScreen(message),
          ),
        ),
      );
    }
  }

  void _navigateToRelevantScreen(RemoteMessage message) {
    print('🔍 [FCM] Начинаем навигацию к экрану');
    final context = _getCurrentContext();
    if (context == null) {
      print('❌ [FCM] Context не найден для навигации');
      return;
    }

    final data = message.data;
    final type = data['type'];
    print('🔍 [FCM] Тип уведомления: $type');
    print('🔍 [FCM] Данные уведомления: $data');

        switch (type) {
          case 'photo_verification_approved':
            print('🔍 [FCM] Обрабатываем одобрение фотоконтроля');
            _updatePhotoVerificationStatus('approved', null);
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/photocontrol',
              (route) => false,
            );
            break;
          case 'photo_verification_rejected':
            final reason = data['rejection_reason'];
            print('🔍 [FCM] Обрабатываем отклонение фотоконтроля, причина: $reason');
            _updatePhotoVerificationStatus('rejected', reason);
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/photocontrol',
              (route) => false,
            );
            break;
          case 'balance_topup':
            final amount = data['amount'];
            final newBalance = data['new_balance'];
            print('🔍 [FCM] Обрабатываем пополнение баланса: $amount сом, новый баланс: $newBalance сом');
            _updateDriverBalance(newBalance);
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
            break;
          default:
            print('⚠️ [FCM] Неизвестный тип уведомления: $type');
            break;
        }
  }

  void _updatePhotoVerificationStatus(String status, String? rejectionReason) {
    try {
      final photoService = PhotoVerificationService();
      photoService.handleNotificationUpdate(status, rejectionReason);
    } catch (e) {
      print('❌ Ошибка обновления статуса фотоконтроля: $e');
    }
  }

  void _updateDriverBalance(String newBalance) {
    try {
      // Обновляем баланс в SharedPreferences
      SharedPreferences.getInstance().then((prefs) {
        final driverData = prefs.getString('driver_data');
        if (driverData != null) {
          final driver = json.decode(driverData);
          driver['balance'] = double.parse(newBalance);
          prefs.setString('driver_data', json.encode(driver));
          print('✅ Баланс водителя обновлен через уведомление: $newBalance сом');
        }
      });
    } catch (e) {
      print('❌ Ошибка обновления баланса водителя: $e');
    }
  }

  BuildContext? _getCurrentContext() {
    return navigatorKey.currentContext;
  }

  Future<void> refreshToken() async {
    await _getFcmToken();
  }

  String? get currentToken => _fcmToken;
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Обработка фонового уведомления: ${message.messageId}');
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
