import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import '../../services/api_service.dart';
import '../../services/firebase_messaging_service.dart';
import '../main/main_app_screen.dart';

class DataConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> selectedPark;

  const DataConfirmationScreen({super.key, required this.selectedPark});

  @override
  State<DataConfirmationScreen> createState() => _DataConfirmationScreenState();
}

class _DataConfirmationScreenState extends State<DataConfirmationScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic> userData = {};

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _startAnimations();
    _loadUserData();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  void _loadUserData() async {
    await UserDataService.instance.loadFromStorage();
    setState(() {
      userData = UserDataService.instance.userData;
    });
    print('Loaded user data: $userData');
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
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildAnimatedProgressSteps(),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: SingleChildScrollView(child: _buildAnimatedContent()),
            ),
            _buildAnimatedConfirmButton(context),
            const SizedBox(height: AppSpacing.lg),
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
        'Подтверждение данных',
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
            _buildAnimatedStep(1, 'Про вас', isCompleted: true),
            _buildAnimatedStep(2, 'Про авто', isCompleted: true),
            _buildAnimatedStep(3, 'Условия', isCompleted: true),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedStep(
    int number,
    String title, {
    required bool isCompleted,
  }) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.textPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          ),
          child: const Center(
            child: Icon(Icons.check, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
            Text(
              'Давайте сверимся. Если все в порядке, нажмите Все верно.',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 15,
                height: 22 / 15,
                letterSpacing: -0.43,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildUserDataSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildCarDataSection(),
            const SizedBox(height: AppSpacing.xl),
            _buildConditionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Про вас',
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
        _buildDataField('Город', userData['city']),
        _buildDataField('ФИО', userData['fullName']),
        _buildDataField('Страна выдачи в/с', userData['country']),
        _buildDataField('Серия и номер в/с', userData['licenseNumber']),
        _buildDataField('Дата выдачи в/с', userData['issueDate']),
        _buildDataField(
          'Дата окончания срока действия в/с',
          userData['expiryDate'],
        ),
        _buildDataField('Код приглашения', userData['invitationCode']),
      ],
    );
  }

  Widget _buildCarDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Про авто',
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
        _buildDataField('Марка', userData['carBrand']),
        _buildDataField('Модель', userData['carModel']),
        _buildDataField('Цвет', userData['carColor']),
        _buildDataField('Год', userData['carYear']),
        _buildDataField('Госномер', userData['licensePlate']),
      ],
    );
  }

  Widget _buildConditionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Условия',
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
        _buildConditionItem(1, 'Парк берет процент с каждой поездки'),
        const SizedBox(height: AppSpacing.md),
        _buildConditionItem(2, 'Парк выплачивает деньги за заказы'),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Автопарк',
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
        Row(
          children: [
            Expanded(
              child: Text(
                widget.selectedPark['name'],
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
      ],
    );
  }

  Widget _buildDataField(String label, String value) {
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
        Row(
          children: [
            Expanded(
              child: Text(
                value,
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
        const SizedBox(height: AppSpacing.lg),
        Container(height: 1, color: const Color(0xFFE0E0E0)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _buildConditionItem(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 22 / 15,
              letterSpacing: -0.43,
              color: AppColors.textPrimary,
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
                'Все верно',
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

  void _confirmData(BuildContext context) async {
    final Map<String, dynamic> allData = UserDataService.instance.getCompleteUserData();

    print('All data collected: $allData');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Регистрация...',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final response = await ApiService.instance.registerDriver(allData);

      if (mounted) Navigator.of(context).pop();

      if (response['success']) {
        final driverId = response['driver_id'];
        final phoneNumber = allData['user']['phoneNumber'];
        
        final driverData = {
          'id': driverId,
          'phoneNumber': phoneNumber,
          'fullName': allData['user']['fullName'],
          'carModel': '${allData['car']['brand']} ${allData['car']['model']}',
          'carNumber': allData['car']['licensePlate'],
          'carBrand': allData['car']['brand'],
          'carColor': allData['car']['color'],
          'carYear': allData['car']['year'],
          'carVin': allData['car']['vin'],
          'carBodyNumber': allData['car']['bodyNumber'],
          'carSts': allData['car']['sts'],
          'taxiparkId': allData['park']['id'],
          'taxiparkName': allData['park']['name'],
          'balance': 0.0,
          'status': 'active',
          'blocked': false,
        };

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('driver_data', jsonEncode(driverData));
        
        await FirebaseMessagingService().refreshToken();
        
        print('✅ Регистрация успешна, данные сохранены');
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainAppScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Ошибка регистрации'),
              content: Text(response['error'] ?? 'Неизвестная ошибка'),
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
    } catch (e) {
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text('Ошибка регистрации: $e'),
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
  }
}
