import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class SupportOrdersScreen extends StatelessWidget {
  const SupportOrdersScreen({super.key});

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
                      'Заказы распределяются системой автоматически и таксопарки могут назначить заказ вручную. Это даёт всем водителям равные условия работы. Бывает, что новый заказ приходит не сразу. Чаще всего это означает, что сейчас в районе низкий спрос.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Если нового заказа нет дольше 20 минут, начните с этих шагов:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildBulletList([
                      'Проверьте раздел Диагностика: если есть ограничения по заказам, там будут все подробности',
                      'Перезагрузите телефон или планшет',
                      'Проверьте, есть ли стабильное интернет-подключение',
                      'Перезапустите - Вазир',
                      'Включите статус - На линии',
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Если всё работает стабильно, но заказы не приходят, обратите внимание на эти рекомендации:',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildBulletList([
                      'Не стойте на месте, перемещайтесь',
                      'Переключайтесь в статус Занят только при необходимости',
                      'Смотрите карту повышенного спроса',
                      'Учитывайте, что заказов будет меньше, если включён режим «Домой» или «По делам»,',
                      'выбран только один способ оплаты или отключены некоторые тарифы',
                    ]),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Если ничего не помогает— позвоните в поддержку, будем разбираться вместе.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
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
              'Не получаю новые заказы',
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