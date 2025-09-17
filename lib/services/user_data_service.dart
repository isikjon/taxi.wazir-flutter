import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/phone_utils.dart';

class UserDataService {
  static const String _userDataKey = 'user_onboarding_data';
  
  static UserDataService? _instance;
  static UserDataService get instance => _instance ??= UserDataService._();
  UserDataService._();

  Map<String, dynamic> _userData = {};

  // Получить все данные пользователя
  Map<String, dynamic> get userData => Map<String, dynamic>.from(_userData);

  // Сохранить данные города
  Future<void> saveCityData(String city) async {
    _userData['city'] = city;
    await _saveToStorage();
  }

  // Сохранить данные водительских прав
  Future<void> saveDriverLicenseData({
    required String country,
    required String fullName,
    required String licenseNumber,
    required String issueDate,
    required String expiryDate,
    required String invitationCode,
    String callSign = '',
    String tariff = 'Эконом',
  }) async {
    _userData.addAll({
      'country': country,
      'fullName': fullName,
      'licenseNumber': licenseNumber,
      'issueDate': issueDate,
      'expiryDate': expiryDate,
      'invitationCode': invitationCode,
      'callSign': callSign,
      'tariff': tariff,
    });
    await _saveToStorage();
  }

  // Сохранить данные автомобиля
  Future<void> saveCarData({
    required String brand,
    required String model,
    required String color,
    required String year,
    required String licensePlate,
    String vin = '',
    String bodyNumber = '',
    String sts = '',
  }) async {
    _userData.addAll({
      'carBrand': brand,
      'carModel': model,
      'carColor': color,
      'carYear': year,
      'licensePlate': licensePlate,
      'vin': vin,
      'bodyNumber': bodyNumber,
      'sts': sts,
    });
    await _saveToStorage();
  }

  // Сохранить выбранный таксопарк
  Future<void> saveParkData(Map<String, dynamic> park) async {
    _userData['selectedPark'] = park;
    await _saveToStorage();
  }

  // Сохранить номер телефона
  Future<void> savePhoneNumber(String phoneNumber) async {
    // Нормализуем номер телефона перед сохранением
    final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    _userData['phoneNumber'] = normalizedPhone;
    await _saveToStorage();
  }

  // Сохранить в локальное хранилище
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(_userData);
      await prefs.setString(_userDataKey, jsonString);
      print('User data saved: $_userData');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  // Загрузить из локального хранилища
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userDataKey);
      if (jsonString != null) {
        _userData = json.decode(jsonString);
        print('User data loaded: $_userData');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  // Очистить все данные
  Future<void> clearUserData() async {
    _userData.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  // Получить полные данные для отправки на backend
  Map<String, dynamic> getCompleteUserData() {
    // Нормализуем номер телефона перед отправкой
    final String phoneNumber = _userData['phoneNumber'] ?? '';
    final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phoneNumber);
    
    return {
      'user': {
        'phoneNumber': normalizedPhone,
        'city': _userData['city'] ?? '',
        'fullName': _userData['fullName'] ?? '',
        'country': _userData['country'] ?? '',
        'licenseNumber': _userData['licenseNumber'] ?? '',
        'issueDate': _userData['issueDate'] ?? '',
        'expiryDate': _userData['expiryDate'] ?? '',
        'invitationCode': _userData['invitationCode'] ?? '',
        'callSign': _userData['callSign'] ?? '',
        'tariff': _userData['tariff'] ?? 'Эконом',
      },
      'car': {
        'brand': _userData['carBrand'] ?? '',
        'model': _userData['carModel'] ?? '',
        'color': _userData['carColor'] ?? '',
        'year': _userData['carYear'] ?? '',
        'licensePlate': _userData['licensePlate'] ?? '',
        'vin': _userData['vin'] ?? '',
        'bodyNumber': _userData['bodyNumber'] ?? '',
        'sts': _userData['sts'] ?? '',
      },
      'park': _userData['selectedPark'] ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
