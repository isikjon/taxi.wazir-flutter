import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../styles/app_colors.dart';

class NavigationScreen extends StatefulWidget {
  final OrderModel order;
  final int driverId;

  const NavigationScreen({
    super.key,
    required this.order,
    required this.driverId,
  });

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Навигация'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.surface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.map_outlined,
              size: 100,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'Навигация временно недоступна',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '2GIS SDK отключен из-за технических проблем',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Назад'),
            ),
          ],
        ),
      ),
    );
  }
}