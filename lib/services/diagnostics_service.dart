
import 'photo_verification_service.dart';

class DiagnosticsService {
  static DiagnosticsService? _instance;
  static DiagnosticsService get instance => _instance ??= DiagnosticsService._();
  DiagnosticsService._();
  
  final PhotoVerificationService _verificationService = PhotoVerificationService();

  Future<DiagnosticsData> getDiagnosticsStatus({
    String? currentTariff,
    double? currentBalance,
  }) async {
    try {
      final hasActiveTariff = await _checkActiveTariff(currentTariff);
      final hasStsPhotoControl = await _checkStsPhotoControl();
      final hasVuPhotoControl = await _checkVuPhotoControl();
      final hasEnoughBalance = await _checkBalance(currentBalance);

      return DiagnosticsData(
        hasActiveTariff: hasActiveTariff,
        hasStsPhotoControl: hasStsPhotoControl,
        hasVuPhotoControl: hasVuPhotoControl,
        hasEnoughBalance: hasEnoughBalance,
      );
    } catch (e) {
      print('Ошибка получения статуса диагностики: $e');
      return DiagnosticsData(
        hasActiveTariff: false,
        hasStsPhotoControl: false,
        hasVuPhotoControl: false,
        hasEnoughBalance: false,
      );
    }
  }

  Future<bool> _checkActiveTariff(String? currentTariff) async {
    // Проверяем, включен ли хотя бы один тариф
    if (currentTariff == null || currentTariff.isEmpty) {
      return false;
    }
    
    // Список активных тарифов
    const activeTariffs = ['Эконом', 'Комфорт', 'Бизнес', 'Минивэн', 'Грузовой', 'Доставка', 'Курьер'];
    return activeTariffs.contains(currentTariff);
  }

  Future<bool> _checkStsPhotoControl() async {
    final statusData = await _verificationService.getVerificationStatus();
    final status = statusData['status'] ?? 'not_started';
    return status == 'approved';
  }

  Future<bool> _checkVuPhotoControl() async {
    final statusData = await _verificationService.getVerificationStatus();
    final status = statusData['status'] ?? 'not_started';
    return status == 'approved';
  }

  Future<bool> _checkBalance(double? currentBalance) async {
    // Проверяем, достаточно ли баланса (больше 50 сомов)
    if (currentBalance == null) {
      return false;
    }
    return currentBalance >= 50.0;
  }

  int getUnresolvedIssuesCount(DiagnosticsData data) {
    int count = 0;
    if (!data.hasActiveTariff) count++;
    if (!data.hasStsPhotoControl) count++;
    if (!data.hasVuPhotoControl) count++;
    if (!data.hasEnoughBalance) count++;
    return count;
  }
}

class DiagnosticsData {
  final bool hasActiveTariff;
  final bool hasStsPhotoControl;
  final bool hasVuPhotoControl;
  final bool hasEnoughBalance;

  DiagnosticsData({
    required this.hasActiveTariff,
    required this.hasStsPhotoControl,
    required this.hasVuPhotoControl,
    required this.hasEnoughBalance,
  });

  bool get hasAllRequirements => 
      hasActiveTariff && hasStsPhotoControl && hasVuPhotoControl && hasEnoughBalance;
}
