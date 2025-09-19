import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/photo_storage_service.dart';
import 'sts_main_screen.dart';

class VuPhotosScreen extends StatefulWidget {
  const VuPhotosScreen({super.key});

  @override
  State<VuPhotosScreen> createState() => _VuPhotosScreenState();
}

class _VuPhotosScreenState extends State<VuPhotosScreen> {
  File? _frontSidePhoto;
  File? _backSidePhoto;
  File? _selfiePhoto;
  final ImagePicker _picker = ImagePicker();
  final PhotoStorageService _photoStorage = PhotoStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildPhotoGrid(),
                    const Spacer(),
                    _buildActionButtons(context),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(
        top: 20,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: AppColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Фотоконтроль в/у',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Чтобы получать заказы, пройдите проверку водительского удостоверения.',
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildPhotoSlot(
                'Водительское\nудостоверение:\nлицевая сторона',
                _frontSidePhoto,
                () => _takePhoto('front'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildPhotoSlot(
                'Водительское\nудостоверение:\nобратная сторона',
                _backSidePhoto,
                () => _takePhoto('back'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _buildPhotoSlot(
                'Фото с ВУ',
                _selfiePhoto,
                () => _takePhoto('selfie'),
              ),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot(String label, File? photo, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity05,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(
                color: AppColors.primaryWithOpacity20,
                width: 1,
              ),
            ),
            child: photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    child: kIsWeb 
                        ? Image.network(
                            photo.path,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryWithOpacity10,
                                child: const Icon(
                                  Icons.photo,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          )
                        : Image.file(
                            photo,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.primaryWithOpacity10,
                                child: const Icon(
                                  Icons.photo,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                  )
                : const Icon(
                    Icons.add,
                    size: 40,
                    color: Color(0xFFBBBBBB),
                  ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    bool hasAllPhotos = _frontSidePhoto != null && _backSidePhoto != null && _selfiePhoto != null;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: Text(
                'Назад',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: hasAllPhotos ? () => _submitPhotos(context) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasAllPhotos ? AppColors.primary : AppColors.textSecondary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: Text(
                'Отправить',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _takePhoto(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPhotoSourceBottomSheet(type),
    );
  }

  Widget _buildPhotoSourceBottomSheet(String type) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Сфотографировать'),
            onTap: () {
              Navigator.of(context).pop();
              _takePhotoWithCamera(type);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Выбрать из галереи'),
            onTap: () {
              Navigator.of(context).pop();
              _pickFromGallery(type);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _takePhotoWithCamera(String type) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        final File photoFile = File(photo.path);
        _setPhotoByType(type, photoFile);
        await _photoStorage.savePhoto(type, photoFile);
      }
    } catch (e) {
      _showErrorDialog('Ошибка при съемке: $e');
    }
  }

  Future<void> _pickFromGallery(String type) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        final File photoFile = File(photo.path);
        _setPhotoByType(type, photoFile);
        await _photoStorage.savePhoto(type, photoFile);
      }
    } catch (e) {
      _showErrorDialog('Ошибка выбора из галереи: $e');
    }
  }

  void _setPhotoByType(String type, File photo) {
    setState(() {
      switch (type) {
        case 'front':
          _frontSidePhoto = photo;
          break;
        case 'back':
          _backSidePhoto = photo;
          break;
        case 'selfie':
          _selfiePhoto = photo;
          break;
      }
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ошибка'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _submitPhotos(BuildContext context) async {
    try {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Сохраняем фото локально, не отправляем на сервер
      await Future.delayed(const Duration(seconds: 1));

      // Закрываем индикатор загрузки
      Navigator.of(context).pop();

      // Переходим к фотоконтролю СТС
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const StsMainScreen(),
        ),
      );
    } catch (e) {
      // Закрываем индикатор загрузки в случае ошибки
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Ошибка'),
          content: Text('Не удалось отправить фотографии: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
