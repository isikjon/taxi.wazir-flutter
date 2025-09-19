import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../services/user_data_service.dart';
import '../../services/driver_service.dart';
import 'car_info_screen.dart';

class CarDetailsScreen extends StatefulWidget {
  const CarDetailsScreen({super.key});

  @override
  State<CarDetailsScreen> createState() => _CarDetailsScreenState();
}

class _CarDetailsScreenState extends State<CarDetailsScreen> {
  Map<String, dynamic>? _userData;
  Map<String, dynamic>? _carData;
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
        final carData = await DriverService().getDriverCarInfo(phoneNumber);
        setState(() {
          _userData = userData;
          _carData = carData;
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
          'Автомобили',
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 20, bottom: 10),
            child: Text(
              'Основная машина',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primaryWithOpacity60,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          _buildCarItem(),
        ],
      ),
    );
  }

  Widget _buildCarItem() {
    String carName = 'Не указано';
    String licensePlate = '';
    
    if (_carData != null) {
      final carModel = _carData!['car_model'] ?? '';
      licensePlate = _carData!['car_number'] ?? '';
      carName = carModel.isNotEmpty ? carModel : 'Не указано';
    } else if (_userData != null) {
      final carBrand = _userData!['carBrand'] ?? '';
      final carModel = _userData!['carModel'] ?? '';
      licensePlate = _userData!['licensePlate'] ?? '';
      carName = carBrand.isNotEmpty && carModel.isNotEmpty 
          ? '$carBrand $carModel' 
          : 'Не указано';
    }
    
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
          carName,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        subtitle: licensePlate.isNotEmpty
            ? Text(
                licensePlate,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              )
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: AppColors.textSecondary,
          size: 16,
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CarInfoScreen(
              carData: _carData ?? _userData ?? {},
            ),
          ),
        ),
      ),
    );
  }
}
