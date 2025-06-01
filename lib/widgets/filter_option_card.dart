import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_option.dart';
import '../utils/filter_utils.dart';

class FilterOptionCard extends StatelessWidget {
  final FilterOption filter;
  final bool isSelected;
  final VoidCallback onTap;
  
  const FilterOptionCard({
    Key? key,
    required this.filter,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final preset = FilterUtils.getFilterPreset(filter.name);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filter.name,
              style: AppTextStyles.categoryDesc.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                '밝기: ${(preset['brightness']! * 100).round()}%\n'
                '대비: ${(preset['contrast']! * 100).round()}%\n'
                '따뜻함: ${(preset['warmth']! * 100).round()}%',
                style: AppTextStyles.categoryDesc.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
} 