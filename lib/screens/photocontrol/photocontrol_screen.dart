import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/photo_verification_service.dart';
import '../../services/photo_storage_service.dart';
import 'verification_instruction_screen.dart';
import 'sts_main_screen.dart';
import 'photo_review_modal.dart';

class PhotocontrolScreen extends StatefulWidget {
  const PhotocontrolScreen({super.key});

  @override
  State<PhotocontrolScreen> createState() => _PhotocontrolScreenState();
}

class _PhotocontrolScreenState extends State<PhotocontrolScreen> {
  final PhotoVerificationService _verificationService = PhotoVerificationService();
  final PhotoStorageService _photoStorage = PhotoStorageService();
  String _verificationStatus = 'not_started';
  String? _rejectionReason;

  @override
  void initState() {
    super.initState();
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
        child: Text(
          'Документы на проверке',
          textAlign: TextAlign.center,
          style: AppTextStyles.button.copyWith(
            color: Colors.orange[800],
          ),
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
        child: Text(
          'Документы одобрены',
          textAlign: TextAlign.center,
          style: AppTextStyles.button.copyWith(
            color: Colors.green[800],
          ),
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _verificationStatus == 'rejected' || _verificationStatus == 'not_started' 
            ? () => _startVerification(context) 
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
          ),
        ),
        child: Text(
          _verificationStatus == 'rejected' ? 'Пройти проверку заново' : 'Пройти проверку',
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
    if (_verificationStatus == 'approved' || _verificationStatus == 'pending') {
      _showPhotoReviewModal();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const VerificationInstructionScreen(),
        ),
      );
    }
  }

  void _handleStsTap() {
    if (_verificationStatus == 'approved' || _verificationStatus == 'pending') {
      _showPhotoReviewModal();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const StsMainScreen(),
        ),
      );
    }
  }

  void _showPhotoReviewModal() {
    showDialog(
      context: context,
      builder: (context) => PhotoReviewModal(
        onApprove: _approvePhotos,
        onReject: _rejectPhotos,
      ),
    );
  }

  void _approvePhotos() {
    _verificationService.approvePhotos();
    setState(() {
      _verificationStatus = 'approved';
      _rejectionReason = null;
    });
    Navigator.of(context).pop();
  }

  void _rejectPhotos(String reason) {
    _verificationService.rejectPhotos(reason);
    setState(() {
      _verificationStatus = 'rejected';
      _rejectionReason = reason;
    });
    Navigator.of(context).pop();
  }
}
