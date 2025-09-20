import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class TipsStartScreen extends StatelessWidget {
  const TipsStartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildContent(),
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
              'С чего начать',
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

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            'Куда обратиться за помощью.',
            [
              'Если у вас возникли технические проблемы или появились вопросы по работе с сервисом вы всегда можете написать в службу поддержки через соответствующий раздел меню в Eco Такси. Сотрудники службы поддержки помогут вам в любой ситуации - например, если:',
              '—клиенты забыли вещи в вашем автомобиле,',
              '—возникли проблемы с безналичной оплатой.',
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Помните,',
            [
              'что некоторые важные вопросы вам помогут решить в таксопарке:',
              '—проконсультировать о выводе денежных средств со счета и пополнении счета водителя,',
              '—рассказать о смене водительского удостоверения.',
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildParagraph(
            'Ещё можно приехать в Центр для водителей и лично пообщаться со специалистом.',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildParagraph(
            'Центр для водителей в Бишкеке работает по адресу: Бульвар Эркиндик 58а.',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildParagraph(
            'Ждём вас с 10:00 до 19:00 по будням.',
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> content) {
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
        const SizedBox(height: AppSpacing.md),
        ...content.map((text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }
}
