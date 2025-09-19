import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/custom_button.dart';
import '../../services/photo_storage_service.dart';
import 'final_review_screen.dart';

class StsPhotosScreen extends StatefulWidget {
  const StsPhotosScreen({super.key});

  @override
  State<StsPhotosScreen> createState() => _StsPhotosScreenState();
}

class _StsPhotosScreenState extends State<StsPhotosScreen> {
  File? _stsFrontPhoto;
  File? _stsBackPhoto;
  File? _carFrontPhoto;
  File? _carBackPhoto;
  File? _carLeftPhoto;
  File? _carRightPhoto;
  File? _vinPhoto;
  
  final ImagePicker _picker = ImagePicker();
  final PhotoStorageService _photoStorage = PhotoStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
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
                      'Фотоконтроль СТС',
                      style: AppTextStyles.h3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Необходимо отправить фотографии свидетельства о регистрации ТС',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoSlot(
                            'Свидетельства ТС\n(лицевая сторона)',
                            _stsFrontPhoto,
                            'sts_front',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildPhotoSlot(
                            'Свидетельства ТС\n(обратная сторона)',
                            _stsBackPhoto,
                            'sts_back',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoSlot(
                            'Автомобиль спереди',
                            _carFrontPhoto,
                            'car_front',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildPhotoSlot(
                            'Автомобиль слева',
                            _carLeftPhoto,
                            'car_left',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhotoSlot(
                            'Автомобиль сзади',
                            _carBackPhoto,
                            'car_back',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildPhotoSlot(
                            'Автомобиль справа',
                            _carRightPhoto,
                            'car_right',
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppSpacing.lg),
                    
                    Center(
                      child: SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 2,
                        child: _buildPhotoSlot(
                          'VIN - Номер автомобиля',
                          _vinPhoto,
                          'vin',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
            Container(
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
                      child: const Text(
                        'Назад',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: CustomButton(
                      text: 'Отправить',
                      onPressed: _allPhotosSelected() ? () => _proceedToFinalReview() : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSlot(String label, File? photo, String type) {
    return GestureDetector(
      onTap: () => _showPhotoSourceDialog(type),
      child: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
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
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPhotoSourceDialog(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primaryWithOpacity20,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
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
        case 'sts_front':
          _stsFrontPhoto = photo;
          break;
        case 'sts_back':
          _stsBackPhoto = photo;
          break;
        case 'car_front':
          _carFrontPhoto = photo;
          break;
        case 'car_back':
          _carBackPhoto = photo;
          break;
        case 'car_left':
          _carLeftPhoto = photo;
          break;
        case 'car_right':
          _carRightPhoto = photo;
          break;
        case 'vin':
          _vinPhoto = photo;
          break;
      }
    });
  }

  bool _allPhotosSelected() {
    return _stsFrontPhoto != null &&
           _stsBackPhoto != null &&
           _carFrontPhoto != null &&
           _carBackPhoto != null &&
           _carLeftPhoto != null &&
           _carRightPhoto != null &&
           _vinPhoto != null;
  }

  void _proceedToFinalReview() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FinalReviewScreen(),
      ),
    );
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
}
