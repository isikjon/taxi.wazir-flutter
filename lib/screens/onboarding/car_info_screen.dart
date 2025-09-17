import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import 'car_brand_popup_screen.dart';
import 'car_model_popup_screen.dart';
import 'car_color_popup_screen.dart';
import 'car_year_popup_screen.dart';
import 'conditions_screen.dart';

class CarInfoScreen extends StatefulWidget {
  const CarInfoScreen({super.key});

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _bodyNumberController = TextEditingController();
  final TextEditingController _stsController = TextEditingController();

  String? selectedBrand;
  String? selectedModel;
  String? selectedColor;
  String? selectedYear;

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
  }

  void _loadUserData() {
    final userData = UserDataService.instance.userData;
    selectedBrand = userData['carBrand'];
    selectedModel = userData['carModel'];
    selectedColor = userData['carColor'];
    selectedYear = userData['carYear'];
    _licensePlateController.text = userData['licensePlate'] ?? '';
    _vinController.text = userData['vin'] ?? '';
    _bodyNumberController.text = userData['bodyNumber'] ?? '';
    _stsController.text = userData['sts'] ?? '';
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
    _licensePlateController.dispose();
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
            _buildAnimatedProgressSteps(),
            const SizedBox(height: AppSpacing.xxl),
            Expanded(
              child: SingleChildScrollView(
                child: _buildAnimatedForm(),
              ),
            ),
            const SizedBox(height: 10),
            _buildAnimatedContinueButton(context),
            const SizedBox(height: 10),
            SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.bottomSafeArea),
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
        'Заполните анкету',
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

  Widget _buildAnimatedProgressSteps() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAnimatedStep(1, 'Про вас', isActive: false, isCompleted: true),
            _buildAnimatedStep(2, 'Про авто', isActive: true),
            _buildAnimatedStep(3, 'Условия', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStep(int number, String title, {required bool isActive, bool isCompleted = false}) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted 
                ? AppColors.textPrimary 
                : isActive 
                    ? AppColors.textPrimary 
                    : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20,
                  )
                : Text(
                    number.toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
              label: 'Введите Марка',
              value: selectedBrand,
              placeholder: 'Kia',
              onTap: () => _openBrandPopup(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите модель',
              value: selectedModel,
              placeholder: 'Rio',
              onTap: () => _openModelPopup(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите цвет',
              value: selectedColor,
              placeholder: 'Белый',
              onTap: () => _openColorPopup(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите год выпуска',
              value: selectedYear,
              placeholder: '00.00.0000',
              onTap: () => _openYearPopup(),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Введите гос.номер',
              value: _licensePlateController.text,
              placeholder: '01 KG H 1234',
              onTap: null,
              isEditable: true,
              inputFormatters: [LicensePlateFormatter()],
              controller: _licensePlateController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'VIN номер',
              value: _vinController.text,
              placeholder: '1HGBH41JXMN109186',
              onTap: null,
              isEditable: true,
              inputFormatters: [VinFormatter()],
              controller: _vinController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'Номер кузова',
              value: _bodyNumberController.text,
              placeholder: '1234567890',
              onTap: null,
              isEditable: true,
              controller: _bodyNumberController,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildFormField(
              label: 'СТС (серия и номер)',
              value: _stsController.text,
              placeholder: '12 АА 123456',
              onTap: null,
              isEditable: true,
              inputFormatters: [StsFormatter()],
              controller: _stsController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    String? value,
    required String placeholder,
    VoidCallback? onTap,
    bool isEditable = false,
    List<TextInputFormatter>? inputFormatters,
    TextEditingController? controller,
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
          onTap: onTap,
          child:           Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFFCECECE),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isEditable
                      ? TextFormField(
                          controller: controller,
                          onChanged: (value) => setState(() {}),
                          inputFormatters: inputFormatters,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
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
                        )
                      : Text(
                          value ?? placeholder,
                          style: TextStyle(
                            color: value != null ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedContinueButton(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF606060),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _continueToNext(context),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            child: Center(
              child: Text(
                'Продолжить',
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

  void _openBrandPopup() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CarBrandPopupScreen(),
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

    if (result != null && result is String) {
      setState(() {
        selectedBrand = result;
        selectedModel = null; // Сбрасываем модель при смене марки
      });
    }
  }

  void _openModelPopup() async {
    if (selectedBrand == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выберите марку автомобиля'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CarModelPopupScreen(selectedBrand: selectedBrand!),
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

    if (result != null && result is String) {
      setState(() {
        selectedModel = result;
      });
    }
  }

  void _openColorPopup() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CarColorPopupScreen(),
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

    if (result != null && result is String) {
      setState(() {
        selectedColor = result;
      });
    }
  }

  void _openYearPopup() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CarYearPopupScreen(),
        fullscreenDialog: true,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
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

    if (result != null && result is String) {
      setState(() {
        selectedYear = result;
      });
    }
  }

  void _continueToNext(BuildContext context) async {
    // Сохраняем данные автомобиля
    await UserDataService.instance.saveCarData(
      brand: selectedBrand ?? '',
      model: selectedModel ?? '',
      color: selectedColor ?? '',
      year: selectedYear ?? '',
      licensePlate: _licensePlateController.text,
      vin: _vinController.text,
      bodyNumber: _bodyNumberController.text,
      sts: _stsController.text,
    );
    
    print('Car data saved');
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const ConditionsScreen(),
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

class LicensePlateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Удаляем все символы кроме букв и цифр
    final cleanText = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    
    // Первые 2 цифры (код региона)
    if (cleanText.length >= 1) {
      formatted = cleanText.substring(0, 1);
    }
    if (cleanText.length >= 2) {
      formatted += cleanText.substring(1, 2);
    }
    
    // Пробел после кода региона
    if (cleanText.length >= 3) {
      formatted += ' ${cleanText.substring(2, 3)}';
    }
    if (cleanText.length >= 4) {
      formatted += cleanText.substring(3, 4);
    }
    
    // Пробел после первых двух букв
    if (cleanText.length >= 5) {
      formatted += ' ${cleanText.substring(4, 5)}';
    }
    
    // Пробел после третьей буквы
    if (cleanText.length >= 6) {
      formatted += ' ${cleanText.substring(5, 6)}';
    }
    if (cleanText.length >= 7) {
      formatted += cleanText.substring(6, 7);
    }
    if (cleanText.length >= 8) {
      formatted += cleanText.substring(7, 8);
    }
    if (cleanText.length >= 9) {
      formatted += cleanText.substring(8, 9);
    }
    if (cleanText.length >= 10) {
      formatted += cleanText.substring(9, 10);
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class VinFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // VIN может содержать только буквы и цифры, максимум 17 символов
    final cleanText = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final limitedText = cleanText.length > 17 ? cleanText.substring(0, 17) : cleanText;
    
    return newValue.copyWith(
      text: limitedText,
      selection: TextSelection.collapsed(offset: limitedText.length),
    );
  }
}

class StsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.toUpperCase();
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    // Удаляем все символы кроме букв и цифр
    final cleanText = text.replaceAll(RegExp(r'[^A-Z0-9]'), '');
    
    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    
    // Первые 2 цифры (серия)
    if (cleanText.length >= 1) {
      formatted = cleanText.substring(0, 1);
    }
    if (cleanText.length >= 2) {
      formatted += cleanText.substring(1, 2);
    }
    
    // Пробел после серии
    if (cleanText.length >= 3) {
      formatted += ' ${cleanText.substring(2, 3)}';
    }
    if (cleanText.length >= 4) {
      formatted += cleanText.substring(3, 4);
    }
    
    // Пробел после букв
    if (cleanText.length >= 5) {
      formatted += ' ${cleanText.substring(4)}';
    }
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
