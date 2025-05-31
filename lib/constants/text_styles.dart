import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const String fontFamily = 'NotoSans';
  
  static TextStyle get headerTitle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    fontFamily: fontFamily,
  );
  
  static TextStyle get headerSubtitle => TextStyle(
    fontSize: 14,
    color: Colors.white.withOpacity(0.9),
    fontFamily: fontFamily,
  );
  
  static TextStyle get sectionTitle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static TextStyle get categoryName => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
  
  static TextStyle get categoryDesc => const TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
    fontFamily: fontFamily,
  );
  
  static TextStyle get buttonText => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );
  
  static TextStyle get filterText => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white,
    fontFamily: fontFamily,
  );
  
  static TextStyle get navText => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
  
  static TextStyle get sliderLabel => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
} 