import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// Условные импорты для разных платформ
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:path_provider/path_provider.dart';

class PhotoStorageService {
  static const String _vuPhotosKey = 'vu_photos';
  static const String _stsPhotosKey = 'sts_photos';
  static const String _photoStatusKey = 'photo_verification_status';

  Future<void> savePhoto(String type, dynamic photo) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String key;
      if (type.contains('front') && type.contains('vu') || 
          type.contains('back') && type.contains('vu') || 
          type == 'selfie') {
        key = _vuPhotosKey;
      } else {
        key = _stsPhotosKey;
      }
      
      final existingPhotos = prefs.getString(key);
      Map<String, String> photos = {};
      
      if (existingPhotos != null) {
        photos = Map<String, String>.from(json.decode(existingPhotos));
      }
      
      if (kIsWeb) {
        // Для веб-версии сохраняем blob-ссылку (временно для локального хранения)
        photos[type] = photo.path;
        print('📸 Веб: сохранена blob-ссылка: ${photo.path}');
      } else {
        // Для мобильных платформ копируем файл в постоянное хранилище
        try {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final targetPath = '${directory.path}/$fileName';
          final savedFile = await photo.copy(targetPath);
          photos[type] = savedFile.path;
          print('📸 Мобильная версия: файл сохранен: ${savedFile.path}');
        } catch (e) {
          print('❌ Ошибка сохранения файла: $e');
          return;
        }
      }
      
      await prefs.setString(key, json.encode(photos));
      print('📸 Данные о фото сохранены в SharedPreferences для типа: $type');
    } catch (e) {
      print('❌ Ошибка сохранения фото: $e');
    }
  }

  Future<Map<String, String>> getVuPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photosJson = prefs.getString(_vuPhotosKey);
      
      if (photosJson != null) {
        return Map<String, String>.from(json.decode(photosJson));
      }
    } catch (e) {
      print('Ошибка получения фото ВУ: $e');
    }
    return {};
  }

  Future<Map<String, String>> getStsPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photosJson = prefs.getString(_stsPhotosKey);
      
      if (photosJson != null) {
        return Map<String, String>.from(json.decode(photosJson));
      }
    } catch (e) {
      print('Ошибка получения фото СТС: $e');
    }
    return {};
  }

  Future<Map<String, String>> getAllPhotos() async {
    final vuPhotos = await getVuPhotos();
    final stsPhotos = await getStsPhotos();
    
    return {...vuPhotos, ...stsPhotos};
  }

  Future<String?> getPhotoPath(String type) async {
    final allPhotos = await getAllPhotos();
    return allPhotos[type];
  }

  Future<void> setVerificationStatus(String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoStatusKey, status);
    } catch (e) {
      print('Ошибка сохранения статуса: $e');
    }
  }

  Future<String> getVerificationStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_photoStatusKey) ?? 'not_started';
    } catch (e) {
      print('Ошибка получения статуса: $e');
      return 'not_started';
    }
  }

  Future<void> clearAllPhotos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_vuPhotosKey);
      await prefs.remove(_stsPhotosKey);
      await prefs.remove(_photoStatusKey);
    } catch (e) {
      print('Ошибка очистки фото: $e');
    }
  }

  Future<String?> getRejectionReason() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('photo_rejection_reason');
    } catch (e) {
      print('Ошибка получения причины отклонения: $e');
      return null;
    }
  }

  Future<void> setRejectionReason(String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('photo_rejection_reason', reason);
    } catch (e) {
      print('Ошибка сохранения причины отклонения: $e');
    }
  }

}
