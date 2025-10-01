import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/logo_widget.dart';
import '../onboarding/questionnaire_intro_screen.dart';
import '../main/main_app_screen.dart';
import 'phone_auth_screen.dart';

class SmsVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const SmsVerificationScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<SmsVerificationScreen> createState() => _SmsVerificationScreenState();
}

class _SmsVerificationScreenState extends State<SmsVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  
  Timer? _timer;
  int _countdown = 37;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _sendSmsCode();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  void _onCodeChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _checkCode();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _checkCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length == 4) {
      try {
        final fullPhoneNumber = '+996${widget.phoneNumber}';
        final response = await AuthService.login(fullPhoneNumber, code);
        
        if (response['success'] && mounted) {
          if (response['isNewUser']) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const QuestionnaireIntroScreen(),
              ),
              (route) => false,
            );
          } else {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MainAppScreen(),
              ),
              (route) => false,
            );
          }
        } else if (mounted) {
          // Проверяем специальные случаи блокировки и удаления
          if (response['error'] == 'blocked' || response['error'] == 'deleted') {
            _showBlockedDialog(response['message'] ?? 'Ваш аккаунт заблокирован. Для связи: +996 559 868 878');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['error'] ?? 'Ошибка авторизации'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка авторизации: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите полный код'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _sendSmsCode() async {
    try {
      final fullPhoneNumber = '+996${widget.phoneNumber}';
      final response = await ApiService.instance.sendSmsCode(fullPhoneNumber);
      
      if (response['success'] && mounted) {
        // Проверяем, используется ли fallback режим
        if (response['provider'] == 'fallback' || response['provider'] == 'devino') {
          final smsCode = response['data']?['smsCode'] ?? response['test_code'];
          final fallbackReason = response['fallback_reason'];
          
          if (smsCode != null) {
            // Показываем тестовый код пользователю
            _showTestCodeDialog(smsCode, fallbackReason);
          }
        }
      } else if (!response['success'] && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['error'] ?? 'Ошибка отправки SMS'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка отправки SMS: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showTestCodeDialog(String smsCode, String? reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Тестовый режим',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SMS сервис временно недоступен. Используйте тестовый код:',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      smsCode,
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (reason != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Причина: $reason',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Автоматически заполняем код
                for (int i = 0; i < smsCode.length && i < _controllers.length; i++) {
                  _controllers[i].text = smsCode[i];
                }
                // Переходим к последнему полю
                if (_controllers.isNotEmpty) {
                  _focusNodes.last.requestFocus();
                }
              },
              child: Text(
                'Ввести код',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _resendCode() {
    if (_canResend) {
      setState(() {
        _countdown = 37;
        _canResend = false;
      });
      _startTimer();
      _sendSmsCode();
    }
  }

  void _showBlockedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Доступ ограничен',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+996 559 868 878',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const PhoneAuthScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                'Понятно',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatPhoneNumber(String phoneNumber) {
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 9) {
      return '${digits.substring(0, 3)} ${digits.substring(3, 6)} ${digits.substring(6, 9)}';
    }
    
    if (digits.startsWith('996') && digits.length == 12) {
      final withoutCountry = digits.substring(3);
      return '${withoutCountry.substring(0, 3)} ${withoutCountry.substring(3, 6)} ${withoutCountry.substring(6, 9)}';
    }
    
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - (AppSpacing.lg * 2),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _buildLogo(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildTitle(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildCodeInputs(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildResendButton(),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const LogoWidget();
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Введите код из смс. Мы отправили его',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'на номер +996 ${_formatPhoneNumber(widget.phoneNumber)}',
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCodeInputs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return SizedBox(
          width: 50,
          child: TextFormField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFCECECE),
                  width: 1,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFCECECE),
                  width: 1,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color(0xFFCECECE).withOpacity(0.8),
                  width: 1,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            onChanged: (value) => _onCodeChanged(index, value),
          ),
        );
      }),
    );
  }

  Widget _buildResendButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: _canResend ? _resendCode : null,
        child: Text(
          _canResend 
              ? 'Отправить код повторно'
              : 'Код не пришел (${_formatTime(_countdown)})',
          style: AppTextStyles.bodyMedium.copyWith(
            color: _canResend ? AppColors.primary : AppColors.textSecondaryWithOpacity,
            decoration: _canResend ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

