import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF3F51B5);
  static const Color primaryLight = Color(0xFF7986CB);
  static const Color primaryDark = Color(0xFF303F9F);

  static const Color accent = Color(0xFFFF4081);
  static const Color accentLight = Color(0xFFFF80AB);
  static const Color accentDark = Color(0xFFC51162);

  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;

  static const Color cardBackground = Colors.white;
  static const Color cardBorder = Color(0xFFE0E0E0);

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD); 

  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107); 
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3); 

  static const Color divider = Color(0xFFE0E0E0); 
  static const Color disabled = Color(0xFFBDBDBD); 
  static const Color shadow = Color(0x40000000); 

  static const List<Color> primaryGradient = [
    primary,
    primaryDark,
  ];
  
  static const List<Color> accentGradient = [
    accent,
    accentDark,
  ];
}