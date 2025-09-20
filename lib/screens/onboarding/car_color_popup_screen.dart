import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';

class CarColorPopupScreen extends StatefulWidget {
  const CarColorPopupScreen({super.key});

  @override
  State<CarColorPopupScreen> createState() => _CarColorPopupScreenState();
}

class _CarColorPopupScreenState extends State<CarColorPopupScreen>
    with TickerProviderStateMixin {
  String? selectedColor;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredColors = [];
  List<String> allColors = [];

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
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
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

    _buttonAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
    _loadCarColors();
    _searchController.addListener(_filterColors);
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  void _loadCarColors() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/cars.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final List<dynamic> colors = jsonData['colors'];
      
      setState(() {
        allColors = colors.map((color) => color.toString()).toList()..sort();
        filteredColors = allColors;
      });
    } catch (e) {
      print('Error loading car colors: $e');
      // Fallback data
      setState(() {
        allColors = [
          'Белый', 'Черный', 'Серый', 'Серебристый', 'Красный', 'Синий', 'Зеленый', 'Желтый', 'Оранжевый', 'Фиолетовый', 'Коричневый', 'Бежевый', 'Золотой', 'Медный', 'Бронзовый', 'Темно-синий', 'Темно-зеленый', 'Темно-красный', 'Темно-серый', 'Светло-серый', 'Голубой', 'Розовый', 'Бирюзовый', 'Мятный', 'Лавандовый', 'Коралловый', 'Персиковый', 'Кремовый', 'Шоколадный', 'Вишневый'
        ];
        filteredColors = allColors;
      });
    }
  }

  void _filterColors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredColors = allColors;
      } else {
        filteredColors = allColors
            .where((color) => color.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildAnimatedSearchBar(),
          Expanded(
            child: _buildAnimatedColorsList(),
          ),
          _buildAnimatedConfirmButton(),
        ],
      ),
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
        'Выберите цвет',
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

  Widget _buildAnimatedSearchBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск цвета...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedColorsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: filteredColors.length,
          itemBuilder: (context, index) {
            final color = filteredColors[index];
            final isSelected = selectedColor == color;
            
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
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                    _buttonController.forward();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            color,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check,
                            color: AppColors.textPrimary,
                            size: 20,
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

  Widget _buildAnimatedConfirmButton() {
    return AnimatedBuilder(
      animation: _buttonAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.bottomSafeArea,
          ),
          child: AnimatedOpacity(
            opacity: selectedColor != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: selectedColor != null ? 64 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF264b47),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedColor != null ? _confirmSelection : null,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
                  child: Center(
                    child: Text(
                      'Подтвердить',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 17,
                        height: 22 / 17,
                        letterSpacing: -0.41,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmSelection() {
    if (selectedColor != null) {
      Navigator.of(context).pop(selectedColor);
    }
  }
}
