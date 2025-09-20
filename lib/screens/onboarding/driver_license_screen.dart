import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import 'car_info_screen.dart';

class DriverLicenseScreen extends StatefulWidget {
  const DriverLicenseScreen({super.key});

  @override
  State<DriverLicenseScreen> createState() => _DriverLicenseScreenState();
}

class _DriverLicenseScreenState extends State<DriverLicenseScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _licenseNumberController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _invitationCodeController = TextEditingController();
  final TextEditingController _callSignController = TextEditingController();

  bool _isIssueDateValid = true;
  String? selectedTariff;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadUserData();
    _startAnimations();
    _setupControllers();
  }

  void _loadUserData() {
    final userData = UserDataService.instance.userData;
    _countryController.text = userData['country'] ?? '';
    _fullNameController.text = userData['fullName'] ?? '';
    _licenseNumberController.text = userData['licenseNumber'] ?? '';
    _issueDateController.text = userData['issueDate'] ?? '';
    _expiryDateController.text = userData['expiryDate'] ?? '';
    _invitationCodeController.text = userData['invitationCode'] ?? '';
    _callSignController.text = userData['callSign'] ?? '';
    selectedTariff = userData['tariff'];
  }

  void _setupControllers() {
    _issueDateController.addListener(_validateIssueDate);
    _countryController.text = 'Республика Кыргызстан';
  }

  void _validateIssueDate() {
    final date = _issueDateController.text;
    if (date.isNotEmpty) {
      // Простая валидация даты DD.MM.YYYY
      final regex = RegExp(r'^\d{2}\.\d{2}\.\d{4}$');
      final isValid = regex.hasMatch(date);
      
      if (isValid) {
        final parts = date.split('.');
        final day = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final year = int.tryParse(parts[2]);
        
        if (day != null && month != null && year != null) {
          final isValidDate = day >= 1 && day <= 31 && 
                             month >= 1 && month <= 12 && 
                             year >= 1900 && year <= DateTime.now().year;
          
          if (mounted) {
            setState(() {
              _isIssueDateValid = isValidDate;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isIssueDateValid = false;
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isIssueDateValid = true;
        });
      }
    }
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
    _countryController.dispose();
    _fullNameController.dispose();
    _licenseNumberController.dispose();
    _issueDateController.dispose();
    _expiryDateController.dispose();
    _invitationCodeController.dispose();
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedForm(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildAnimatedConfirmButton(context),
            const SizedBox(height: 10),
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
        'Заполните данные ВУ',
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

  Widget _buildAnimatedForm() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFormField(
              label: 'Введите страну',
              controller: _countryController,
              placeholder: 'Республика Кыргызстан',
              hasArrow: true,
              isActive: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите Ф.И.О.',
              controller: _fullNameController,
              placeholder: 'Маасалиев Талантбек',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите номер в/у',
              controller: _licenseNumberController,
              placeholder: 'в/у 12 34 567890',
              inputFormatters: [
                DriverLicenseFormatter(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите дату выдачи в/у',
              controller: _issueDateController,
              placeholder: '25.01.2009',
              inputFormatters: [
                DateInputFormatter(),
              ],
              hasError: !_isIssueDateValid,
              errorText: !_isIssueDateValid ? 'некорректная дата' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите срок действия в/у (если есть)',
              controller: _expiryDateController,
              placeholder: '15.12.2028',
              inputFormatters: [
                DateInputFormatter(),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите код приглашения (если есть)',
              controller: _invitationCodeController,
              placeholder: '1200048930000',
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Позывной',
              controller: _callSignController,
              placeholder: 'Введите позывной',
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildTariffField(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    bool hasArrow = false,
    bool hasError = false,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
    bool isActive = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 22 / 15,
            letterSpacing: -0.43,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: hasArrow ? () => _handleFieldTap(label) : null,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: hasError ? Colors.red : const Color(0xFFCECECE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    inputFormatters: inputFormatters,
                    style: TextStyle(
                      color: isActive ? AppColors.textPrimary : AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    enabled: !hasArrow,
                  ),
                ),
                if (hasArrow)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnimatedConfirmButton(BuildContext context) {
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
            onTap: () => _confirmData(context),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            child: Center(
              child: Text(
                'Подтвердить',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  height: 22 / 17,
                  letterSpacing: -0.41,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleFieldTap(String fieldLabel) {
    // TODO: Implement field-specific actions
    print('Tapped on field: $fieldLabel');
  }

  Widget _buildTariffField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Тариф',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFCECECE),
                width: 1,
              ),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTariff,
              hint: Text(
                'Выберите тариф',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'Эконом',
                  child: Text('Эконом'),
                ),
                DropdownMenuItem(
                  value: 'Комфорт',
                  child: Text('Комфорт'),
                ),
                DropdownMenuItem(
                  value: 'Бизнес',
                  child: Text('Бизнес'),
                ),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  selectedTariff = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  void _confirmData(BuildContext context) async {
    // Сохраняем данные водительских прав
    await UserDataService.instance.saveDriverLicenseData(
      country: _countryController.text,
      fullName: _fullNameController.text,
      licenseNumber: _licenseNumberController.text,
      issueDate: _issueDateController.text,
      expiryDate: _expiryDateController.text,
      invitationCode: _invitationCodeController.text,
      callSign: _callSignController.text,
      tariff: selectedTariff ?? 'Эконом',
    );
    
    print('Driver license data saved');
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CarInfoScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

class DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (text.length > 8) {
      return oldValue;
    }
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    if (text.length >= 1) {
      formatted = text.substring(0, 1);
    }
    if (text.length >= 2) {
      formatted += text.substring(1, 2);
    }
    if (text.length >= 3) {
      formatted += '.${text.substring(2, 3)}';
    }
    if (text.length >= 4) {
      formatted += text.substring(3, 4);
    }
    if (text.length >= 5) {
      formatted += '.${text.substring(4, 5)}';
    }
    if (text.length >= 6) {
      formatted += text.substring(5, 6);
    }
    if (text.length >= 7) {
      formatted += text.substring(6, 7);
    }
    if (text.length >= 8) {
      formatted += text.substring(7, 8);
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DriverLicenseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Убираем все символы кроме букв и цифр
    final text = newValue.text.replaceAll(RegExp(r'[^а-яА-Яa-zA-Z0-9]'), '');
    
    // Ограничиваем до 10 символов (4 для серии + 6 для номера)
    if (text.length > 10) {
      return oldValue;
    }
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    
    // Первые 2 символа серии
    if (text.length >= 1) {
      formatted = text.substring(0, 1);
    }
    if (text.length >= 2) {
      formatted += text.substring(1, 2);
    }
    
    // Пробел после первых 2 символов
    if (text.length >= 3) {
      formatted += ' ${text.substring(2, 3)}';
    }
    if (text.length >= 4) {
      formatted += text.substring(3, 4);
    }
    
    // Пробел после серии (4 символа)
    if (text.length >= 5) {
      formatted += ' ${text.substring(4, 5)}';
    }
    if (text.length >= 6) {
      formatted += text.substring(5, 6);
    }
    if (text.length >= 7) {
      formatted += text.substring(6, 7);
    }
    if (text.length >= 8) {
      formatted += text.substring(7, 8);
    }
    if (text.length >= 9) {
      formatted += text.substring(8, 9);
    }
    if (text.length >= 10) {
      formatted += text.substring(9, 10);
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
