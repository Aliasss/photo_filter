import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../utils/filter_utils.dart';
import '../utils/image_state.dart';
import '../widgets/custom_button.dart';

enum LogoPosition { topLeft, topRight, bottomLeft, bottomRight, center }

class BrandingScreen extends StatefulWidget {
  const BrandingScreen({Key? key}) : super(key: key);
  
  @override
  _BrandingScreenState createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  // 로고 관련
  dynamic _logoImage; // File 또는 Uint8List
  LogoPosition _logoPosition = LogoPosition.bottomRight;
  double _logoSize = 80.0; // 로고 크기 (픽셀)
  double _logoOpacity = 0.8; // 로고 투명도
  
  // 베이스 이미지 관련
  dynamic _baseImage; // 메인 이미지
  List<double> _currentMatrix = []; // 현재 적용된 매트릭스
  
  // 편집 관련 (브랜딩 화면에 추가된 편집 기능)
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _warmth = 0;
  String? _selectedFilter;
  bool _showEditingPanel = false;
  
  // 상태 관리
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBase = false;
  
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _previewKey = GlobalKey(); // RepaintBoundary 키
  final ImageState _imageState = ImageState(); // 전역 상태 관리
  
  @override
  void initState() {
    super.initState();
    _loadImageFromState();
  }
  
