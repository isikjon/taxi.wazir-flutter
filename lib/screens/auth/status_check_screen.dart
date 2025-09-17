import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../main/main_app_screen.dart';
import 'phone_auth_screen.dart';

class StatusCheckScreen extends StatefulWidget {
  final String phoneNumber;

  const StatusCheckScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<StatusCheckScreen> createState() => _StatusCheckScreenState();
}

class _StatusCheckScreenState extends State<StatusCheckScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _driverData;

  @override
  void initState() {
    super.initState();
    _checkDriverStatus();
  }

  Future<void> _checkDriverStatus() async {
    try {
      final response = await ApiService.instance.checkSmsStatus(widget.phoneNumber);
      
      if (response['success'] && mounted) {
        final data = response['data'];
        
        if (data['exists']) {
          final driver = data['driver'];
          final status = driver['status'];
          
          if (status == 'inactive' || driver['blocked'] == true) {
            setState(() {
              _isLoading = false;
              _errorMessage = driver['blockMessage'] ?? 'Ваш аккаунт заблокирован суперадмином. Для связи: +996 559 868 878';
            });
          } else {
            setState(() {
              _isLoading = false;
              _driverData = driver;
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = data['message'] ?? 'Ваш аккаунт удален суперадмином. Для связи: +996 559 868 878';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Ошибка проверки статуса';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Ошибка сети: $e';
      });
    }
  }

  void _showBlockedDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.block,
                color: AppColors.error,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Доступ ограничен',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+996 559 868 878',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const PhoneAuthScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(
                'Понятно',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBlockedDialog(_errorMessage!);
      });
      
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Проверка статуса...'),
        ),
      );
    }

    if (_driverData != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const MainAppScreen(),
          ),
          (route) => false,
        );
      });
      
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: Text('Загрузка...'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Text('Неизвестная ошибка'),
      ),
    );
  }
}
