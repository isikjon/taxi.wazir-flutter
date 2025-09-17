import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';
import '../../services/api_service.dart';
import 'park_details_screen.dart';

class ParkSelectionScreen extends StatefulWidget {
  const ParkSelectionScreen({super.key});

  @override
  State<ParkSelectionScreen> createState() => _ParkSelectionScreenState();
}

class _ParkSelectionScreenState extends State<ParkSelectionScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  List<Map<String, dynamic>> parks = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _startAnimations();
    _loadParks();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  Future<void> _loadParks() async {
    try {
      final response = await ApiService.instance.getTaxiparks();
      
      print('🔍 Park selection response: $response');
      
      if (response['success']) {
        setState(() {
          // API возвращает массив напрямую, а не объект с полем 'parks'
          final data = response['data'];
          print('🔍 Park data type: ${data.runtimeType}');
          print('🔍 Park data content: $data');
          
          if (data is List) {
            parks = List<Map<String, dynamic>>.from(data);
            print('✅ Loaded ${parks.length} parks from API');
          } else if (data is Map && data.containsKey('parks')) {
            parks = List<Map<String, dynamic>>.from(data['parks']);
            print('✅ Loaded ${parks.length} parks from nested structure');
          } else {
            parks = [];
            print('⚠️ No parks found in response');
          }
          isLoading = false;
        });
      } else {
        // Fallback данные при ошибке API
        setState(() {
          parks = [
            {
              'id': 1,
              'name': 'ООО Платинум Партнер',
              'city': 'Ош',
              'phone': '+970667788778',
              'email': 'example@gmail.com',
              'address': 'Кыргызстан г. Ок мкр Анар 1, (орентир Автомойка Нурзаман, кафе Нирвана)',
              'working_hours': 'Пн-Сб 10:00-18:00\nВс-выходной',
              'commission_percent': 15,
              'description': 'Надежный партнер с многолетним опытом работы'
            },
            {
              'id': 2,
              'name': 'Premium park',
              'city': 'Ош',
              'phone': '+996555123456',
              'email': 'premium@park.kg',
              'address': 'Кыргызстан г. Ош ул. Ленина 123',
              'working_hours': 'Пн-Пт 09:00-19:00\nСб-Вс 10:00-16:00',
              'commission_percent': 12,
              'description': 'Премиум сервис для водителей'
            },
            {
              'id': 3,
              'name': 'Тумар Такси',
              'city': 'Ош',
              'phone': '+996777888999',
              'email': 'tumar@taxi.kg',
              'address': 'Кыргызстан г. Ош ул. Курманжан Датка 45',
              'working_hours': 'Пн-Вс 08:00-20:00',
              'commission_percent': 18,
              'description': 'Семейный бизнес с индивидуальным подходом'
            },
            {
              'id': 4,
              'name': 'Индекс-Б',
              'city': 'Ош',
              'phone': '+996312345678',
              'email': 'index@b.kg',
              'address': 'Кыргызстан г. Ош ул. Масалиева 78',
              'working_hours': 'Пн-Сб 09:00-18:00\nВс-выходной',
              'commission_percent': 20,
              'description': 'Современные технологии и быстрые выплаты'
            },
          ];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading parks: $e');
      // Fallback данные при ошибке
      setState(() {
        parks = [
          {
            'id': 1,
            'name': 'ООО Платинум Партнер',
            'city': 'Ош',
            'phone': '+970667788778',
            'email': 'example@gmail.com',
            'address': 'Кыргызстан г. Ок мкр Анар 1, (орентир Автомойка Нурзаман, кафе Нирвана)',
            'working_hours': 'Пн-Сб 10:00-18:00\nВс-выходной',
            'commission_percent': 15,
            'description': 'Надежный партнер с многолетним опытом работы'
          },
        ];
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildParksList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Выберите парк',
        style: const TextStyle(
          fontFamily: 'Montserrat',
          fontWeight: FontWeight.w600,
          fontSize: 23,
          height: 24 / 23,
          letterSpacing: 0,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildParksList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: parks.length,
          itemBuilder: (context, index) {
            final park = parks[index];
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openParkDetails(park),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            park['name'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openParkDetails(Map<String, dynamic> park) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ParkDetailsScreen(park: park),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
