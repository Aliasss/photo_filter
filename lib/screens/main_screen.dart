import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
// import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../models/filter_option.dart';
import '../models/filter_preset.dart';
import '../utils/filter_utils.dart';
import '../utils/favorites_storage.dart';
import '../utils/image_state.dart';
import '../widgets/category_card.dart';
import '../widgets/custom_button.dart';
import '../widgets/filter_option_card.dart';
import 'edit_screen.dart';
import 'branding_screen.dart';
import 'favorites_screen.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

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
  bool _isSavingFromPreview = false; // 미리보기에서 저장 중 상태
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _previewKey = GlobalKey(); // RepaintBoundary 키
  final ImageState _imageState = ImageState(); // 전역 상태 관리
  
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Text('브랜딧', style: AppTextStyles.headerTitle.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          )),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              '당신의 사진이 브랜드가 되는 순간', 
              style: AppTextStyles.headerSubtitle.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
          height: 280,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1.5),
            boxShadow: AppColors.lightShadow,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '사진을 업로드하세요',
                style: AppTextStyles.categoryDesc.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '카메라로 촬영하거나 갤러리에서 선택하세요',
                style: AppTextStyles.categoryDesc.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
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
          height: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.mediumShadow,
            border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(19),
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
          top: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              boxShadow: AppColors.lightShadow,
            ),
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 20),
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
                // 상태 초기화
                _imageState.reset();
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '카테고리별 필터', 
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
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
                // 필터 선택 초기화 시 상태 업데이트
                _imageState.updateFilter(null);
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                '${category.name} 전용 필터', 
                style: AppTextStyles.sectionTitle.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${category.filters.length}개',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: category.filters.length,
            itemBuilder: (context, index) {
              final filterName = category.filters[index];
              return Container(
                margin: const EdgeInsets.only(right: 14),
                child: FilterOptionCard(
                  filter: FilterOption.fromPreset(filterName, category.name),
                  isSelected: index == _selectedFilterIndex,
                  onTap: () {
                    print('필터 선택: $filterName'); // 디버그용
                    setState(() {
                      _selectedFilterIndex = index == _selectedFilterIndex ? -1 : index;
                      if (_selectedFilterIndex != -1) {
                        _currentMatrix = FilterUtils.getMatrixForFilter(filterName);
                        print('필터 매트릭스 적용됨: $_currentMatrix'); // 디버그용
                        // 상태 업데이트
                        _imageState.updateFilter(filterName);
                        _imageState.updateMatrix(_currentMatrix);
                      } else {
                        // 필터 해제 시 기본 매트릭스로 복원
                        _currentMatrix = [
                          1.0, 0.0, 0.0, 0.0, 0.0,
                          0.0, 1.0, 0.0, 0.0, 0.0,
                          0.0, 0.0, 1.0, 0.0, 0.0,
                          0.0, 0.0, 0.0, 1.0, 0.0,
                        ];
                        print('기본 매트릭스로 복원됨'); // 디버그용
                        // 상태 업데이트
                        _imageState.updateFilter(null);
                        _imageState.updateMatrix(_currentMatrix);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: '미리보기',
              isOutlined: true,
              onPressed: _originalImage != null ? () => _showPreviewDialog() : () {},
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: CustomButton(
              text: '편집 시작',
              icon: Icons.edit,
              onPressed: _originalImage != null ? () => _navigateToEditScreen() : () {},
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.3))),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem('편집', Icons.edit, 0),
          _buildNavItem('브랜딩', Icons.palette, 1),
          _buildNavItem('즐겨찾기', Icons.favorite, 2),
        ],
      ),
    );
  }
  
  Widget _buildNavItem(String label, IconData icon, int index) {
    final isSelected = _selectedNavIndex == index;
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          // 브랜딩 탭 - 현재 편집된 상태를 전달
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BrandingScreen(),
            ),
          );
        } else if (index == 2) {
          // 즐겨찾기 탭
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FavoritesScreen(
                onPresetSelected: (FilterPreset preset) {
                  _applyPreset(preset);
                },
              ),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? AppColors.lightShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.navText.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showPreviewDialog() {
    if (_originalImage == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withOpacity(0.95),
                AppColors.surface.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
            boxShadow: AppColors.heavyShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Text(
                  '미리보기', 
                  style: AppTextStyles.sectionTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 이미지 미리보기
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.mediumShadow,
                  border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: RepaintBoundary(
                    key: _previewKey,
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(_currentMatrix),
                      child: kIsWeb
                        ? Image.memory(
                            _originalImage,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _originalImage,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 필터 정보
              if (_selectedFilterIndex >= 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.lightShadow,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.filter_vintage, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]}',
                        style: AppTextStyles.categoryDesc.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              
              // 버튼들
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: '저장',
                      icon: Icons.save_alt,
                      isLoading: _isSavingFromPreview,
                      onPressed: _isSavingFromPreview ? () {} : () => _saveFilteredImageFromPreview(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: '닫기',
                      isOutlined: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface.withOpacity(0.95),
              AppColors.surface,
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.border.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 32,
              spreadRadius: 0,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 핸들 바
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.lightShadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_camera, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    '사진 선택', 
                    style: AppTextStyles.sectionTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // 버튼들
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: '카메라',
                    icon: Icons.camera_alt,
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: '갤러리',
                    icon: Icons.photo_library,
                    onPressed: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
          // 상태 업데이트
          _imageState.updateImage(bytes);
          _imageState.updateFilter(null);
          _imageState.updateMatrix(_currentMatrix);
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
          // 상태 업데이트
          _imageState.updateImage(File(image.path));
          _imageState.updateFilter(null);
          _imageState.updateMatrix(_currentMatrix);
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
  
  Future<Uint8List?> _captureRepaintBoundary() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('RepaintBoundary 캡처 오류: $e');
      return null;
    }
  }
  
  Future<void> _saveFilteredImageFromPreview() async {
    if (_originalImage == null) return;

    setState(() {
      _isSavingFromPreview = true;
    });

    try {
      Uint8List? finalImageBytes;
      
      if (_selectedFilterIndex >= 0 && _currentMatrix.isNotEmpty) {
        // 필터가 선택된 경우 RepaintBoundary에서 캡처
        finalImageBytes = await _captureRepaintBoundary();
        print('필터 적용된 이미지 캡처 완료: ${FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]}');
      } else {
        // 필터가 선택되지 않은 경우 원본 저장
        if (_originalImage is File) {
          final File file = _originalImage as File;
          finalImageBytes = await file.readAsBytes();
        } else {
          finalImageBytes = _originalImage as Uint8List;
        }
        print('원본 이미지 저장');
      }

      if (finalImageBytes == null) {
        throw Exception('이미지 처리 실패');
      }

      final String fileName = 'filtered_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await ImageGallerySaver.saveImage(
        finalImageBytes,
        name: fileName,
        quality: 90,
      );

      if (result['isSuccess'] == true || result['isSuccess'] == 1) {
        // 다이얼로그 닫기
        Navigator.pop(context);
        
        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('갤러리에 저장되었습니다.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('이미지 저장 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('저장 중 오류가 발생했습니다: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSavingFromPreview = false;
      });
    }
  }
  
  void _navigateToEditScreen() {
    // 현재 상태를 ImageState에 저장
    _imageState.updateImage(_originalImage);
    _imageState.updateFilter(_selectedFilterIndex >= 0 
      ? FilterCategory.categories[_selectedCategoryIndex].filters[_selectedFilterIndex]
      : null);
    _imageState.updateMatrix(_currentMatrix);
    
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

  Future<void> _saveImage() async {
    if (_originalImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      Uint8List imageBytes;
      String fileName;

      if (_originalImage is File) {
        final File file = _originalImage as File;
        imageBytes = await file.readAsBytes();
      } else {
        imageBytes = _originalImage as Uint8List;
      }
      fileName = 'business_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: fileName,
        quality: 100,
      );
      if (result['isSuccess'] == true || result['isSuccess'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('갤러리에 저장되었습니다.'), duration: Duration(seconds: 2)),
        );
      } else {
        throw Exception('이미지 저장 실패');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 저장하는데 실패했습니다.')),
      );
    }
  }

  void _applyPreset(FilterPreset preset) {
    if (_originalImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 이미지를 선택해주세요.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // 프리셋의 필터 적용
      if (preset.filterType != null) {
        // 해당 필터가 속한 카테고리 찾기
        for (int catIndex = 0; catIndex < FilterCategory.categories.length; catIndex++) {
          final category = FilterCategory.categories[catIndex];
          final filterIndex = category.filters.indexOf(preset.filterType!);
          if (filterIndex != -1) {
            _selectedCategoryIndex = catIndex;
            _selectedFilterIndex = filterIndex;
            break;
          }
        }
      } else {
        _selectedFilterIndex = -1;
      }

      // 매트릭스 계산 및 적용
      List<double> baseMatrix = preset.filterType != null
          ? FilterUtils.getMatrixForFilter(preset.filterType!)
          : [
              1.0, 0.0, 0.0, 0.0, 0.0,
              0.0, 1.0, 0.0, 0.0, 0.0,
              0.0, 0.0, 1.0, 0.0, 0.0,
              0.0, 0.0, 0.0, 1.0, 0.0,
            ];

      // 편집 효과 매트릭스 생성
      List<double> adjustmentMatrix = FilterUtils.createAdjustmentMatrix(
        brightness: preset.brightness,
        contrast: preset.contrast,
        saturation: preset.saturation,
        warmth: preset.warmth,
      );

      // 두 매트릭스 합성
      _currentMatrix = _combineMatrices(baseMatrix, adjustmentMatrix);
    });

    // 상태 업데이트
    _imageState.updateFilter(preset.filterType);
    _imageState.updateAdjustments(
      brightness: preset.brightness,
      contrast: preset.contrast,
      saturation: preset.saturation,
      warmth: preset.warmth,
    );
    _imageState.updateMatrix(_currentMatrix);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text("'${preset.name}' 프리셋이 적용되었습니다."),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 두 매트릭스를 합성하는 함수 (edit_screen.dart와 동일)
  List<double> _combineMatrices(List<double> matrix1, List<double> matrix2) {
    List<double> result = List.filled(20, 0.0);
    
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        if (col < 4) {
          for (int k = 0; k < 4; k++) {
            result[row * 5 + col] += matrix1[row * 5 + k] * matrix2[k * 5 + col];
          }
        } else {
          result[row * 5 + col] = matrix1[row * 5 + col] + matrix2[row * 5 + col];
        }
      }
    }
    
    return result;
  }
} 