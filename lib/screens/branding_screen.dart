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
import '../widgets/custom_button.dart';

enum LogoPosition { topLeft, topRight, bottomLeft, bottomRight, center }

class BrandingScreen extends StatefulWidget {
  final dynamic baseImage; // 베이스 이미지 (옵션)
  final String? selectedFilter; // 적용된 필터 (옵션)
  
  const BrandingScreen({
    Key? key,
    this.baseImage,
    this.selectedFilter,
  }) : super(key: key);
  
  @override
  _BrandingScreenState createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<BrandingScreen> {
  // 브랜드 컬러 관련
  int _selectedColorIndex = 0;
  
  // 로고 관련
  dynamic _logoImage; // File 또는 Uint8List
  LogoPosition _logoPosition = LogoPosition.bottomRight;
  double _logoSize = 80.0; // 로고 크기 (픽셀)
  double _logoOpacity = 0.8; // 로고 투명도
  
  // 베이스 이미지 관련
  dynamic _baseImage; // 메인 이미지
  
  // 상태 관리
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  bool _isUploadingBase = false;
  
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _previewKey = GlobalKey(); // RepaintBoundary 키
  
  @override
  void initState() {
    super.initState();
    _baseImage = widget.baseImage;
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
                    '브랜딩할 이미지를 선택하세요',
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
                  // 베이스 이미지
                  kIsWeb
                    ? Image.memory(
                        _baseImage as Uint8List,
                        fit: BoxFit.cover,
                      )
                    : Image.file(
                        _baseImage as File,
                        fit: BoxFit.cover,
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
        CustomButton(
          text: '이미지 선택',
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
          });
        } else {
          setState(() {
            _baseImage = File(image.path);
          });
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