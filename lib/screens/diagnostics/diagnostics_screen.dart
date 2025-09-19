import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/diagnostics_service.dart';
import '../../services/photo_verification_service.dart';

class DiagnosticsScreen extends StatefulWidget {
  final String? currentTariff;
  final double? currentBalance;

  const DiagnosticsScreen({
    super.key,
    this.currentTariff,
    this.currentBalance,
  });

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  DiagnosticsData? _diagnosticsData;
  bool _isLoading = true;
  final PhotoVerificationService _verificationService = PhotoVerificationService();
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadDiagnosticsData();
  }

  Future<void> _loadDiagnosticsData() async {
    try {
      final data = await DiagnosticsService.instance.getDiagnosticsStatus(
        currentTariff: widget.currentTariff,
        currentBalance: widget.currentBalance,
      );
      
      final statusData = await _verificationService.getVerificationStatus();
      final rejectionReason = statusData['rejection_reason'];
      
      if (mounted) {
        setState(() {
          _diagnosticsData = data;
          _rejectionReason = rejectionReason;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
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
              'Диагностика',
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
    if (_diagnosticsData == null) {
      return const Center(
        child: Text('Ошибка загрузки данных'),
      );
    }

    final issues = _getIssuesList();
    
    if (issues.isEmpty) {
      return _buildAllGoodMessage();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Доступ временно приостановлен',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Чтобы снова выполнить заказы, устраните эти проблемы:',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...issues.map((issue) => _buildIssueItem(issue)),
        ],
      ),
    );
  }

  Widget _buildAllGoodMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 80,
              color: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Все требования выполнены',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Вы можете выполнять заказы',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(DiagnosticsIssue issue) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity30,
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: issue.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textSecondary,
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      issue.title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (issue.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        issue.subtitle!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
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
      ),
    );
  }

  List<DiagnosticsIssue> _getIssuesList() {
    if (_diagnosticsData == null) return [];

    final issues = <DiagnosticsIssue>[];

    if (!_diagnosticsData!.hasActiveTariff) {
      issues.add(DiagnosticsIssue(
        title: 'Включите хотя бы один тариф',
        onTap: () {
          // Навигация к тарифам
          Navigator.of(context).pop();
        },
      ));
    }

    if (!_diagnosticsData!.hasStsPhotoControl) {
      issues.add(DiagnosticsIssue(
        title: 'Пройдите фотоконтроль СТС',
        subtitle: _rejectionReason,
        onTap: () {
          Navigator.of(context).pop();
        },
      ));
    }

    if (!_diagnosticsData!.hasVuPhotoControl) {
      issues.add(DiagnosticsIssue(
        title: 'Пройдите фотоконтроль ВУ',
        subtitle: _rejectionReason,
        onTap: () {
          Navigator.of(context).pop();
        },
      ));
    }

    if (!_diagnosticsData!.hasEnoughBalance) {
      issues.add(DiagnosticsIssue(
        title: 'Низкий баланс',
        onTap: () {
          // Навигация к пополнению баланса
          Navigator.of(context).pop();
        },
      ));
    }

    return issues;
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(feature),
        content: const Text('Эта функция находится в разработке'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class DiagnosticsIssue {
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  DiagnosticsIssue({
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
