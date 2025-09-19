import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../services/user_data_service.dart';
import '../../services/driver_service.dart';

class TariffsScreen extends StatefulWidget {
  const TariffsScreen({super.key});

  @override
  State<TariffsScreen> createState() => _TariffsScreenState();
}

class _TariffsScreenState extends State<TariffsScreen> {
  String _currentTariff = 'Эконом'; // Текущий тариф водителя
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    
  }

  Future<void> _loadDriverData() async {
    try {
      await UserDataService.instance.loadFromStorage();
      final userData = UserDataService.instance.userData;
      final phoneNumber = userData['phoneNumber'];
      
      if (phoneNumber != null) {
        final driverProfile = await DriverService().getDriverProfile(phoneNumber);
        if (driverProfile != null && driverProfile['tariff'] != null) {
          setState(() {
            _currentTariff = driverProfile['tariff'] ?? 'Эконом';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading driver data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
          'Тарифы и опции',
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
          : Container(
              color: Colors.white,
              child: Column(
                children: [
            _buildTariffItem(
              'Эконом',
              _currentTariff == 'Эконом' ? 'активно' : 'не доступно',
              _currentTariff == 'Эконом' 
                  ? 'Ваш текущий тариф' 
                  : 'Пройдите фотоконтроль машины',
              _currentTariff == 'Эконом',
              _currentTariff == 'Эконом',
            ),
            _buildTariffItem(
              'Комфорт',
              'не доступно',
              'Тариф недоступен в этой геозоне',
              false,
              false,
            ),
            _buildTariffItem(
              'Комфорт +',
              'не доступно',
              'Тариф недоступен в этой геозоне',
              false,
              false,
            ),
            _buildTariffItem(
              'Business',
              'не доступно',
              'Тариф недоступен в этой геозоне',
              false,
              false,
            ),
            _buildTariffItem(
              'Доставка',
              'не доступно',
              'Тариф недоступен в этой геозоне',
              false,
              false,
            ),
            _buildTariffItem(
              'Курьер',
              'не доступно',
              'Тариф недоступен в этой геозоне',
              false,
              false,
            ),
                ],
              ),
            ),
    );
  }

  Widget _buildTariffItem(
    String title,
    String status,
    String subtitle,
    bool isActive,
    bool isEnabled,
  ) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity30,
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF264b47) : AppColors.primaryWithOpacity30,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            _buildIOSSwitch(
              value: isActive,
              onChanged: isEnabled ? (value) {
                // Только активный тариф можно переключать
                if (isActive) {
                  setState(() {
                    _currentTariff = value ? title : '';
                  });
                }
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return GestureDetector(
      onTap: onChanged != null ? () => onChanged(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 51,
        height: 31,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.5),
          color: value 
              ? (onChanged != null ? const Color(0xFF34C759) : const Color(0xFF9E9E9E))
              : const Color(0xFFE5E5E7),
          border: Border.all(
            color: value 
                ? (onChanged != null ? const Color(0xFF34C759) : const Color(0xFF9E9E9E))
                : const Color(0xFFE5E5E7),
            width: 0.5,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
