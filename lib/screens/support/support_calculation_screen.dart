import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class SupportCalculationScreen extends StatelessWidget {
  const SupportCalculationScreen({super.key});

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
                      'У меня вопрос про расчет стоимости заказа',
                      'Если нужно разобраться с оплатой или бонусами или комиссией по заказу — выберите из списка заказов нужный и позвоните в поддержку.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'Не пришли деньги за заказ, и прошло меньше трёх дней.',
                      'Мы возмещаем нужную сумму не позднее 3 дней с момента совершения поездки. Вам не нужно для этого ничего делать — через три дня деньги придут сами. Бывает, что пришла только часть суммы, это означает, что недостающая часть дойдёт. Не пришли деньги за заказ, и прошло больше трёх дней. Позвоните в поддержку — будем разбираться.',
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSection(
                      'Как снимается комиссия.',
                      'Комиссия — это плата за получение заказа, она списывается за каждую поездку. Есть комиссия сервиса и комиссия парка-партнёра (если вы работаете в компании). Списание комиссии по каждому заказу отражается в Карточке финансового отчёта в профиле.',
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
              'У меня вопрос про расчет стоимости заказа',
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