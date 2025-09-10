import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../widgets/logo_widget.dart';
import '../onboarding/questionnaire_intro_screen.dart';

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
    if (code == '1111') {
      try {
        await AuthService.login(widget.phoneNumber, 'password');
        if (mounted) {
          // Временно всегда показываем анкетирование для тестирования
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const QuestionnaireIntroScreen(),
            ),
          );
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
          content: Text('Неверный код'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _resendCode() {
    if (_canResend) {
      setState(() {
        _countdown = 37;
        _canResend = false;
      });
      _startTimer();
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Убираем все символы кроме цифр
    final digits = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Если номер начинается с 0, заменяем на +996
    if (digits.startsWith('0') && digits.length == 10) {
      final withoutZero = digits.substring(1);
      return '+996 ${withoutZero.substring(0, 3)} ${withoutZero.substring(3, 6)} ${withoutZero.substring(6, 8)} ${withoutZero.substring(8)}';
    }
    
    // Если номер уже в международном формате
    if (digits.startsWith('996') && digits.length == 12) {
      final withoutCountry = digits.substring(3);
      return '+996 ${withoutCountry.substring(0, 3)} ${withoutCountry.substring(3, 6)} ${withoutCountry.substring(6, 8)} ${withoutCountry.substring(8)}';
    }
    
    // Возвращаем как есть, если формат не распознан
    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
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
          'на номер ${_formatPhoneNumber(widget.phoneNumber)}',
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
                  color: AppColors.primaryWithOpacity,
                  width: 2,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primaryWithOpacity,
                  width: 2,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
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

