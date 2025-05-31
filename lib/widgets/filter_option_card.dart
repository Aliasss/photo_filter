import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_option.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? LinearGradient(
            colors: AppColors.filterGradients[0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ) : null,
          color: isSelected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : AppColors.border,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? AppColors.filterGradients[0][0].withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filter.name,
              style: AppTextStyles.filterText.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAdjustmentChip('밝기', (filter.adjustments['brightness'] ?? 0).toInt()),
                  const SizedBox(width: 4),
                  _buildAdjustmentChip('대비', (filter.adjustments['contrast'] ?? 0).toInt()),
                  const SizedBox(width: 4),
                  _buildAdjustmentChip('따뜻함', (filter.adjustments['warmth'] ?? 0).toInt()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdjustmentChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label ${value > 0 ? '+' : ''}$value',
        style: AppTextStyles.filterText.copyWith(fontSize: 10),
      ),
    );
  }
} 