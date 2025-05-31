import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF7C3AED);
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
  
  static const List<List<Color>> filterGradients = [
    [Color(0xFFFBBF24), Color(0xFFF59E0B)], // Golden
    [Color(0xFF10B981), Color(0xFF059669)], // Emerald
    [Color(0xFFF43F5E), Color(0xFFE11D48)], // Rose
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // Purple
    [Color(0xFF06B6D4), Color(0xFF0891B2)], // Cyan
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