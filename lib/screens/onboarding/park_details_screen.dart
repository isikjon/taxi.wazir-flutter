import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import 'data_confirmation_screen.dart';

class ParkDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> park;

  const ParkDetailsScreen({
    super.key,
    required this.park,
  });

  @override
  State<ParkDetailsScreen> createState() => _ParkDetailsScreenState();
}

class _ParkDetailsScreenState extends State<ParkDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildAnimatedContent(),
            ),
          ),
          _buildAnimatedSelectButton(),
        ],
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
        '${widget.park['name']} ${widget.park['city']}',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWithdrawalConditions(),
            const SizedBox(height: AppSpacing.xl),
            _buildContactsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawalConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _openWithdrawalConditions,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Условия вывода средств',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 22 / 16,
                    letterSpacing: -0.41,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 1,
          color: const Color(0xFFE0E0E0),
        ),
      ],
    );
  }

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Контакты',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            height: 24 / 18,
            letterSpacing: 0,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildContactItem('Телефон', widget.park['phone'], () => _makePhoneCall(widget.park['phone'])),
        _buildContactItem('График работы', widget.park['working_hours'], null),
        _buildContactItem('Почта', widget.park['email'], () => _sendEmail(widget.park['email'])),
        _buildContactItem('Адрес', widget.park['address'], null),
      ],
    );
  }

  Widget _buildContactItem(String label, String value, VoidCallback? onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 22 / 16,
              letterSpacing: -0.41,
              color: onTap != null ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          height: 1,
          color: const Color(0xFFE0E0E0),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildAnimatedSelectButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + AppSpacing.bottomSafeArea,
        ),
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF264b47),
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectPark(),
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
            child: Center(
              child: Text(
                'Выбрать этот парк',
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

  void _openWithdrawalConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Условия вывода средств'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Вывод средств через приложение MOZEN.'),
              SizedBox(height: 16),
              Text('Для этого необходимо:'),
              SizedBox(height: 8),
              Text('1. Заранее уточните в таксопарке график и форму проведения выплат.'),
              SizedBox(height: 8),
              Text('2. Если вывод затянулся, не переживайте, а подождите еще. Деньги должны прийти, поэтому наберитесь терпения. Возможно, вы попали на выходной или праздничный день.'),
              SizedBox(height: 8),
              Text('3. Если заявку долго не обрабатывают, не создавайте еще одну. Обратитесь в техподдержку для уточнения статуса вашей транзакции.'),
              SizedBox(height: 8),
              Text('4. Источник: https://yanbase.ru/vyvod-deneg.html'),
              SizedBox(height: 16),
              Text('Средства автоматически переводятся на карту самозанятого водителя со второго дня работы в агрегаторе. Каждая транзакция проходит проверку ответственными сотрудниками банка. Если она успешна, клиент получает соответствующее уведомление, а через некоторое время после этого деньги зачисляются на карту.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _sendEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _selectPark() async {
    // Сохраняем выбранный таксопарк
    await UserDataService.instance.saveParkData(widget.park);
    
    print('Park data saved: ${widget.park['name']}');
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => DataConfirmationScreen(selectedPark: widget.park),
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
