import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/template.dart';
import '../widgets/custom_button.dart';
import 'template_editor_screen.dart';

class ImageAdjustmentScreen extends StatefulWidget {
  final Template template;
  final XFile userImage;

  const ImageAdjustmentScreen({
    Key? key,
    required this.template,
    required this.userImage,
  }) : super(key: key);

  @override
  _ImageAdjustmentScreenState createState() => _ImageAdjustmentScreenState();
}

class _ImageAdjustmentScreenState extends State<ImageAdjustmentScreen> {
  dynamic _originalImage;
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _offset = Offset.zero;
  Size? _imageSize;
  Size? _containerSize;
  bool _isLoading = true;
  
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _containerKey = GlobalKey();

  // 줌 제한
  static const double _minScale = 0.5;
  static const double _maxScale = 3.0;

  @override
  void initState() {
    super.initState();
    _loadImage();
    
    // transformation controller 변화 감지
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final Matrix4 matrix = _transformationController.value;
    setState(() {
      _scale = matrix.getMaxScaleOnAxis();
      _offset = Offset(matrix.getTranslation().x, matrix.getTranslation().y);
    });
  }

  Future<void> _loadImage() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kIsWeb) {
        final bytes = await widget.userImage.readAsBytes();
        setState(() {
          _originalImage = bytes;
        });
        await _getImageSize(MemoryImage(bytes));
      } else {
        final file = File(widget.userImage.path);
        setState(() {
          _originalImage = file;
        });
        await _getImageSize(FileImage(file));
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('이미지 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getImageSize(ImageProvider imageProvider) async {
    final Completer<ui.Image> completer = Completer();
    final ImageStream stream = imageProvider.resolve(ImageConfiguration.empty);
    stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
      completer.complete(info.image);
    }));
    
    final ui.Image image = await completer.future;
    setState(() {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    });
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _rotation = 0.0;
      _offset = Offset.zero;
    });
    _transformationController.value = Matrix4.identity();
  }

  void _applyScale(double newScale) {
    final double clampedScale = newScale.clamp(_minScale, _maxScale);
    final Matrix4 matrix = Matrix4.identity()
      ..translate(_offset.dx, _offset.dy)
      ..scale(clampedScale);
    
    _transformationController.value = matrix;
    setState(() {
      _scale = clampedScale;
    });
  }

  void _applyOffset(Offset newOffset) {
    final Matrix4 matrix = Matrix4.identity()
      ..translate(newOffset.dx, newOffset.dy)
      ..scale(_scale);
    
    _transformationController.value = matrix;
    setState(() {
      _offset = newOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          '이미지 조정',
          style: AppTextStyles.sectionTitle.copyWith(color: Colors.white),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetTransform,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : Column(
              children: [
                // 템플릿 정보
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black87,
                  child: Row(
                    children: [
                      Text(
                        _getTemplateIcon(),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.template.name,
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '이미지를 조정하세요 (핀치/드래그)',
                              style: AppTextStyles.categoryDesc.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 이미지 조정 영역
                Expanded(
                  child: Container(
                    key: _containerKey,
                    width: double.infinity,
                    child: Stack(
                      children: [
                        // 이미지 뷰어
                        InteractiveViewer(
                          transformationController: _transformationController,
                          minScale: _minScale,
                          maxScale: _maxScale,
                          boundaryMargin: EdgeInsets.all(100),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: _buildImageWidget(),
                          ),
                        ),

                        // 크롭 가이드라인
                        _buildCropGuide(),

                        // 줌 레벨 표시
                        Positioned(
                          top: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(_scale * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 컨트롤 버튼들
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black87,
                  child: Column(
                    children: [
                      // 조정 버튼들
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.zoom_out,
                            label: '축소',
                            onPressed: () {
                              _applyScale(_scale / 1.2);
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.center_focus_strong,
                            label: '중앙',
                            onPressed: () {
                              _applyOffset(Offset.zero);
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.zoom_in,
                            label: '확대',
                            onPressed: () {
                              _applyScale(_scale * 1.2);
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 완료/취소 버튼
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: '취소',
                              isOutlined: true,
                              isDark: true,
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomButton(
                              text: '완료',
                              isDark: true,
                              onPressed: _applyAdjustment,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildImageWidget() {
    if (_originalImage == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Center(
      child: kIsWeb
          ? Image.memory(
              _originalImage as Uint8List,
              fit: BoxFit.contain,
            )
          : Image.file(
              _originalImage as File,
              fit: BoxFit.contain,
            ),
    );
  }

  Widget _buildCropGuide() {
    return Center(
      child: AspectRatio(
        aspectRatio: widget.template.aspectRatio,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // 모서리 가이드
              ..._buildCornerGuides(),
              
              // 중앙 정보
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '템플릿 영역',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCornerGuides() {
    const double guideSize = 20;
    const double guideThickness = 3;
    
    return [
      // 좌상단
      Positioned(
        top: -guideThickness,
        left: -guideThickness,
        child: Container(
          width: guideSize,
          height: guideSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: guideThickness),
              left: BorderSide(color: Colors.white, width: guideThickness),
            ),
          ),
        ),
      ),
      // 우상단
      Positioned(
        top: -guideThickness,
        right: -guideThickness,
        child: Container(
          width: guideSize,
          height: guideSize,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: guideThickness),
              right: BorderSide(color: Colors.white, width: guideThickness),
            ),
          ),
        ),
      ),
      // 좌하단
      Positioned(
        bottom: -guideThickness,
        left: -guideThickness,
        child: Container(
          width: guideSize,
          height: guideSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: guideThickness),
              left: BorderSide(color: Colors.white, width: guideThickness),
            ),
          ),
        ),
      ),
      // 우하단
      Positioned(
        bottom: -guideThickness,
        right: -guideThickness,
        child: Container(
          width: guideSize,
          height: guideSize,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white, width: guideThickness),
              right: BorderSide(color: Colors.white, width: guideThickness),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white54),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _applyAdjustment() async {
    try {
      print('=== 이미지 조정 완료 - 데이터 수집 시작 ===');
      
      // 현재 변환 정보를 정확히 전달
      final Matrix4 currentMatrix = _transformationController.value;
      final double finalScale = currentMatrix.getMaxScaleOnAxis();
      
      // Matrix4에서 직접 translation 값 추출
      final double translateX = currentMatrix[12];
      final double translateY = currentMatrix[13];
      final Offset finalOffset = Offset(translateX, translateY);
      
      // 화면 크기 정보 계산 (더 정확한 변환을 위해)
      final RenderBox? renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox?;
      final Size? screenSize = renderBox?.size;
      
      // 실제 템플릿 가이드라인 크기 계산
      double guideWidth = 300; // 기본값
      double guideHeight = 300 / widget.template.aspectRatio;
      
      if (screenSize != null) {
        // 화면 크기에서 가이드라인 크기 계산 (패딩 고려)
        final availableWidth = screenSize.width - 40; // 좌우 패딩
        final availableHeight = screenSize.height - 200; // 상하 여백
        
        if (availableWidth / widget.template.aspectRatio <= availableHeight) {
          guideWidth = availableWidth;
          guideHeight = availableWidth / widget.template.aspectRatio;
        } else {
          guideHeight = availableHeight;
          guideWidth = availableHeight * widget.template.aspectRatio;
        }
      }
      
      // 이미지 원본 크기 정보 (중요!)
      Size? originalImageSize = _imageSize;
      
      print('=== 변환 정보 로그 ===');
      print('최종 Scale: $finalScale');
      print('최종 Offset: $finalOffset');
      print('화면 크기: $screenSize');
      print('가이드라인 크기: ${Size(guideWidth, guideHeight)}');
      print('원본 이미지 크기: $originalImageSize');
      print('템플릿 비율: ${widget.template.aspectRatio}');
      print('=========================');
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TemplateEditorScreen(
            template: widget.template,
            userImage: widget.userImage,
            initialScale: finalScale,
            initialOffset: finalOffset,
            initialRotation: _rotation,
            // 추가 정보 전달 (확장성 고려)
            guideSize: Size(guideWidth, guideHeight),
            screenSize: screenSize,
            originalImageSize: originalImageSize,
          ),
        ),
      );
    } catch (e) {
      print('이미지 조정 적용 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('조정 적용 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTemplateIcon() {
    // TemplateCategory에서 해당 template의 카테고리를 찾아서 icon 반환
    for (final category in TemplateCategory.categories) {
      if (category.id == widget.template.categoryId) {
        return category.icon;
      }
    }
    // 기본 아이콘
    return '🖼️';
  }
} 