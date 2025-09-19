import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
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
        final driverProfile = await DriverService().getDriverProfile(phoneNumber);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'О вас',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
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
              MaterialPageRoute(
                builder: (context) => const CarDetailsScreen(),
              ),
            ),
          ),
          _buildMenuItem(
            'Занятость',
            _getEmploymentInfo(),
            Icons.business,
            () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const EmploymentScreen(),
              ),
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
            _showLogoutDialog,
          ),
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
            color: AppColors.primaryWithOpacity20, // Зеленый цвет как в требованиях
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
        trailing: title == 'Выйти из аккаунта'
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
        return taxiparkName.length > 15 ? '${taxiparkName.substring(0, 15)}...' : taxiparkName;
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

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Text(
          'Вы уверены что хотите выйти из аккаунта?',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Нет',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _handleLogout();
                  },
                  child: Text(
                    'Да',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleLogout() async {
    try {
      await UserDataService.instance.clearUserData();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/phone_auth',
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
