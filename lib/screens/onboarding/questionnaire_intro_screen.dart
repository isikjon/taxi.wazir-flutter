import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/logo_widget.dart';
import 'city_selection_screen.dart';

class QuestionnaireIntroScreen extends StatefulWidget {
  const QuestionnaireIntroScreen({super.key});

  @override
  State<QuestionnaireIntroScreen> createState() => _QuestionnaireIntroScreenState();
}

class _QuestionnaireIntroScreenState extends State<QuestionnaireIntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    super.dispose();
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
              _buildAnimatedLogo(),
              const SizedBox(height: AppSpacing.xxl),
              _buildAnimatedTitle(),
              const SizedBox(height: AppSpacing.lg),
              _buildAnimatedDescription(),
              const Spacer(),
              _buildAnimatedStartButton(context),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: const LogoWidget(size: 100),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Text(
          'Заполните анкету',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 23,
            height: 24 / 23,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimatedDescription() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Text(
          'Выберите удобные для вас условия работы и укажите данные о себе. Начнем?',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 22 / 15,
            letterSpacing: -0.43,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAnimatedStartButton(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF264b47),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToCitySelection(context),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              child: Center(
                child: Text(
                  'Начать',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    fontSize: 17,
                    height: 22 / 17,
                    letterSpacing: -0.41,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCitySelection(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const CitySelectionScreen(),
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
