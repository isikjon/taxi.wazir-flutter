import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import 'support_help_app_screen.dart';
import 'support_documents_screen.dart';
import 'support_payment_screen.dart';
import 'support_items_screen.dart';
import 'support_orders_screen.dart';
import 'support_access_screen.dart';
import 'support_calculation_screen.dart';

class SupportMainScreen extends StatelessWidget {
  const SupportMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildWriteToSupport(context),
            const Divider(height: 1, color: AppColors.divider),
            Expanded(
              child: _buildPopularQuestions(context),
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
              'Служба поддержки',
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

  Widget _buildWriteToSupport(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: InkWell(
        onTap: () => _callSupport(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Написать в поддержку',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularQuestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Популярные вопросы',
            style: AppTextStyles.h4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            children: [
              _buildQuestionItem(
                context,
                'Помощь с приложением',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportHelpAppScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'Я поменял документы',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportDocumentsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'Мне не платит парк-партнер',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportPaymentScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'В машине остались вещи или...',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportItemsScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'Не получаю новые заказы',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportOrdersScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'Почему закрыт доступ',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportAccessScreen(),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              _buildQuestionItem(
                context,
                'У меня вопрос про расчет...',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportCalculationScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionItem(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
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