  void _loadImageFromState() {
    // ImageState에서 편집된 이미지 데이터 가져오기
    if (_imageState.hasEditedImage) {
      setState(() {
        _baseImage = _imageState.currentImage;
        _selectedFilter = _imageState.selectedFilter;
        _brightness = _imageState.brightness;
        _contrast = _imageState.contrast;
        _saturation = _imageState.saturation;
        _warmth = _imageState.warmth;
        _currentMatrix = _imageState.currentMatrix;
      });
      print('브랜딩 화면에 편집된 이미지 로드됨: 필터=$_selectedFilter, 밝기=$_brightness');
    } else {
      // 기본 매트릭스 설정
      _currentMatrix = [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    }
  }
  
  void _updateMatrix() {
    if (_selectedFilter != null) {
      // 기본 필터 매트릭스
      List<double> baseMatrix = FilterUtils.getMatrixForFilter(_selectedFilter!);
      // 편집 효과 매트릭스
      List<double> adjustmentMatrix = FilterUtils.createAdjustmentMatrix(
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        warmth: _warmth,
      );
      // 합성
      setState(() {
        _currentMatrix = _combineMatrices(baseMatrix, adjustmentMatrix);
      });
    } else {
      // 필터 없이 편집 효과만
      setState(() {
        _currentMatrix = FilterUtils.createAdjustmentMatrix(
          brightness: _brightness,
          contrast: _contrast,
          saturation: _saturation,
          warmth: _warmth,
        );
      });
    }
    
    // 상태 업데이트
    _imageState.updateAdjustments(
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      warmth: _warmth,
    );
    _imageState.updateMatrix(_currentMatrix);
  }
  
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('브랜딩 설정', style: AppTextStyles.sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 편집 패널 토글 버튼
          if (_baseImage != null)
            IconButton(
              icon: Icon(
                _showEditingPanel ? Icons.palette_outlined : Icons.tune,
                color: _showEditingPanel ? AppColors.primary : AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() {
                  _showEditingPanel = !_showEditingPanel;
                });
              },
            ),
          if (_baseImage != null && _logoImage != null)
            IconButton(
              icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save, color: AppColors.primary),
              onPressed: _isSaving ? null : _saveBrandedImage,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 미리보기 영역
            _buildPreviewSection(),
            
            // 컨트롤 영역
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_baseImage == null) _buildBaseImageSection(),
                  if (_baseImage != null) ...[
                    _buildLogoSection(),
                    if (_logoImage != null) ...[
                      const SizedBox(height: 24),
                      _buildPositionSection(),
                      const SizedBox(height: 24),
                      _buildSizeSection(),
                      const SizedBox(height: 24),
                      _buildOpacitySection(),
                    ],
                    // 편집 패널
                    if (_showEditingPanel) ...[
                      const SizedBox(height: 24),
                      _buildEditingSection(),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      width: double.infinity,
      height: 300,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _baseImage == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _imageState.hasEditedImage 
                      ? '편집된 이미지를 불러오는 중...'
                      : '브랜딩할 이미지를 선택하세요',
                    style: AppTextStyles.categoryDesc.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : RepaintBoundary(
              key: _previewKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 베이스 이미지 (편집 효과 적용)
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(_currentMatrix),
                    child: kIsWeb
                      ? Image.memory(
                          _baseImage as Uint8List,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _baseImage as File,
                          fit: BoxFit.cover,
                        ),
                  ),
                  
                  // 로고 오버레이
                  if (_logoImage != null)
                    _buildLogoOverlay(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildLogoOverlay() {
    return Positioned(
      top: _getLogoTop(),
      left: _getLogoLeft(),
      right: _getLogoRight(),
      bottom: _getLogoBottom(),
      child: Opacity(
        opacity: _logoOpacity,
        child: Container(
          width: _logoSize,
          height: _logoSize,
          child: kIsWeb
            ? Image.memory(
                _logoImage as Uint8List,
                fit: BoxFit.contain,
              )
            : Image.file(
                _logoImage as File,
                fit: BoxFit.contain,
              ),
        ),
      ),
    );
  }

  double? _getLogoTop() {
    switch (_logoPosition) {
      case LogoPosition.topLeft:
      case LogoPosition.topRight:
        return 16.0;
      case LogoPosition.center:
        return null; // 중앙 정렬을 위해 null
      default:
        return null;
    }
  }

  double? _getLogoLeft() {
    switch (_logoPosition) {
      case LogoPosition.topLeft:
      case LogoPosition.bottomLeft:
        return 16.0;
      case LogoPosition.center:
        return null; // 중앙 정렬을 위해 null
      default:
        return null;
    }
  }

  double? _getLogoRight() {
    switch (_logoPosition) {
      case LogoPosition.topRight:
      case LogoPosition.bottomRight:
        return 16.0;
      default:
        return null;
    }
  }

  double? _getLogoBottom() {
    switch (_logoPosition) {
      case LogoPosition.bottomLeft:
      case LogoPosition.bottomRight:
        return 16.0;
      case LogoPosition.center:
        return null; // 중앙 정렬을 위해 null
      default:
        return null;
    }
  }

  Widget _buildBaseImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('베이스 이미지', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        if (_imageState.hasEditedImage)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '편집된 이미지 사용',
                        style: AppTextStyles.categoryDesc.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (_imageState.selectedFilter != null)
                        Text(
                          '필터: ${_imageState.selectedFilter}',
                          style: AppTextStyles.categoryDesc.copyWith(
                            fontSize: 11,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                        ),
                    ],
                  ),
                ),
                CustomButton(
                  text: '불러오기',
                  isSmall: true,
                  onPressed: () {
                    setState(() {
                      _baseImage = _imageState.currentImage;
                      _selectedFilter = _imageState.selectedFilter;
                      _brightness = _imageState.brightness;
                      _contrast = _imageState.contrast;
                      _saturation = _imageState.saturation;
                      _warmth = _imageState.warmth;
                      _currentMatrix = _imageState.currentMatrix;
                    });
                  },
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        CustomButton(
          text: '새 이미지 선택',
          icon: Icons.photo_library,
          isLoading: _isUploadingBase,
          onPressed: _isUploadingBase ? () {} : () => _pickBaseImage(),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('로고 설정', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        if (_logoImage == null)
          CustomButton(
            text: '로고 이미지 추가',
            icon: Icons.add_photo_alternate,
            isLoading: _isUploadingLogo,
            onPressed: _isUploadingLogo ? () {} : () => _pickLogoImage(),
          )
        else
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                          ? Image.memory(
                              _logoImage as Uint8List,
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              _logoImage as File,
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('로고 이미지 선택됨', style: AppTextStyles.categoryDesc),
                          const SizedBox(height: 4),
                          Text(
                            '위치, 크기, 투명도를 조정하세요',
                            style: AppTextStyles.categoryDesc.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _logoImage = null;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPositionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('로고 위치', style: AppTextStyles.sectionTitle),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPositionButton('좌상', LogoPosition.topLeft),
                  _buildPositionButton('우상', LogoPosition.topRight),
                ],
              ),
              const SizedBox(height: 16),
              _buildPositionButton('중앙', LogoPosition.center),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPositionButton('좌하', LogoPosition.bottomLeft),
                  _buildPositionButton('우하', LogoPosition.bottomRight),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPositionButton(String label, LogoPosition position) {
    final isSelected = _logoPosition == position;
    return GestureDetector(
      onTap: () {
        setState(() {
          _logoPosition = position;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.categoryDesc.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('로고 크기', style: AppTextStyles.sectionTitle),
            Text(
              '${_logoSize.round()}px',
              style: AppTextStyles.categoryDesc.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _logoSize,
            min: 40.0,
            max: 200.0,
            onChanged: (value) {
              setState(() {
                _logoSize = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOpacitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('로고 투명도', style: AppTextStyles.sectionTitle),
            Text(
              '${(_logoOpacity * 100).round()}%',
              style: AppTextStyles.categoryDesc.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _logoOpacity,
            min: 0.1,
            max: 1.0,
            onChanged: (value) {
              setState(() {
                _logoOpacity = value;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEditingSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('이미지 편집', style: AppTextStyles.sectionTitle),
              if (_selectedFilter != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _selectedFilter!,
                    style: AppTextStyles.categoryDesc.copyWith(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAdjustmentSlider(
            '밝기',
            _brightness,
            -100.0,
            100.0,
            (value) {
              setState(() {
                _brightness = value;
              });
              _updateMatrix();
            },
          ),
          const SizedBox(height: 16),
          _buildAdjustmentSlider(
            '대비',
            _contrast,
            -100.0,
            100.0,
            (value) {
              setState(() {
                _contrast = value;
              });
              _updateMatrix();
            },
          ),
          const SizedBox(height: 16),
          _buildAdjustmentSlider(
            '채도',
            _saturation,
            -100.0,
            100.0,
            (value) {
              setState(() {
                _saturation = value;
              });
              _updateMatrix();
            },
          ),
          const SizedBox(height: 16),
          _buildAdjustmentSlider(
            '따뜻함',
            _warmth,
            -100.0,
            100.0,
            (value) {
              setState(() {
                _warmth = value;
              });
              _updateMatrix();
            },
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: '편집 초기화',
            isOutlined: true,
            icon: Icons.refresh,
            onPressed: () {
              setState(() {
                _brightness = 0;
                _contrast = 0;
                _saturation = 0;
                _warmth = 0;
              });
              _updateMatrix();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.categoryDesc),
            Text(
              '${value.round()}',
              style: AppTextStyles.categoryDesc.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Future<void> _pickBaseImage() async {
    setState(() {
      _isUploadingBase = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            _baseImage = bytes;
            // 새 이미지 선택 시 편집값 초기화
            _brightness = 0;
            _contrast = 0;
            _saturation = 0;
            _warmth = 0;
            _selectedFilter = null;
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
          _imageState.updateAdjustments(
            brightness: 0,
            contrast: 0,
            saturation: 0,
            warmth: 0,
          );
          _imageState.updateMatrix(_currentMatrix);
        } else {
          setState(() {
            _baseImage = File(image.path);
            // 새 이미지 선택 시 편집값 초기화
            _brightness = 0;
            _contrast = 0;
            _saturation = 0;
            _warmth = 0;
            _selectedFilter = null;
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
          _imageState.updateAdjustments(
            brightness: 0,
            contrast: 0,
            saturation: 0,
            warmth: 0,
          );
          _imageState.updateMatrix(_currentMatrix);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지를 가져오는데 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingBase = false;
      });
    }
  }

  Future<void> _pickLogoImage() async {
    setState(() {
      _isUploadingLogo = true;
    });

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (kIsWeb) {
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            _logoImage = bytes;
          });
        } else {
          setState(() {
            _logoImage = File(image.path);
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('로고 이미지를 가져오는데 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingLogo = false;
      });
    }
  }

  Future<Uint8List?> _captureBrandedImage() async {
    try {
      RenderRepaintBoundary boundary = _previewKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('브랜딩된 이미지 캡처 오류: $e');
      return null;
    }
  }

  Future<void> _saveBrandedImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      Uint8List? brandedImageBytes = await _captureBrandedImage();
      
      if (brandedImageBytes == null) {
        throw Exception('브랜딩된 이미지 캡처 실패');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'branded_image_$timestamp.png';

      final result = await ImageGallerySaver.saveImage(
        brandedImageBytes,
        name: fileName,
        quality: 100,
      );
      
      if (result['isSuccess'] == true || result['isSuccess'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('브랜딩된 이미지가 갤러리에 저장되었습니다.'),
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
        _isSaving = false;
      });
    }
  }
} 