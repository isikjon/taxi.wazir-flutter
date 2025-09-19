import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';

class CarInfoScreen extends StatefulWidget {
  final Map<String, dynamic> carData;

  const CarInfoScreen({
    super.key,
    required this.carData,
  });

  @override
  State<CarInfoScreen> createState() => _CarInfoScreenState();
}

class _CarInfoScreenState extends State<CarInfoScreen> {
  bool _isPrimary = true;

  @override
  Widget build(BuildContext context) {
    // Поддерживаем как старые поля (из UserDataService), так и новые (из API)
    final carBrand = widget.carData['carBrand'] ?? '';
    final carModel = widget.carData['car_model'] ?? widget.carData['carModel'] ?? '';
    final licensePlate = widget.carData['car_number'] ?? widget.carData['licensePlate'] ?? '';
    final carName = carModel.isNotEmpty && licensePlate.isNotEmpty 
        ? '$carModel, $licensePlate' 
        : 'Автомобиль';

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
          carName,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            _buildInfoRow('Марка', widget.carData['carBrand'] ?? 'Не указано'),
            _buildInfoRow('Модель', widget.carData['car_model'] ?? widget.carData['carModel'] ?? 'Не указано'),
            _buildInfoRow('Цвет', widget.carData['car_color'] ?? widget.carData['carColor'] ?? 'Не указано'),
            _buildInfoRow('Год выпуска', widget.carData['car_year'] ?? widget.carData['carYear'] ?? 'Не указано'),
            _buildInfoRow('Гос.номер', widget.carData['car_number'] ?? widget.carData['licensePlate'] ?? 'Не указано'),
            _buildInfoRow('Свидетельство о регистрации ТС', widget.carData['car_sts'] ?? widget.carData['sts'] ?? 'Не указано'),
            _buildInfoRow('Идентификационный номер ТС (VIN)', widget.carData['car_vin'] ?? widget.carData['vin'] ?? '-'),
            const Spacer(),
            _buildPrimaryCarToggle(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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

  Widget _buildPrimaryCarToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Сделать основной машиной',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          Switch(
            value: _isPrimary,
            onChanged: (value) {
              setState(() {
                _isPrimary = value;
              });
            },
            activeColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.primaryWithOpacity20,
          ),
        ],
      ),
    );
  }
}
