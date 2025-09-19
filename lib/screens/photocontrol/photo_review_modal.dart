import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/photo_storage_service.dart';

class PhotoReviewModal extends StatefulWidget {
  final VoidCallback onApprove;
  final Function(String) onReject;

  const PhotoReviewModal({
    super.key,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<PhotoReviewModal> createState() => _PhotoReviewModalState();
}

class _PhotoReviewModalState extends State<PhotoReviewModal> {
  final PhotoStorageService _photoStorage = PhotoStorageService();
  Map<String, String> _allPhotos = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final photos = await _photoStorage.getAllPhotos();
    setState(() {
      _allPhotos = photos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Expanded(
                child: _buildPhotoGrid(),
              ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Проверка документов',
              style: AppTextStyles.h3,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid() {
    if (_allPhotos.isEmpty) {
      return Center(
        child: Text(
          'Нет загруженных фотографий',
          style: AppTextStyles.bodyLarge,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          if (_hasStsCar())
            _buildPhotoSection('Документы и автомобиль', [
              if (_allPhotos.containsKey('sts_front')) 
                PhotoItem('sts_front', 'Лицевая сторона СТС', _allPhotos['sts_front']!),
              if (_allPhotos.containsKey('sts_back')) 
                PhotoItem('sts_back', 'Обратная сторона СТС', _allPhotos['sts_back']!),
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
    );
  }

  bool _hasStsCar() {
    return _allPhotos.containsKey('sts_front') ||
           _allPhotos.containsKey('sts_back') ||
           _allPhotos.containsKey('car_front') ||
           _allPhotos.containsKey('car_back') ||
           _allPhotos.containsKey('car_left') ||
           _allPhotos.containsKey('car_right') ||
           _allPhotos.containsKey('vin');
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.2,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) => _buildPhotoCard(photos[index]),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(PhotoItem photo) {
    return GestureDetector(
      onTap: () => _showFullScreenPhoto(photo),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: const Color(0xFFE0E0E0)),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.borderRadius),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
                  child: kIsWeb 
                      ? Image.network(
                          photo.path,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.photo,
                              color: Colors.grey,
                              size: 40,
                            );
                          },
                        )
                      : Image.file(
                          File(photo.path),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.photo,
                              color: Colors.grey,
                              size: 40,
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: Text(
                photo.title,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _showRejectDialog,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: const Text(
                'Отклонить',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onApprove,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: const Text(
                'Одобрить',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenPhoto(PhotoItem photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: kIsWeb 
                  ? Image.network(photo.path, fit: BoxFit.contain)
                  : Image.file(File(photo.path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  photo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Причина отклонения'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Введите причину отклонения документов',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.of(context).pop();
                widget.onReject(reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Отклонить',
              style: TextStyle(color: Colors.white),
            ),
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
