import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/photo_verification_service.dart';
import 'verification_instruction_screen.dart';
import 'sts_main_screen.dart';

class PhotocontrolScreen extends StatefulWidget {
  const PhotocontrolScreen({super.key});

  @override
  State<PhotocontrolScreen> createState() => _PhotocontrolScreenState();
}

class _PhotocontrolScreenState extends State<PhotocontrolScreen> {
  final PhotoVerificationService _verificationService = PhotoVerificationService();
  String _verificationStatus = 'not_started';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
    _loadVerificationStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVerificationStatus();
  }

  Future<void> _loadVerificationStatus() async {
    final statusData = await _verificationService.getVerificationStatus();
    setState(() {
      _verificationStatus = statusData['status'] ?? 'not_started';
      _rejectionReason = statusData['rejection_reason'];
    });
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPhotocontrolItem(
                      'Фотоконтроль в/у',
                      _verificationService.getStatusText(_verificationStatus),
                      _verificationService.getStatusColor(_verificationStatus),
                      () => _handleVuTap(),
                    ),
                    _buildPhotocontrolItem(
                      'Фотоконтроль СТС',
                      _verificationService.getStatusText(_verificationStatus),
                      _verificationService.getStatusColor(_verificationStatus),
                      () => _handleStsTap(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _buildStartVerificationButton(context),
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
              'Фотоконтроль',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadVerificationStatus,
            icon: const Icon(
              Icons.refresh,
              color: AppColors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      'Блокирует работу',
      style: AppTextStyles.h4.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPhotocontrolItem(String title, String status, Color statusColor, VoidCallback onTap) {
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
        onTap: onTap,
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
                  color: AppColors.textSecondary.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      status,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _buildStartVerificationButton(BuildContext context) {
    if (_verificationStatus == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: Colors.orange),
        ),
        child: Column(
          children: [
            Text(
              'Документы на проверке',
              textAlign: TextAlign.center,
              style: AppTextStyles.button.copyWith(
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ожидайте решения диспетчера',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.orange[700],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_verificationStatus == 'approved') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          border: Border.all(color: Colors.green),
        ),
        child: Column(
          children: [
            Text(
              '✅ Документы одобрены',
              textAlign: TextAlign.center,
              style: AppTextStyles.button.copyWith(
                color: Colors.green[800],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Вы можете работать в системе',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }
    
    if (_verificationStatus == 'rejected') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
              border: Border.all(color: Colors.red),
            ),
            child: Column(
              children: [
                Text(
                  '❌ Документы отклонены',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.button.copyWith(
                    color: Colors.red[800],
                  ),
                ),
                if (_rejectionReason != null && _rejectionReason!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Причина: $_rejectionReason',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startVerification(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
              ),
              child: Text(
                'Пройти проверку заново',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.surface,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startVerification(context),
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

  void _startVerification(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const VerificationInstructionScreen(),
      ),
    );
  }

  void _handleVuTap() {
    if (_verificationStatus == 'pending') {
      _showPendingDialog();
    } else if (_verificationStatus == 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Документы уже одобрены.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const VerificationInstructionScreen(),
        ),
      );
    }
  }

  void _handleStsTap() {
    if (_verificationStatus == 'pending') {
      _showPendingDialog();
    } else if (_verificationStatus == 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Документы уже одобрены.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const StsMainScreen(),
        ),
      );
    }
  }

  void _showPendingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Документы на проверке'),
        content: const Text(
          'Ваши документы находятся на проверке у диспетчера. Ожидайте решения.',
        ),
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
