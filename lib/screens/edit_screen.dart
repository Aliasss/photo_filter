import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
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
                // TODO: 필터 조정 슬라이더 추가
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

  void _resetValues() {
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _warmth = 0;
    });
  }
} 