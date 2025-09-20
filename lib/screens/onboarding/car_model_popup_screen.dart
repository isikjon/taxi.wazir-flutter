import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../styles/app_colors.dart';
import '../../styles/app_spacing.dart';

class CarModelPopupScreen extends StatefulWidget {
  final String selectedBrand;

  const CarModelPopupScreen({
    super.key,
    required this.selectedBrand,
  });

  @override
  State<CarModelPopupScreen> createState() => _CarModelPopupScreenState();
}

class _CarModelPopupScreenState extends State<CarModelPopupScreen>
    with TickerProviderStateMixin {
  String? selectedModel;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonAnimation;
  
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredModels = [];
  List<String> allModels = [];

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
    _loadCarModels();
    _searchController.addListener(_filterModels);
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _slideController.forward();
  }

  void _loadCarModels() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/cars.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> brands = jsonData['brands'];
      
      if (brands.containsKey(widget.selectedBrand)) {
        final brandData = brands[widget.selectedBrand] as Map<String, dynamic>;
        final models = brandData['models'] as List<dynamic>;
        
        setState(() {
          allModels = models.map((model) => model.toString()).toList()..sort();
          filteredModels = allModels;
        });
      } else {
        setState(() {
          allModels = [];
          filteredModels = [];
        });
      }
    } catch (e) {
      print('Error loading car models: $e');
      // Fallback data
      setState(() {
        allModels = ['Model 1', 'Model 2', 'Model 3', 'Model 4', 'Model 5'];
        filteredModels = allModels;
      });
    }
  }

  void _filterModels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredModels = allModels;
      } else {
        filteredModels = allModels
            .where((model) => model.toLowerCase().contains(query))
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
            child: _buildAnimatedModelsList(),
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
        'Выберите модель',
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
              hintText: 'Поиск модели...',
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

  Widget _buildAnimatedModelsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          itemCount: filteredModels.length,
          itemBuilder: (context, index) {
            final model = filteredModels[index];
            final isSelected = selectedModel == model;
            
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
                      selectedModel = model;
                    });
                    _buttonController.forward();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            model,
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
            opacity: selectedModel != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: selectedModel != null ? 64 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF264b47),
                borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLarge),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: selectedModel != null ? _confirmSelection : null,
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
    if (selectedModel != null) {
      Navigator.of(context).pop(selectedModel);
    }
  }
}
