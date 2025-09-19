import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/balance_service.dart';
import '../../services/driver_service.dart';
import '../../models/balance_models.dart';
import '../auth/phone_auth_screen.dart';
import '../balance/balance_screen.dart';
import '../profile/personal_data_screen.dart';
import '../profile/tariffs_screen.dart';
import '../settings/options_screen.dart';
import '../support/support_main_screen.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../photocontrol/photocontrol_screen.dart';
import '../streethail/street_hail_screen.dart';
import '../tips/useful_tips_screen.dart';
import '../navigation/navigation_screen.dart';
import '../navigation/order_notification_screen.dart';
import '../../services/diagnostics_service.dart';
import '../../services/websocket_service.dart';
import '../../services/order_service.dart';
import '../../models/order_model.dart';

class MainAppScreen extends StatefulWidget {
  const MainAppScreen({super.key});

  @override
  State<MainAppScreen> createState() => _MainAppScreenState();
}


class _MainAppScreenState extends State<MainAppScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Предотвращаем возврат на страницу авторизации
        return false;
      },
      child: Scaffold(
        body: const HomeScreen(),
      ),
    );
  }

}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  final WebSocketService _webSocketService = WebSocketService();
  final OrderService _orderService = OrderService();
  int? _currentDriverId;
  int? _currentTaxiparkId;
  Map<String, dynamic>? _driverData;
  BalanceData? _balanceData;
  Map<String, dynamic>? _taxiparkData;
  String _selectedPaymentMethod = 'наличными';
  String _currentTariff = 'Эконом';
  bool _isLoading = true;
  int _diagnosticsIssuesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
    _initializeWebSocket();
  }

  Future<void> _initializeWebSocket() async {
    try {
      final driverData = await AuthService.getCurrentDriver();
      if (driverData != null) {
        _currentDriverId = driverData['id'];
        _currentTaxiparkId = driverData['taxiparkId'];
        
        if (_currentDriverId != null && _currentTaxiparkId != null) {
          await _webSocketService.connect(_currentDriverId.toString(), _currentTaxiparkId!);
          _webSocketService.orderStream.listen(_handleNewOrder);
        }
      }
    } catch (e) {
      print('WebSocket initialization error: $e');
    }
  }

  void _handleNewOrder(OrderModel order) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OrderNotificationScreen(
        order: order,
        onAccept: () {
          Navigator.of(context).pop();
          _acceptOrder(order);
        },
        onDecline: () {
          Navigator.of(context).pop();
          _declineOrder(order);
        },
      ),
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      await _orderService.acceptOrder(order.id, _currentDriverId!);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NavigationScreen(
              order: order,
              driverId: _currentDriverId!,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка принятия заказа: $e')),
        );
      }
    }
  }

  Future<void> _declineOrder(OrderModel order) async {
    try {
      await _orderService.cancelOrder(order.id, _currentDriverId!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка отклонения заказа: $e')),
        );
      }
    }
  }

  Future<void> _loadDriverData() async {
    try {
      // Показываем полную информацию о API
      await ApiService.printApiInfo();
      
      final driverData = await AuthService.getCurrentDriver();
      if (mounted) {
        setState(() {
          _driverData = driverData;
        });
      }
      
      // Загружаем данные таксопарка и тариф
      if (driverData != null && driverData['phoneNumber'] != null) {
        final taxiparkData = await DriverService().getDriverTaxipark(driverData['phoneNumber']);
        final driverProfile = await DriverService().getDriverProfile(driverData['phoneNumber']);
        
        if (mounted) {
          setState(() {
            _taxiparkData = taxiparkData;
            _currentTariff = driverProfile?['tariff'] ?? 'Эконом';
          });
        }
      }
      
      // Загружаем баланс водителя
      await _loadBalance();
      
      // Загружаем данные диагностики
      await _loadDiagnosticsData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки данных: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadBalance() async {
    try {
      final result = await BalanceService.instance.getDriverBalance();
      if (result['success'] && mounted) {
        setState(() {
          _balanceData = BalanceData.fromJson(result['data']);
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки баланса: $e');
    }
  }

  Future<void> _loadDiagnosticsData() async {
    try {
      final diagnosticsData = await DiagnosticsService.instance.getDiagnosticsStatus(
        currentTariff: _currentTariff,
        currentBalance: _balanceData?.currentBalance,
      );
      if (mounted) {
        setState(() {
          _diagnosticsIssuesCount = DiagnosticsService.instance.getUnresolvedIssuesCount(diagnosticsData);
        });
      }
    } catch (e) {
      print('❌ Ошибка загрузки диагностики: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadDriverData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                _buildProfileSection(),
                _buildCalendarSection(),
                _buildEarningsSection(),
                _buildOnlineButton(),
                _buildMenuSections(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8F8F8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final driverName = _driverData?['fullName'] ?? 'Маасалиев Талантбек';
    final carModel = _driverData?['carModel'] ?? 'BMW M5';
    final carNumber = _driverData?['carNumber'] ?? '01 29 9 20001';
    final taxiparkName = _driverData?['taxiparkName'] ?? 'Томар Такси';
    
    print('Driver data in UI: $_driverData');
    print('Driver name: $driverName');
    print('Car: $carModel, $carNumber');
    print('Taxipark: $taxiparkName');

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Профиль
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppColors.primaryWithOpacity10,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF264b47),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: const Color(0xFF264b47),
                  size: 35,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                driverName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$carModel, $carNumber',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryWithOpacity60,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                taxiparkName,
                style: const TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF264b47),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Рейтинг
          Column(
            children: [
              const Text(
                '5.0',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Рейтинг',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final weekStart = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));

    return Container(
      margin: const EdgeInsets.only(top: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.primaryWithOpacity30, width: 1),
          bottom: BorderSide(color: AppColors.primaryWithOpacity30, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Навигация по неделям
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryWithOpacity30, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_left, size: 24, color: Color(0xFF666666)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const Text(
                  'Сегодня',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 7));
                    });
                  },
                  icon: const Icon(Icons.chevron_right, size: 24, color: Color(0xFF666666)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Дни недели
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.primaryWithOpacity30, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: weekDays.map((day) {
                final isSelected = day.day == DateTime.now().day && 
                                  day.month == DateTime.now().month && 
                                  day.year == DateTime.now().year;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                    });
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF264b47) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Заработок за день
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  '${_balanceData?.currentBalance.toStringAsFixed(0) ?? '0'} сом',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_balanceData?.totalOrders ?? 0} заказов',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryWithOpacity60,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _balanceData?.totalOrders == 0 
                    ? 'За этот период поездок не было'
                    : 'Всего заказов выполнено',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryWithOpacity60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsSection() {
    final weeklyEarnings = _balanceData?.weeklyEarnings ?? 0.0;
    
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        children: [
          _buildEarningsRow('По безналу', '${(weeklyEarnings * 0.6).toStringAsFixed(0)} сом'),
          _buildEarningsRow('Наличными', '${(weeklyEarnings * 0.4).toStringAsFixed(0)} сом'),
          _buildEarningsRow('Сервис (вычеты)', '${(weeklyEarnings * 0.05).toStringAsFixed(0)} сом (5%)'),
          _buildEarningsRow('Парк (вычеты)', '${(weeklyEarnings * (_taxiparkData?['commission'] ?? 0.1) / 100).toStringAsFixed(0)} сом (${(_taxiparkData?['commission'] ?? 10).toStringAsFixed(0)}%)'),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 0.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      child: Column(
        children: [
          _buildMenuRow('Баланс', null, onTap: () async {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const BalanceScreen(),
              ),
            );
            // Обновляем баланс после возврата со страницы баланса
            if (result == true) {
              await _loadBalance();
            }
          }),
          _buildMenuRow('Оплата', _selectedPaymentMethod, onTap: _showPaymentMethodBottomSheet),
          _buildMenuRow('Личные данные о вас', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PersonalDataScreen(),
              ),
            );
          }),
          Container(
            height: 8,
            color: AppColors.primaryWithOpacity05,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Тарифы и опции',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          _buildMenuRow('Тарифы', '${_currentTariff == 'Эконом' ? 1 : 0} из 6', onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TariffsScreen(),
              ),
            );
          }),
          _buildMenuRow('Опции для тарифов', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const OptionsScreen(),
              ),
            );
          }),
          _buildMenuRow('Поддержка', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const SupportMainScreen(),
              ),
            );
          }),
          _buildMenuRow('Диагностика', _diagnosticsIssuesCount > 0 ? '$_diagnosticsIssuesCount' : null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DiagnosticsScreen(
                  currentTariff: _currentTariff,
                  currentBalance: _balanceData?.currentBalance,
                ),
              ),
            ).then((_) {
              // Обновляем данные после возврата с экрана диагностики
              _loadDiagnosticsData();
            });
          }),
          _buildMenuRow('Фотоконтроль', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PhotocontrolScreen(),
              ),
            );
          }),
          _buildMenuRow('От борта', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const StreetHailScreen(),
              ),
            );
          }),
          _buildMenuRow('Полезные советы', null, onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const UsefulTipsScreen(),
              ),
            );
          }),
        _buildMenuRow('Выполнить тестовый заказ', null, onTap: () {
            final testOrder = OrderModel(
              id: 999,
              orderNumber: 'TEST-001',
              clientName: 'Тестовый клиент',
              clientPhone: '+7900000000',
              pickupAddress: 'Тестовый адрес А',
              pickupLatitude: 55.751244,
              pickupLongitude: 37.617494,
              destinationAddress: 'Тестовый адрес Б',
              destinationLatitude: 55.761244,
              destinationLongitude: 37.627494,
              price: 500.0,
              status: 'accepted',
              taxiparkId: _currentTaxiparkId ?? 1,
              driverId: _currentDriverId,
              createdAt: DateTime.now(),
              notes: 'Тестовый заказ для проверки навигации',
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  order: testOrder,
                  driverId: _currentDriverId ?? 1,
                ),
              ),
            );
        }),
          _buildMenuRow('Выход из Wazir', null, onTap: _handleLogout),
        ],
      ),
    );
  }

  Widget _buildMenuRow(String title, String? subtitle, {VoidCallback? onTap}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryWithOpacity20,
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
          children: [
            // Серая иконка слева
            Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: AppColors.primaryWithOpacity20,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.circle,
                color: const Color(0xFF264b47),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const Spacer(),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: title == 'Диагностика' ? Colors.red : const Color(0xFF666666),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF999999),
              size: 20,
            ),
          ],
          ),
        ),
      ),
    );
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Выполняем выход
        await AuthService.logout();
        
        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();
        
        // Перенаправляем на экран авторизации
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const PhoneAuthScreen(),
            ),
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


  void _showPaymentMethodBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPaymentMethodBottomSheet(),
    );
  }

  Widget _buildPaymentMethodBottomSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildPaymentOption('Оплата наличными', 'cash', true),
          _buildPaymentOption('Безналичная оплата', 'card', false),
          _buildPaymentOption('Наличными или картой', 'both', false),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, String value, bool isSelected) {
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
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        trailing: isSelected
            ? const Icon(
                Icons.check,
                color: Colors.black,
                size: 24,
              )
            : null,
        onTap: () {
          if (value == 'cash') {
            setState(() {
              _selectedPaymentMethod = 'наличными';
            });
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop();
            _showComingSoonAlert();
          }
        },
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

  Widget _buildOnlineButton() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 1),
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: () {
            final testOrder = OrderModel(
              id: 998,
              orderNumber: 'TEST-002',
              clientName: 'Тестовый клиент 2',
              clientPhone: '+7900000001',
              pickupAddress: 'Тестовый адрес А',
              pickupLatitude: 55.751244,
              pickupLongitude: 37.617494,
              destinationAddress: 'Тестовый адрес Б',
              destinationLatitude: 55.761244,
              destinationLongitude: 37.627494,
              price: 600.0,
              status: 'accepted',
              taxiparkId: _currentTaxiparkId ?? 1,
              driverId: _currentDriverId,
              createdAt: DateTime.now(),
              notes: 'Тестовый заказ 2',
            );
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => NavigationScreen(
                  order: testOrder,
                  driverId: _currentDriverId ?? 1,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF264b47),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'На линию',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

}

