import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import 'vu_photos_screen.dart';

class VuMainScreen extends StatelessWidget {
  const VuMainScreen({super.key});

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
                    const SizedBox(height: AppSpacing.lg),
                    _buildDescription(),
                    const Spacer(),
                    _buildDocumentPreview(),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: _buildStartButton(context),
                    ),
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

  Widget _buildDescription() {
    return Text(
      'За подделку документов предусмотрена ответственность согласно действующему законодательству',
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 200,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryWithOpacity05,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(
                color: AppColors.primaryWithOpacity20,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.image_outlined,
              size: 60,
              color: const Color(0xFF264b47),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Электронная',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startPhotoVerification(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
        ),
        child: Text(
          'Пройти проверку',
          style: AppTextStyles.button.copyWith(
            color: AppColors.surface,
          ),
        ),
      ),
    );
  }

  void _startPhotoVerification(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VuPhotosScreen(),
      ),
    );
  }
}
