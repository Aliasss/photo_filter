import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color accent = Color(0xFF03DAC6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDashed = Color(0xFFD1D5DB);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
  
  static const List<Color> filterColors = [
    Color(0xFFFBBF24), // 황금
    Color(0xFF10B981), // 에메랄드
    Color(0xFFF43F5E), // 로즈
    Color(0xFF8B5CF6), // 퍼플
    Color(0xFF06B6D4), // 시안
  ];
  
  static const List<Color> brandColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
  ];
} 