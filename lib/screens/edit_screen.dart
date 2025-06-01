import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  double _warmth = 0;
  List<double> _currentMatrix = [];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('사진 편집'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: 저장 기능 구현
            },
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