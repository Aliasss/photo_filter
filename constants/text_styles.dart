import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  static TextStyle get headerTitle => GoogleFonts.notoSans(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );
  
  static TextStyle get headerSubtitle => GoogleFonts.notoSans(
    fontSize: 14,
    color: Colors.white.withOpacity(0.9),
  );
  
  static TextStyle get sectionTitle => GoogleFonts.notoSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get categoryName => GoogleFonts.notoSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get categoryDesc => GoogleFonts.notoSans(
    fontSize: 12,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get buttonText => GoogleFonts.notoSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
} 