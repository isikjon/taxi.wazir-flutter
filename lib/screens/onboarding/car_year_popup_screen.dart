import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';

class CarYearPopupScreen extends StatefulWidget {
  const CarYearPopupScreen({super.key});

  @override
  State<CarYearPopupScreen> createState() => _CarYearPopupScreenState();
}

class _CarYearPopupScreenState extends State<CarYearPopupScreen>
    with TickerProviderStateMixin {
  String? selectedYear;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredYears = [];
  List<String> allYears = [];

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
    _generateYears();
    _searchController.addListener(_filterYears);
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  void _generateYears() {
    final currentYear = DateTime.now().year;
    final years = <String>[];
    
    // Генерируем годы от текущего до 1990
    for (int year = currentYear; year >= 1990; year--) {
      years.add(year.toString());
    }
    
    setState(() {
      allYears = years;
      filteredYears = years;
    });
  }

  void _filterYears() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredYears = allYears;
      } else {
        filteredYears = allYears
            .where((year) => year.toLowerCase().contains(query))
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
            child: _buildAnimatedYearsList(),
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
        'Год выпуска',
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
              hintText: 'Поиск года...',
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

  Widget _buildAnimatedYearsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: filteredYears.length,
          itemBuilder: (context, index) {
            final year = filteredYears[index];
            final isSelected = selectedYear == year;
            
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
                      selectedYear = year;
                    });
                    _buttonController.forward();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            year,
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
            opacity: selectedYear != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: selectedYear != null ? 64 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF606060),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedYear != null ? _confirmSelection : null,
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
    if (selectedYear != null) {
      Navigator.of(context).pop(selectedYear);
    }
  }
}
