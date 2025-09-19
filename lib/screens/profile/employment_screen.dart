import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../services/user_data_service.dart';
import '../../services/driver_service.dart';

class EmploymentScreen extends StatefulWidget {
  const EmploymentScreen({super.key});

  @override
  State<EmploymentScreen> createState() => _EmploymentScreenState();
}

class _EmploymentScreenState extends State<EmploymentScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _taxiparkData;
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
        final taxiparkData = await DriverService().getDriverTaxipark(phoneNumber);
        setState(() {
          _userData = userData;
          _taxiparkData = taxiparkData;
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
    String parkName = 'ООО Платинум Партнер';
    
    if (_taxiparkData != null) {
      parkName = _taxiparkData!['name'] ?? 'ООО Платинум Партнер';
    } else if (_userData != null) {
      parkName = _userData!['selectedPark']?['name'] ?? 'ООО Платинум Партнер';
    }

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
          parkName,
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
            'Условия вывода средств',
            () => _showComingSoonAlert(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Контакты',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          _buildContactItem('Телефон', _taxiparkData?['phone'] ?? '+970667788778'),
          _buildContactItem('График работы', _taxiparkData?['work_schedule'] ?? 'Пн-Сб 10:00-18:00\nВс-выходной'),
          _buildContactItem('Почта', _taxiparkData?['email'] ?? 'Example@gmail.com'),
          _buildContactItem(
            'Адрес',
            _taxiparkData?['address'] ?? 'Кыргыстан г. Ок мкр Анар 1, (орентир Автомойка Нурзаман, кафе Нирвана)',
          ),
          const Spacer(),
          _buildSelectedButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, VoidCallback onTap) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildContactItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF999999),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Парк выбран',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showComingSoonAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('В разработке'),
        content: const Text('Эта функция пока недоступна и находится в разработке.'),
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
