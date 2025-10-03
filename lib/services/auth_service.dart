import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'user_data_service.dart';
import 'database_service.dart';
import 'firebase_messaging_service.dart';
import '../utils/phone_utils.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _driverDataKey = 'driver_data';

  static Future<Map<String, dynamic>> login(String phone, String smsCode) async {
    try {
      // Проверяем dev-режим для кода 1111
      if (smsCode == '1111') {
        print('🔧 DEV MODE: Пропускаем проверку через backend для кода 1111');
        
        // Сохраняем данные как авторизованного пользователя
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        
        // Сохраняем номер телефона
        final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phone);
        await UserDataService.instance.savePhoneNumber(normalizedPhone);
        
        // Отправляем FCM токен на сервер
        await FirebaseMessagingService().refreshToken();
        
        return {
          'success': true,
          'isNewUser': true,
          'driver': null,
        };
      }
      
      final response = await ApiService.instance.loginDriver(phone, smsCode);
      
      if (response['success']) {
        final driverData = response['data']['driver'];
        
        // Проверяем статус водителя
        if (driverData != null) {
          final status = driverData['status'];
          
          // Если водитель заблокирован
          if (status == 'inactive' || driverData['blocked'] == true) {
            return {
              'success': false,
              'error': 'blocked',
              'message': driverData['blockMessage'] ?? 'Ваш аккаунт заблокирован суперадмином. Для связи: +996 559 868 878',
            };
          }
          
          // Если водитель активен, сохраняем данные
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setString(_driverDataKey, jsonEncode(driverData));
          print('Saved driver data: ${jsonEncode(driverData)}');
          
          // Обновляем данные в UserDataService (сохраняем нормализованный номер)
          final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phone);
          await UserDataService.instance.savePhoneNumber(normalizedPhone);
          
          // Отправляем FCM токен на сервер
          await FirebaseMessagingService().refreshToken();
          
          // Если есть данные о таксопарке, сохраняем их
          if (driverData['taxiparkName'] != null) {
            final taxiparkData = {
              'id': driverData['taxiparkId'] ?? 1,
              'name': driverData['taxiparkName'],
            };
            await UserDataService.instance.saveParkData(taxiparkData);
            print('Updated taxipark data: $taxiparkData');
          }
          
          // Если есть данные о машине, сохраняем их
          if (driverData['carModel'] != null) {
            await UserDataService.instance.saveCarData(
              brand: driverData['carBrand'] ?? '',
              model: driverData['carModel'] ?? '',
              color: driverData['carColor'] ?? '',
              year: driverData['carYear'] ?? '',
              licensePlate: driverData['carNumber'] ?? '',
              vin: driverData['carVin'] ?? '',
              bodyNumber: driverData['carBodyNumber'] ?? '',
              sts: driverData['carSts'] ?? '',
            );
            print('Updated car data from login');
          }
          
          return {
            'success': true,
            'isNewUser': response['isNewUser'] ?? false,
            'driver': driverData,
          };
        }
        
        // Если это новый пользователь
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        
        return {
          'success': true,
          'isNewUser': response['isNewUser'] ?? false,
          'driver': null,
        };
      } else {
        // Проверяем, не удален ли водитель
        if (response['error']?.contains('не найден') == true || 
            response['error']?.contains('удален') == true) {
          return {
            'success': false,
            'error': 'deleted',
            'message': 'Ваш аккаунт удален суперадмином. Для связи: +996 559 868 878',
          };
        }
        
        return {
          'success': false,
          'error': response['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка авторизации: $e',
      };
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Очищаем все данные авторизации
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_driverDataKey);
      
      // Очищаем данные пользователя из UserDataService
      await UserDataService.instance.clearUserData();
      
      // Очищаем базу данных
      await DatabaseService.clearAllData();
      
      // Очищаем все остальные данные
      await prefs.clear();
      
      print('✅ Logout successful - all data cleared');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentDriver() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverDataString = prefs.getString(_driverDataKey);
      print('Raw driver data string: $driverDataString');
      
      if (driverDataString != null && driverDataString.isNotEmpty) {
        // Проверяем, что строка начинается с { (валидный JSON)
        if (driverDataString.startsWith('{')) {
          try {
            final driverData = jsonDecode(driverDataString) as Map<String, dynamic>;
            print('Parsed driver data: $driverData');
            return driverData;
          } catch (e) {
            print('JSON parsing error: $e');
            // Если JSON невалидный, очищаем данные
            await prefs.remove(_driverDataKey);
            return null;
          }
        } else {
          print('Invalid JSON format, clearing data');
          // Очищаем невалидные данные
          await prefs.remove(_driverDataKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting driver data: $e');
      return null;
    }
  }
}
