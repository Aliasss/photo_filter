import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../models/filter_option.dart';
import '../utils/filter_utils.dart';
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
  dynamic _originalImage; // 원본 이미지 (File 또는 Uint8List)
  List<double> _currentMatrix = []; // 현재 적용된 필터 매트릭스
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
    
    // 초기 매트릭스 설정
    _currentMatrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
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
    if (_originalImage == null) {
      return GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                '사진을 업로드하세요',
                style: AppTextStyles.categoryDesc.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(_currentMatrix),
              child: kIsWeb
                  ? Image.memory(
                      _originalImage,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      _originalImage,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              setState(() {
                _originalImage = null;
                _selectedFilterIndex = -1;
                _currentMatrix = [
                  1.0, 0.0, 0.0, 0.0, 0.0,
                  0.0, 1.0, 0.0, 0.0, 0.0,
                  0.0, 0.0, 1.0, 0.0, 0.0,
                  0.0, 0.0, 0.0, 1.0, 0.0,
                ];
              });
            },
          ),
        ),
      ],
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
              final filterName = category.filters[index];
              return FilterOptionCard(
                filter: FilterOption.fromPreset(filterName, category.name),
                isSelected: index == _selectedFilterIndex,
                onTap: () {
                  print('필터 선택: $filterName'); // 디버그용
                  setState(() {
                    _selectedFilterIndex = index == _selectedFilterIndex ? -1 : index;
                    if (_selectedFilterIndex != -1) {
                      _currentMatrix = FilterUtils.getMatrixForFilter(filterName);
                      print('필터 매트릭스 적용됨: $_currentMatrix'); // 디버그용
                    } else {
                      // 필터 해제 시 기본 매트릭스로 복원
                      _currentMatrix = [
                        1.0, 0.0, 0.0, 0.0, 0.0,
                        0.0, 1.0, 0.0, 0.0, 0.0,
                        0.0, 0.0, 1.0, 0.0, 0.0,
                        0.0, 0.0, 0.0, 1.0, 0.0,
                      ];
                      print('기본 매트릭스로 복원됨'); // 디버그용
                    }
                  });
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
            onPressed: _originalImage != null ? () => _showPreviewDialog() : () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: '편집 시작',
            onPressed: _originalImage != null ? () => _navigateToEditScreen() : () {},
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
        if (kIsWeb) {
          // 웹에서는 Uint8List로 처리
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            _originalImage = bytes;
            _isUploading = false;
            // 이미지 선택 시 필터 초기화
            _selectedFilterIndex = -1;
            _currentMatrix = [
              1.0, 0.0, 0.0, 0.0, 0.0,
              0.0, 1.0, 0.0, 0.0, 0.0,
              0.0, 0.0, 1.0, 0.0, 0.0,
              0.0, 0.0, 0.0, 1.0, 0.0,
            ];
          });
        } else {
          // 모바일에서는 File 객체 사용
          setState(() {
            _originalImage = File(image.path);
            _isUploading = false;
            // 이미지 선택 시 필터 초기화
            _selectedFilterIndex = -1;
            _currentMatrix = [
              1.0, 0.0, 0.0, 0.0, 0.0,
              0.0, 1.0, 0.0, 0.0, 0.0,
              0.0, 0.0, 1.0, 0.0, 0.0,
              0.0, 0.0, 0.0, 1.0, 0.0,
            ];
          });
        }
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
    if (_originalImage == null) return;

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
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(_currentMatrix),
                  child: kIsWeb
                    ? Image.memory(
                        _originalImage,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        _originalImage,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
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
          image: _originalImage,
          selectedFilter: _selectedFilterIndex >= 0 
            ? FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]
            : null,
        ),
      ),
    );
  }
} 