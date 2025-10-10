import 'package:eco_taxi/screens/auth/phone_auth_screen.dart';
import 'package:eco_taxi/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/user_data_service.dart';
import '../../services/driver_service.dart';
import 'car_details_screen.dart';
import 'employment_screen.dart';
import 'weekly_results_screen.dart';

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _driverProfile;
  bool _isLoading = true;
  bool _isLoadingDeleteAccount = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      await UserDataService.instance.loadFromStorage();
      final userData = UserDataService.instance.userData;
      final phoneNumber = userData['phoneNumber'];

      if (phoneNumber != null) {
        final driverProfile = await DriverService().getDriverProfile(
          phoneNumber,
        );
        setState(() {
          _userData = userData;
          _driverProfile = driverProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _userData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await DriverService().deleteAccount();
      setState(() {
        _isLoadingDeleteAccount = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingDeleteAccount = false;
      });
    }
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(),
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
              'О вас',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadUserData,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          _buildMenuItem(
            'Ваша машина',
            _getCarInfo(),
            Icons.directions_car,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CarDetailsScreen()),
            ),
          ),
          _buildMenuItem(
            'Занятость',
            _getEmploymentInfo(),
            Icons.business,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const EmploymentScreen()),
            ),
          ),
          _buildMenuItem(
            'Результаты недели',
            null,
            Icons.analytics,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const WeeklyResultsScreen(),
              ),
            ),
          ),
          _buildMenuItem(
            'Выйти из аккаунта',
            null,
            Icons.logout,
            _handleLogout,
          ),

          _buildMenuItem('Удалить аккаунт', null, Icons.logout, _deleteAccountShow),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    String? subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      height: 72, // Фиксированная высота для всех блоков
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity30, // Измененный цвет границы
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 25,
          height: 25,
          decoration: const BoxDecoration(
            color: AppColors.primaryWithOpacity20,
            // Зеленый цвет как в требованиях
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: title == 'Выйти из аккаунта' || title == 'Удалить аккаунт'
            ? null
            : const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.textSecondary,
                size: 16,
              ),
        onTap: onTap,
      ),
    );
  }

  String _getCarInfo() {
    if (_driverProfile != null) {
      final carModel = _driverProfile!['car_model'] ?? '';
      final carNumber = _driverProfile!['car_number'] ?? '';

      if (carModel.isNotEmpty && carNumber.isNotEmpty) {
        return '$carModel, $carNumber';
      } else if (carModel.isNotEmpty) {
        return carModel;
      } else if (carNumber.isNotEmpty) {
        return carNumber;
      }
    }

    if (_userData != null) {
      final carBrand = _userData!['carBrand'] ?? '';
      final carModel = _userData!['carModel'] ?? '';
      final licensePlate = _userData!['licensePlate'] ?? '';

      if (carBrand.isNotEmpty && carModel.isNotEmpty) {
        return '$carBrand $carModel';
      } else if (licensePlate.isNotEmpty) {
        return licensePlate;
      }
    }

    return 'Не указано';
  }

  String _getEmploymentInfo() {
    if (_driverProfile != null && _driverProfile!['taxipark'] != null) {
      final taxiparkName = _driverProfile!['taxipark']['name'] ?? '';
      if (taxiparkName.isNotEmpty) {
        return taxiparkName.length > 15
            ? '${taxiparkName.substring(0, 15)}...'
            : taxiparkName;
      }
    }

    if (_userData != null) {
      final park = _userData!['selectedPark'];
      if (park != null && park['name'] != null) {
        final name = park['name'] as String;
        return name.length > 15 ? '${name.substring(0, 15)}...' : name;
      }
    }

    return 'Не указано';
  }

  Future<void> _handleLogout() async {
    // Показываем диалог подтверждения
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Выполняем выход
        await AuthService.logout();

        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Перенаправляем на экран авторизации
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при выходе: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccountShow() async {
    // Показываем диалог подтверждения
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление аккаунта'),
        content: const Text(
          'При удалении аккаунта произойдут следующие действия:\n\n'
          '• Удалятся все записи фотоконтроля и связанные фотографии.\n'
          '• Будут удалены все транзакции (баланс, пополнения, списания).\n'
          '• Все заказы останутся, но водитель будет отвязан от них.\n'
          '• Аккаунт водителя будет полностью удалён.\n'
          '• В таксопарке обновится счётчик водителей.\n\n'
          'Вы уверены, что хотите продолжить?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Удалить аккаунт',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Выполняем выход

        await _deleteAccount();
        await AuthService.logout();

        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Перенаправляем на экран авторизации
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при удалении: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // void _handleLogout() async {
  //   try {
  //     await UserDataService.instance.clearUserData();
  //     Navigator.of(context).pushNamedAndRemoveUntil(
  //       '/phone_auth',
  //       (route) => false,
  //     );
  //   } catch (e) {
  //     print('Error during logout: $e');
  //   }
  // }
}
