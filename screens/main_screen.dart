import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../widgets/category_card.dart';
import '../widgets/custom_button.dart';
import 'edit_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedCategoryIndex = 0;
  int _selectedNavIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final selectedCategory = FilterCategory.categories[_selectedCategoryIndex];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoPreview(),
                    const SizedBox(height: 24),
                    _buildCategorySection(),
                    const SizedBox(height: 24),
                    _buildFilterSection(selectedCategory),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text('비즈니스 포토', style: AppTextStyles.headerTitle),
          const SizedBox(height: 8),
          Text('매장용 사진을 프로처럼 편집하세요', style: AppTextStyles.headerSubtitle),
        ],
      ),
    );
  }
  
  Widget _buildPhotoPreview() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderDashed,
          width: 2,
          style: BorderStyle.none,
        ),
      ),
      child: DashedBorder(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              '사진을 업로드하세요',
              style: AppTextStyles.categoryDesc.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('카테고리별 필터', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: FilterCategory.categories.length,
          itemBuilder: (context, index) {
            return CategoryCard(
              category: FilterCategory.categories[index],
              isSelected: index == _selectedCategoryIndex,
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildFilterSection(FilterCategory category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${category.name} 전용 필터', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: category.filters.length,
            itemBuilder: (context, index) {
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.filterColors[index % AppColors.filterColors.length],
                      AppColors.filterColors[index % AppColors.filterColors.length].withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    category.filters[index].replaceAll(' ', '\n'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: '미리보기',
            isPrimary: false,
            onPressed: () {
              // 미리보기 로직
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: '편집 시작',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditScreen()),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('편집', Icons.edit, 0),
          _buildNavItem('템플릿', Icons.template_outlined, 1),
          _buildNavItem('브랜딩', Icons.palette, 2),
          _buildNavItem('내 작업', Icons.folder, 3),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(String label, IconData icon, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNavIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// DashedBorder 위젯 (점선 테두리용)
class DashedBorder extends StatelessWidget {
  final Widget child;
  
  const DashedBorder({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderDashed,
          width: 2,
          style: BorderStyle.solid, // 실제로는 dashed_border 패키지 사용 권장
        ),
      ),
      child: child,
    );
  }
} 