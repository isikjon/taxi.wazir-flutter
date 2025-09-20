import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class SupportDocumentsScreen extends StatelessWidget {
  const SupportDocumentsScreen({super.key});

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
                    _buildSection(
                      'Водительское удостоверение.',
                      'Ваш рейтинг привязывается к водительскому удостоверению. Чтобы обновить информацию в Eco Такси и восстановить рейтинг, пришлите нам два номера — старого и нового водительского удостоверения. И прикрепите цветные фотографии нового удостоверения с обеих сторон.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'Документы на автомобиль.',
                      'Напишите нам, какие данные нужно изменить, пришлите 7 фотографий машины (задних сидений; переднего пассажирского сиденья; правого и левого борта; передней и задней части авто; открытого багажника, свободного не менее, чем наполовину) и прикрепите фотографии свидетельства о регистрации автомобиля.',
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildCallButton(),
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
              'Я поменял документы',
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

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.h4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCallButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _callSupport,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        ),
        child: Text(
          'Позвонить в поддержку',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _callSupport() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+996559868878');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }
}