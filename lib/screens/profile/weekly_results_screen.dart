import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../styles/app_colors.dart';
import '../../services/balance_service.dart';
import '../../services/driver_service.dart';
import '../../services/user_data_service.dart';

class WeeklyResultsScreen extends StatefulWidget {
  const WeeklyResultsScreen({super.key});

  @override
  State<WeeklyResultsScreen> createState() => _WeeklyResultsScreenState();
}

class _WeeklyResultsScreenState extends State<WeeklyResultsScreen> {
  bool _isLoading = true;
  int _weeklyOrders = 0;
  bool _hasResults = false;

  @override
  void initState() {
    super.initState();
    _loadWeeklyResults();
  }

  Future<void> _loadWeeklyResults() async {
    try {
      await UserDataService.instance.loadFromStorage();
      final userData = UserDataService.instance.userData;
      final phoneNumber = userData['phoneNumber'];
      
      if (phoneNumber != null) {
        final weeklyData = await DriverService().getWeeklyResults(phoneNumber);
        setState(() {
          _weeklyOrders = weeklyData?['weekly_orders'] ?? 0;
          _hasResults = _weeklyOrders >= 10;
          _isLoading = false;
        });
      } else {
        setState(() {
          _weeklyOrders = 0;
          _hasResults = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading weekly results: $e');
      setState(() {
        _weeklyOrders = 0;
        _hasResults = false;
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
          'Результаты недели',
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
      padding: const EdgeInsets.all(20),
      child: _hasResults
          ? _buildResultsContent()
          : _buildNoResultsContent(),
    );
  }

  Widget _buildNoResultsContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Выполните 10 заказов за неделю, и мы покажем вам отзывы пользователей и наши наблюдения.',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Заказов выполнено: $_weeklyOrders из 10',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Поздравляем! Вы выполнили цель недели',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildResultsSection('Отзывы пользователей', [
          'Отличный водитель, вежливый и пунктуальный',
          'Быстрая и комфортная поездка',
          'Рекомендую этого водителя',
        ]),
        const SizedBox(height: 20),
        _buildResultsSection('Наши наблюдения', [
          'Высокий рейтинг: 4.9/5',
          'Среднее время ожидания: 3 минуты',
          '100% выполнение заказов',
        ]),
      ],
    );
  }

  Widget _buildResultsSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryWithOpacity05,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primaryWithOpacity20,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}
