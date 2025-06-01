import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../models/filter_option.dart';
import '../widgets/category_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/filter_option_card.dart';
import 'edit_screen.dart';
import 'branding_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  int _selectedNavIndex = 0;
  int _selectedFilterIndex = -1;
  File? _selectedImage;
  bool _isUploading = false;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final selectedCategory = FilterCategory.categories[_selectedCategoryIndex];
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
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
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          gradient: _selectedImage == null 
            ? const LinearGradient(
                colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
              )
            : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.borderDashed,
            width: 2,
          ),
          image: _selectedImage != null 
            ? DecorationImage(
                image: FileImage(_selectedImage!),
                fit: BoxFit.cover,
              ) 
            : null,
        ),
        child: _selectedImage == null 
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  )
                else ...[
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
                  const SizedBox(height: 4),
                  Text(
                    '탭하여 갤러리에서 선택하거나 카메라로 촬영',
                    style: AppTextStyles.categoryDesc.copyWith(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          : Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImage = null;
                        _selectedFilterIndex = -1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
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
                  _selectedFilterIndex = -1;
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
              return FilterOptionCard(
                filter: FilterOption(
                  name: category.filters[index],
                  category: category.name,
                  adjustments: {'brightness': 0, 'contrast': 0, 'warmth': 0},
                ),
                isSelected: index == _selectedFilterIndex,
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index == _selectedFilterIndex ? -1 : index;
                  });
                  HapticFeedback.lightImpact();
                },
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
            isOutlined: true,
            onPressed: _selectedImage != null ? () => _showPreviewDialog() : () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: '편집 시작',
            onPressed: _selectedImage != null ? () => _navigateToEditScreen() : () {},
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('편집', Icons.edit, 0),
          _buildNavItem('템플릿', Icons.grid_view, 1),
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
        if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BrandingScreen()),
          );
        } else if (index == 1 || index == 3) {
          // 템플릿 탭과 내 작업 탭
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('알림', style: AppTextStyles.sectionTitle),
              content: Text(
                '곧 출시 예정입니다.',
                style: AppTextStyles.categoryDesc,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    '확인',
                    style: AppTextStyles.buttonText.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          setState(() {
            _selectedNavIndex = index;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.navText.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showImageSourceDialog() async {
    if (kIsWeb) {
      // 웹에서는 갤러리만 표시
      _pickImage(ImageSource.gallery);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text('사진 선택', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: '카메라',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: '갤러리',
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isUploading = true;
    });
    
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          if (kIsWeb) {
            // 웹에서는 XFile을 직접 사용
            _selectedImage = File(image.path);
          } else {
            _selectedImage = File(image.path);
          }
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 가져오는데 실패했습니다.')),
      );
    }
  }
  
  void _showPreviewDialog() {
    if (_selectedImage == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('미리보기', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedFilterIndex >= 0) ...[
                Text(
                  '선택된 필터: ${FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]}',
                  style: AppTextStyles.categoryDesc,
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              CustomButton(
                text: '닫기',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _navigateToEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditScreen(
          image: _selectedImage!,
          selectedFilter: _selectedFilterIndex >= 0 
            ? FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]
            : null,
        ),
      ),
    );
  }
} 