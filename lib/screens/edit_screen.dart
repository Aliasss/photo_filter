import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../utils/filter_utils.dart';
import '../widgets/custom_button.dart';
import 'branding_screen.dart';

// 웹 전용 import
import 'dart:html' as html if (dart.library.io) 'dart:io' as io;

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
  double _warmth = 0;
  List<double> _currentMatrix = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedFilter != null) {
      _currentMatrix = FilterUtils.getMatrixForFilter(widget.selectedFilter!);
    } else {
      _currentMatrix = [
        1.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 1.0, 0.0,
      ];
    }
  }

  void _updateMatrix() {
    setState(() {
      _currentMatrix = FilterUtils.createAdjustmentMatrix(
        brightness: _brightness,
        contrast: _contrast,
        warmth: _warmth,
      );
    });
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 이미지 데이터 가져오기
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = widget.image as Uint8List;
      } else {
        final File file = widget.image as File;
        imageBytes = await file.readAsBytes();
      }

      // 파일명 생성
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'edited_image_$timestamp.png';

      if (kIsWeb) {
        // 웹 저장 로직
        final blob = html.Blob([imageBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..download = fileName
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지가 다운로드되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 모바일 저장 로직
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          name: fileName,
          quality: 100,
        );

        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('갤러리에 저장되었습니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          throw Exception('이미지 저장 실패');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
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
        title: const Text('사진 편집'),
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
              : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(_currentMatrix),
                child: kIsWeb
                  ? Image.memory(
                      widget.image,
                      fit: BoxFit.contain,
                    )
                  : Image.file(
                      widget.image,
                      fit: BoxFit.contain,
                    ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
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
                _buildAdjustmentSlider(
                  '밝기',
                  _brightness,
                  -1.0,
                  1.0,
                  (value) {
                    setState(() {
                      _brightness = value;
                      _updateMatrix();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildAdjustmentSlider(
                  '대비',
                  _contrast,
                  -1.0,
                  1.0,
                  (value) {
                    setState(() {
                      _contrast = value;
                      _updateMatrix();
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildAdjustmentSlider(
                  '따뜻함',
                  _warmth,
                  -1.0,
                  1.0,
                  (value) {
                    setState(() {
                      _warmth = value;
                      _updateMatrix();
                    });
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
              '${(value * 100).round()}%',
              style: AppTextStyles.categoryDesc.copyWith(
                color: AppColors.primary,
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
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 16,
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
      _warmth = 0;
      _updateMatrix();
    });
  }
} 