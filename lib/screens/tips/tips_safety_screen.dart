import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class TipsSafetyScreen extends StatelessWidget {
  const TipsSafetyScreen({super.key});

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
              'Безопасность',
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
            'Профилактика вирусных инфекций',
            [
              _buildSubsection(
                'Вирусной инфекции, в том числе и коронавирус, передаются',
                [
                  _buildBulletPoint('При чихании и кашле'),
                  _buildBulletPoint('При рукопожатиях'),
                  _buildBulletPoint('При использовании одной посуды с носителем болезни'),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSubsection(
                'Вот что советуют врачи',
                [
                  _buildNestedSubsection(
                    'В машине',
                    [
                      'Проветривайте салон после каждой поездки',
                      'Два раза в день протираете руль, ручки, кресло спиртовыми салфетками',
                      'Чаще обрабатываете руки антисептика',
                      'Уберите из салона конфеты и другие угощение',
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildNestedSubsection(
                    'В любое время',
                    [
                      'Не ходить и туда где много людей',
                      'Если рядом чихают и кашляет наденкайте медицинскую маску',
                      'Рене прикасаетесь руками к лицу',
                      'Не ешьте и не пейте из одной посуды с другими людьми',
                      'Чихайте кашлять одноразовые салфетки',
                      'Если нет салфеток прикрываетесь локтям',
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildSubsection(
                'Обратитесь к врачу, если у вас',
                [
                  _buildBulletPoint('Повышиная температура'),
                  _buildBulletPoint('Кашель'),
                  _buildBulletPoint('Насморк'),
                  _buildBulletPoint('Расстройство жатудия'),
                  _buildBulletPoint('Затрудненое дыхание'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> content) {
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
        ...content,
      ],
    );
  }

  Widget _buildSubsection(String title, List<Widget> content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...content,
      ],
    );
  }

  Widget _buildNestedSubsection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                decoration: const BoxDecoration(
                  color: const Color(0xFF264b47),
                  shape: BoxShape.circle,
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
        )),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
            decoration: const BoxDecoration(
              color: Color(0xFF999999),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
