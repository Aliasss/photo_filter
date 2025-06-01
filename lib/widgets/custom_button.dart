import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isLoading;
  final bool isSmall;
  final bool isDark;
  final double? width;
  final double? height;
  final IconData? icon;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.isLoading = false,
    this.isSmall = false,
    this.isDark = false,
    this.width,
    this.height,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height ?? (isSmall ? 32 : 48),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isOutlined 
            ? Colors.transparent 
            : (isDark ? Colors.white : AppColors.primary),
          foregroundColor: isOutlined 
            ? (isDark ? Colors.white : AppColors.primary)
            : (isDark ? AppColors.primary : Colors.white),
          elevation: isOutlined ? 0 : 2,
          padding: isSmall 
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isSmall ? 6 : 8),
            side: isOutlined
                ? BorderSide(
                    color: isDark ? Colors.white : AppColors.primary, 
                    width: isSmall ? 1 : 2
                  )
                : BorderSide.none,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: isSmall ? 16 : 24,
                height: isSmall ? 16 : 24,
                child: CircularProgressIndicator(
                  strokeWidth: isSmall ? 1.5 : 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isOutlined 
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? AppColors.primary : Colors.white),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 14 : 20),
                    SizedBox(width: isSmall ? 4 : 8),
                  ],
                  Text(
                    text, 
                    style: isSmall 
                      ? AppTextStyles.buttonText.copyWith(fontSize: 12)
                      : AppTextStyles.buttonText,
                  ),
                ],
              ),
      ),
    );
  }
} 