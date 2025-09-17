import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DriverService {
  static final DriverService _instance = DriverService._internal();
  factory DriverService() => _instance;
  DriverService._internal();

  final String _baseUrl = ApiConfig.baseUrl;

  Future<Map<String, dynamic>?> getDriverProfile(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/profile?phoneNumber=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🚗 Driver profile response status: ${response.statusCode}');
      print('🚗 Driver profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error getting driver profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting driver profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverCarInfo(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/car?phoneNumber=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🚗 Car info response status: ${response.statusCode}');
      print('🚗 Car info response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error getting car info: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting car info: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDriverTaxipark(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/taxipark?phoneNumber=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('🏢 Taxipark response status: ${response.statusCode}');
      print('🏢 Taxipark response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error getting taxipark: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting taxipark: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeeklyResults(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/weekly-results?phoneNumber=$phoneNumber'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('📊 Weekly results response status: ${response.statusCode}');
      print('📊 Weekly results response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        print('❌ Error getting weekly results: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception getting weekly results: $e');
      return null;
    }
  }
}