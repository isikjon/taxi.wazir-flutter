import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'photo_storage_service.dart';
// Условный импорт для разных платформ (не используется в мобильной версии)

class PhotoVerificationService {
  final PhotoStorageService _photoStorage = PhotoStorageService();

  Future<bool> submitPhotosForVerification(Map<String, String> photos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        print('❌ Нет данных водителя');
        return false;
      }
      
      final driver = json.decode(driverData);
      final driverPhone = driver['phoneNumber'] ?? '';
      
      if (driverPhone.isEmpty) {
        print('❌ Нет номера телефона водителя');
        return false;
      }
      
      final url = '${ApiConfig.baseUrl}/api/photo-control/submit';
      print('📸 Отправка фото на: $url');
      print('📸 Телефон водителя: $driverPhone');
      print('📸 Фотографии: ${photos.keys.toList()}');
      
      // Получаем реальные пути к файлам из локального хранилища
      final Map<String, String> realPhotoPaths = {};
      for (final entry in photos.entries) {
        final realPath = await _photoStorage.getPhotoPath(entry.key);
        if (realPath != null) {
          realPhotoPaths[entry.key] = realPath;
          print('📸 ${entry.key}: $realPath');
        } else {
          print('❌ Не найден файл для ${entry.key}');
        }
      }
      
      if (realPhotoPaths.isEmpty) {
        print('❌ Нет доступных фотографий для отправки');
        return false;
      }
      
      // Всегда используем multipart для отправки файлов (убираем веб-логику)
      print('📸 Отправляем файлы через multipart/form-data');
      
      final request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['driver_phone'] = driverPhone;
      
      // Добавляем фото как файлы
      for (final entry in realPhotoPaths.entries) {
        try {
          if (kIsWeb) {
            // Для веб-версии конвертируем blob в байты
            await _addWebFileToRequest(request, entry.key, entry.value);
          } else {
            // Для мобильных платформ используем fromPath
            final file = await http.MultipartFile.fromPath(
              entry.key,
              entry.value,
              filename: '${entry.key}.jpg',
            );
            request.files.add(file);
          }
          print('📸 Добавлен файл ${entry.key}: ${entry.value}');
        } catch (e) {
          print('❌ Ошибка добавления файла ${entry.key}: $e');
        }
      }
      
      final response = await request.send();
      final statusCode = response.statusCode;
      final responseBody = await response.stream.bytesToString();
      
      print('📸 Статус ответа: $statusCode');
      print('📸 Тело ответа: $responseBody');
      
      if (statusCode == 200) {
        final responseData = json.decode(responseBody);
        if (responseData['success'] == true) {
          await _photoStorage.setVerificationStatus('pending');
          print('✅ Фотографии успешно отправлены на проверку');
          return true;
        }
      }
      
      print('❌ Ошибка отправки фотографий: $responseBody');
      return false;
      
    } catch (e) {
      print('❌ Ошибка отправки фото на проверку: $e');
      return false;
    }
  }

  Future<void> _addWebFileToRequest(http.MultipartRequest request, String fieldName, String blobUrl) async {
    if (!kIsWeb) return;
    
    try {
      // Веб-специфичный код отключен для мобильной сборки
      if (kIsWeb) {
        throw UnimplementedError('Web blob handling not available in mobile build');
      }
      
      // Заглушка для мобильной версии - просто пропускаем
      print('📸 Веб-файл $fieldName пропущен в мобильной версии');
    } catch (e) {
      print('❌ Ошибка обработки веб-файла $fieldName: $e');
      // Если не удалось получить файл из blob, пропускаем его
    }
  }

  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final driverData = prefs.getString('driver_data');
      
      if (driverData == null) {
        return {
          'status': 'not_started',
          'rejection_reason': null,
        };
      }
      
      final driver = json.decode(driverData);
      final driverPhone = driver['phoneNumber'] ?? '';
      
      if (driverPhone.isEmpty) {
        return {
          'status': 'not_started',
          'rejection_reason': null,
        };
      }
      
      final url = '${ApiConfig.baseUrl}/api/photo-control/status?driver_phone=$driverPhone';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Сохраняем статус локально для быстрого доступа
        await _photoStorage.setVerificationStatus(responseData['status'] ?? 'not_started');
        if (responseData['rejection_reason'] != null) {
          await _photoStorage.setRejectionReason(responseData['rejection_reason']);
        }
        
        return {
          'status': responseData['status'] ?? 'not_started',
          'rejection_reason': responseData['rejection_reason'],
        };
      }
      
      // Если API недоступен, возвращаем локальный статус
      final localStatus = await _photoStorage.getVerificationStatus();
      final localReason = await _photoStorage.getRejectionReason();
      
      return {
        'status': localStatus,
        'rejection_reason': localReason,
      };
      
    } catch (e) {
      print('Ошибка получения статуса проверки: $e');
      
      // Возвращаем локальный статус при ошибке
      final localStatus = await _photoStorage.getVerificationStatus();
      final localReason = await _photoStorage.getRejectionReason();
      
      return {
        'status': localStatus,
        'rejection_reason': localReason,
      };
    }
  }

  Future<void> approvePhotos() async {
    try {
      await _photoStorage.setVerificationStatus('approved');
      await _photoStorage.setRejectionReason('');
    } catch (e) {
      print('Ошибка одобрения фото: $e');
    }
  }

  Future<void> rejectPhotos(String reason) async {
    try {
      await _photoStorage.setVerificationStatus('rejected');
      await _photoStorage.setRejectionReason(reason);
    } catch (e) {
      print('Ошибка отклонения фото: $e');
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'На проверке';
      case 'approved':
        return 'Одобрено';
      case 'rejected':
        return 'Отклонено';
      default:
        return 'Не пройдено';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFA726);
      case 'approved':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return const Color(0xFFF44336);
      default:
        return AppColors.primaryWithOpacity60;
    }
  }
}
