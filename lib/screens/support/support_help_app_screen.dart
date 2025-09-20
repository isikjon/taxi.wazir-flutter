import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class SupportHelpAppScreen extends StatelessWidget {
  const SupportHelpAppScreen({super.key});

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
                      'Приложение не работает или выдаёт ошибку.',
                      'Почистите кэш на устройстве и переустановите Eco Такси из Play Market. Если рекомендации не помогли, опишите, что происходит: куда вы нажимаете и какая ошибка появляется. Мы разберёмся быстрее, если вы приложите скриншот.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'Навигатор теряет местоположение.',
                      'Попробуйте следующие шаги, часто после них геолокация работает лучше:',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildBulletList([
                      'Выключить энергосберегающий режим',
                      'Подключиться к Wi-Fi',
                      'Закрыть все сторонние приложения',
                      'Проверить настройку GPS-модуля через приложение для тестирования GPS',
                    ]),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'Подключить тариф (если доступен в вашем регионе).',
                      'Чтобы получать заказы в тарифах «Доставка» или «Курьер», зайдите в Eco Такси, переведите рычажок напротив названия тарифа вправо и пройдите короткое обучение. Если вы уже проходили тестирование в «Доставке», сможете получать заказы в «Курьере» без повторного обучения.',
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
              'Помощь с приложением',
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

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '— ',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            Expanded(
              child: Text(
                item,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
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