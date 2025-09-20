import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import 'city_popup_screen.dart';
import 'city_info_screen.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({super.key});

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen>
    with TickerProviderStateMixin {
  String? selectedCity;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _progressController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;

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
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _progressController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _progressController.dispose();
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
            _buildAnimatedCityInput(),
            const Spacer(),
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
            _buildAnimatedStep(1, 'Про вас', isActive: true),
            _buildAnimatedStep(2, 'Про авто', isActive: false),
            _buildAnimatedStep(3, 'Условия', isActive: false),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStep(int number, String title, {required bool isActive}) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? AppColors.textPrimary : const Color(0xFF264b47),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              ),
              child: Center(
                child: Text(
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
      },
    );
  }

  Widget _buildAnimatedCityInput() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Укажите город',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 22 / 15,
                letterSpacing: -0.43,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: _openCityPopup,
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFF264b47),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedCity ?? 'В каком городе вы хотите работать',
                        style: TextStyle(
                          color: selectedCity != null 
                              ? AppColors.textPrimary 
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '>',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openCityPopup() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CityPopupScreen(),
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
        selectedCity = result;
      });
      
      // Сохраняем данные города
      await UserDataService.instance.saveCityData(result);
      
      // Navigate to city info screen
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => CityInfoScreen(selectedCity: result),
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
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    }
  }
}


