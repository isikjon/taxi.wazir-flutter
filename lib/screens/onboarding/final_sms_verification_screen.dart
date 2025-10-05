import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/api_service.dart';
import '../../services/user_data_service.dart';
import '../auth/phone_auth_screen.dart';

class FinalSmsVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> allData;

  const FinalSmsVerificationScreen({
    super.key,
    required this.allData,
  });

  @override
  State<FinalSmsVerificationScreen> createState() => _FinalSmsVerificationScreenState();
}

class _FinalSmsVerificationScreenState extends State<FinalSmsVerificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  
  String _verificationCode = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildAnimatedContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Подтвердите код из смс',
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 23,
          height: 24 / 23,
          letterSpacing: 0,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildAnimatedContent() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Мы отправили проверочный код на номер +7 999 123 45 67',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 22 / 15,
                letterSpacing: -0.43,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildCodeInputFields(),
            const SizedBox(height: AppSpacing.xl),
            _buildResendCode(),
            const SizedBox(height: AppSpacing.xxl),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              _buildAnimatedConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (index) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFCECECE),
                width: 2,
              ),
            ),
          ),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w600,
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              counterText: '',
            ),
            onChanged: (value) => _onCodeChanged(index, value),
          ),
        );
      }),
    );
  }

  Widget _buildResendCode() {
    return Column(
      children: [
        Text(
          '* Код не пришел (0:09)',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 20 / 14,
            letterSpacing: -0.41,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _resendCode,
          child: Text(
            'Отправить код повторно',
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 20 / 14,
              letterSpacing: -0.41,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedConfirmButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF264b47),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _verificationCode.length == 4 ? _verifyCode : null,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            child: Center(
              child: Text(
                'Подтвердить',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  height: 22 / 17,
                  letterSpacing: -0.41,
                  color: _verificationCode.length == 4 ? Colors.white : Colors.grey,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onCodeChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    setState(() {
      _verificationCode = _controllers.map((controller) => controller.text).join();
    });

    // Автоматическая проверка при вводе 4 цифр
    if (_verificationCode.length == 4) {
      _verifyCode();
    }
  }

  void _resendCode() {
    // TODO: Implement resend code logic
    print('Resending code...');
  }

  void _verifyCode() async {
    if (_verificationCode.length != 4) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Введите полный код из 4 цифр'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _sendDataToBackend();
      
      if (mounted) {
        _showSuccessScreen();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendDataToBackend() async {
    final response = await ApiService.instance.registerDriver(widget.allData);
    
    if (!response['success']) {
      throw Exception(response['error'] ?? 'Registration failed');
    }
    
    print('Driver registered successfully: ${response['data']}');
  }

  void _showSuccessScreen() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Получилось!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Контакты парка мы отправили вам в смс. Выходите на линию!'),
            const SizedBox(height: 16),
            const Text('Условия', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Ваш парк: ${widget.allData['park']['name']}'),
            const SizedBox(height: 4),
            Text('Адрес: ${widget.allData['park']['address']}'),
            const SizedBox(height: 4),
            Text('Телефон: ${widget.allData['park']['phone']}'),
          ],
        ),
        actions: [
            ElevatedButton(
            onPressed: () async {
              // Очищаем данные пользователя после успешной регистрации
              await UserDataService.instance.clearUserData();
              
              Navigator.of(context).pop(); // Закрываем диалог
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF264b47),
              foregroundColor: Colors.white,
            ),
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }
}
