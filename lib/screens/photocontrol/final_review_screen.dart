import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/custom_button.dart';
import '../../services/photo_storage_service.dart';
import '../../services/photo_verification_service.dart';

class FinalReviewScreen extends StatefulWidget {
  const FinalReviewScreen({super.key});

  @override
  State<FinalReviewScreen> createState() => _FinalReviewScreenState();
}

class _FinalReviewScreenState extends State<FinalReviewScreen> {
  final PhotoStorageService _photoStorage = PhotoStorageService();
  final PhotoVerificationService _verificationService = PhotoVerificationService();
  Map<String, String> _allPhotos = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAllPhotos();
  }

  Future<void> _loadAllPhotos() async {
    final photos = await _photoStorage.getAllPhotos();
    setState(() {
      _allPhotos = photos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Проверьте загруженные фотографии перед отправкой',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    if (_allPhotos.containsKey('front') || _allPhotos.containsKey('back') || _allPhotos.containsKey('selfie'))
                      _buildPhotoSection('Водительское удостоверение', [
                        if (_allPhotos.containsKey('front')) 
                          PhotoItem('front', 'Лицевая сторона ВУ', _allPhotos['front']!),
                        if (_allPhotos.containsKey('back')) 
                          PhotoItem('back', 'Обратная сторона ВУ', _allPhotos['back']!),
                        if (_allPhotos.containsKey('selfie')) 
                          PhotoItem('selfie', 'Селфи с ВУ', _allPhotos['selfie']!),
                      ]),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildPhotoSection('Свидетельство о регистрации ТС', [
                      if (_allPhotos.containsKey('sts_front')) 
                        PhotoItem('sts_front', 'Лицевая сторона СТС', _allPhotos['sts_front']!),
                      if (_allPhotos.containsKey('sts_back')) 
                        PhotoItem('sts_back', 'Обратная сторона СТС', _allPhotos['sts_back']!),
                    ]),
                    
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildPhotoSection('Автомобиль', [
                      if (_allPhotos.containsKey('car_front')) 
                        PhotoItem('car_front', 'Автомобиль спереди', _allPhotos['car_front']!),
                      if (_allPhotos.containsKey('car_back')) 
                        PhotoItem('car_back', 'Автомобиль сзади', _allPhotos['car_back']!),
                      if (_allPhotos.containsKey('car_left')) 
                        PhotoItem('car_left', 'Автомобиль слева', _allPhotos['car_left']!),
                      if (_allPhotos.containsKey('car_right')) 
                        PhotoItem('car_right', 'Автомобиль справа', _allPhotos['car_right']!),
                      if (_allPhotos.containsKey('vin')) 
                        PhotoItem('vin', 'VIN номер', _allPhotos['vin']!),
                    ]),
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
              child: CustomButton(
                text: _isLoading ? 'Отправка...' : 'Отправить на проверку',
                onPressed: _isLoading ? null : _submitForVerification,
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
              'Проверка документов',
              style: AppTextStyles.h3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(String title, List<PhotoItem> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        ...photos.map((photo) => _buildPhotoRow(photo)).toList(),
      ],
    );
  }

  Widget _buildPhotoRow(PhotoItem photo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(color: AppColors.primaryWithOpacity20),
            ),
            child: ClipRRect(
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
                            color: const Color(0xFF264b47),
                            size: 20,
                          ),
                        );
                      },
                    )
                  : Image.file(
                      File(photo.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primaryWithOpacity10,
                          child: const Icon(
                            Icons.photo,
                            color: const Color(0xFF264b47),
                            size: 20,
                          ),
                        );
                      },
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              photo.title,
              style: AppTextStyles.bodyMedium,
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _submitForVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _photoStorage.setVerificationStatus('pending');
      
      final success = await _verificationService.submitPhotosForVerification(_allPhotos);
      
      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Не удалось отправить фотографии на проверку. Попробуйте еще раз.');
      }
    } catch (e) {
      _showErrorDialog('Ошибка отправки: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Документы отправлены'),
        content: const Text(
          'Ваши документы отправлены на проверку. Результат будет доступен в течение 24 часов.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('OK'),
          ),
        ],
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

class PhotoItem {
  final String type;
  final String title;
  final String path;

  PhotoItem(this.type, this.title, this.path);
}
