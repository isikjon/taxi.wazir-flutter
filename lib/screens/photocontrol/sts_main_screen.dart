import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/custom_button.dart';
import 'sts_photos_screen.dart';

class StsMainScreen extends StatelessWidget {
  const StsMainScreen({super.key});

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
                    Text(
                      'Необходимо отправить фотографии СТС.',
                      style: AppTextStyles.bodyLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'За подделку документов предусмотрена ответственность согласно действующему законодательству',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.left,
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.primaryWithOpacity05,
                        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: const Color(0xFF264b47),
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text(
                            'Иллюстрация',
                            style: TextStyle(
                              color: const Color(0xFF264b47),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
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
                text: 'Пройти проверку',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const StsPhotosScreen(),
                    ),
                  );
                },
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
              'Фотоконтроль СТС',
              style: AppTextStyles.h3,
            ),
          ),
        ],
      ),
    );
  }
}
