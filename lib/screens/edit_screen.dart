import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../utils/filter_utils.dart';
import '../widgets/custom_button.dart';
import 'branding_screen.dart';

class EditScreen extends StatefulWidget {
  final dynamic image; // File 또는 Uint8List
  final String? selectedFilter;
  
  const EditScreen({
    Key? key,
    required this.image,
    this.selectedFilter,
  }) : super(key: key);
  
  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _warmth = 0;
  List<double> _baseFilterMatrix = []; // 기본 필터 매트릭스
  List<double> _currentMatrix = []; // 현재 적용된 최종 매트릭스
  bool _isSaving = false;
  final GlobalKey _imageKey = GlobalKey(); // RepaintBoundary 키

  @override
  void initState() {
    super.initState();
    // 기본 필터 매트릭스 설정
    if (widget.selectedFilter != null) {
      _baseFilterMatrix = FilterUtils.getMatrixForFilter(widget.selectedFilter!);
      print('기본 필터 적용: ${widget.selectedFilter}');
    } else {
      _baseFilterMatrix = [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    }
    _currentMatrix = List.from(_baseFilterMatrix);
    _updateMatrix();
  }

  void _updateMatrix() {
    print('매트릭스 업데이트: 밝기=$_brightness, 대비=$_contrast, 채도=$_saturation, 따뜻함=$_warmth');
    
    // 편집 효과 매트릭스 생성
    List<double> adjustmentMatrix = FilterUtils.createAdjustmentMatrix(
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      warmth: _warmth,
    );
    
    // 기본 필터 + 편집 효과 합성
    setState(() {
      _currentMatrix = _combineMatrices(_baseFilterMatrix, adjustmentMatrix);
    });
    
    print('최종 매트릭스: $_currentMatrix');
  }

  // 두 매트릭스를 합성하는 함수
  List<double> _combineMatrices(List<double> matrix1, List<double> matrix2) {
    // 4x5 매트릭스 곱셈 (ColorMatrix 합성)
    List<double> result = List.filled(20, 0.0);
    
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        if (col < 4) {
          // 매트릭스 곱셈
          for (int k = 0; k < 4; k++) {
            result[row * 5 + col] += matrix1[row * 5 + k] * matrix2[k * 5 + col];
          }
        } else {
          // offset 값 (마지막 열)
          result[row * 5 + col] = matrix1[row * 5 + col] + matrix2[row * 5 + col];
        }
      }
    }
    
    return result;
  }

  Future<Uint8List?> _captureEditedImage() async {
    try {
      RenderRepaintBoundary boundary = _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('이미지 캡처 오류: $e');
      return null;
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 편집된 이미지 캡처
      Uint8List? editedImageBytes = await _captureEditedImage();
      
      if (editedImageBytes == null) {
        throw Exception('편집된 이미지 캡처 실패');
      }

      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'edited_image_$timestamp.png';

      final result = await ImageGallerySaver.saveImage(
        editedImageBytes,
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
                Text('편집된 이미지가 갤러리에 저장되었습니다.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('사진 편집', style: AppTextStyles.sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
            onPressed: _isSaving ? null : _saveImage,
          ),
        ],
      ),
      body: Column(
        children: [
          // 이미지 미리보기 영역
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: RepaintBoundary(
                  key: _imageKey,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix(_currentMatrix),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                        ? Image.memory(
                            widget.image as Uint8List,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            widget.image as File,
                            fit: BoxFit.contain,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 편집 컨트롤 영역
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 현재 필터 표시
                if (widget.selectedFilter != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '적용된 필터: ${widget.selectedFilter}',
                      style: AppTextStyles.categoryDesc.copyWith(
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
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
                  text: '초기화',
                  isOutlined: true,
                  icon: Icons.refresh,
                  onPressed: _resetValues,
                ),
              ],
            ),
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
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 20,
            ),
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

  void _resetValues() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _warmth = 0;
    });
    _updateMatrix();
  }
} 