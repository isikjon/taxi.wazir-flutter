import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF264b47);
  static const Color primaryLight = Color(0xFF3a6b66);
  static const Color primaryDark = Color(0xFF1a322f);
  
  static const Color secondary = Color(0xFF2196F3);
  static const Color secondaryLight = Color(0xFF64B5F6);
  static const Color secondaryDark = Color(0xFF1976D2);
  
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);
  
  static const Color textPrimary = Color(0xFF264b47);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFFBDBDBD);
  
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF757575);
  static const Color busy = Color(0xFFFF9800);
  
  // Предопределенные цвета с прозрачностью
  static const Color primaryWithOpacity30 = Color(0x4D264b47); // 30% прозрачности
  static const Color primaryWithOpacity20 = Color(0x33264b47); // 20% прозрачности
  static const Color primaryWithOpacity10 = Color(0x1A264b47); // 10% прозрачности
  static const Color primaryWithOpacity60 = Color(0x99264b47); // 60% прозрачности
  static const Color primaryWithOpacity05 = Color(0x0D264b47); // 5% прозрачности
  
  static Color get primaryWithOpacity => primary.withOpacity(0.3);
  static Color get textSecondaryWithOpacity => textSecondary.withOpacity(0.5);
}
