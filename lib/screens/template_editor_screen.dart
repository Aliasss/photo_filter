import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/template.dart';
import '../widgets/custom_button.dart';
import 'dart:math' as math;

class TemplateEditorScreen extends StatefulWidget {
  final Template template;
  final XFile userImage;
  final double? initialScale;
  final Offset? initialOffset;
  final double? initialRotation;
  final Size? guideSize; // 이미지 조정 화면의 가이드라인 크기
  final Size? screenSize; // 이미지 조정 화면의 전체 크기
  final Size? originalImageSize; // 원본 이미지 크기

  const TemplateEditorScreen({
    Key? key,
    required this.template,
    required this.userImage,
    this.initialScale,
    this.initialOffset,
    this.initialRotation,
    this.guideSize,
    this.screenSize,
    this.originalImageSize,
  }) : super(key: key);

  @override
  _TemplateEditorScreenState createState() => _TemplateEditorScreenState();
}

class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
  dynamic _processedImage; // 처리된 사용자 이미지
  String _overlayText = '여기에 텍스트 입력';
  bool _isSaving = false;
  final GlobalKey _templateKey = GlobalKey(); // RepaintBoundary 키
  late double _templateWidth;
  late double _templateHeight;
  late TextEditingController _textController; // 텍스트 컨트롤러 추가

  @override
  void initState() {
    super.initState();
    
    print('=== 템플릿 편집 화면 초기화 시작 ===');
    print('템플릿 ID: ${widget.template.id}');
    print('템플릿 이름: ${widget.template.name}');
    print('템플릿 비율: ${widget.template.aspectRatio}');
    print('템플릿 요소 개수: ${widget.template.elements.length}');
    
    _templateWidth = widget.template.layout.width;
    _templateHeight = widget.template.layout.height;
    
    // 템플릿에 따라 기본 텍스트 설정
    if (widget.template.categoryId == 'instagram_story') {
      _overlayText = '나만의 스토리';
    } else if (widget.template.categoryId == 'business_card') {
      _overlayText = '비즈니스 정보';
    } else {
      _overlayText = '텍스트를 입력하세요';
    }
    
    // 텍스트 컨트롤러 초기화
    _textController = TextEditingController(text: _overlayText);
    
    print('=== 전달받은 이미지 조정 데이터 ===');
    print('Scale: ${widget.initialScale}');
    print('Offset: ${widget.initialOffset}');
    print('Rotation: ${widget.initialRotation}');
    print('가이드 크기: ${widget.guideSize}');
    print('화면 크기: ${widget.screenSize}');
    print('원본 이미지 크기: ${widget.originalImageSize}');
    
    // 템플릿 요소별 정보 출력
    for (int i = 0; i < widget.template.elements.length; i++) {
      final element = widget.template.elements[i];
      print('요소 $i: ${element.type}, bounds: ${element.bounds}, style: ${element.style}');
    }
    print('=====================================');
    
    _loadUserImage();
  }

  @override
  void dispose() {
    _textController.dispose(); // 컨트롤러 메모리 해제
    super.dispose();
  }

  Future<void> _loadUserImage() async {
    try {
      print('사용자 이미지 로드 시작');
      if (kIsWeb) {
        final bytes = await widget.userImage.readAsBytes();
        print('웹 이미지 로드 완료: ${bytes.length} bytes');
        setState(() {
          _processedImage = bytes;
        });
      } else {
        print('모바일 이미지 로드: ${widget.userImage.path}');
        setState(() {
          _processedImage = File(widget.userImage.path);
        });
      }
      print('이미지 로드 성공');
    } catch (e) {
      print('이미지 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 로드 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('템플릿 편집', style: AppTextStyles.sectionTitle),
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
            onPressed: _isSaving ? null : _saveTemplate,
          ),
        ],
      ),
      body: Column(
        children: [
          // 템플릿 정보
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.image, color: AppColors.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.template.name, style: AppTextStyles.sectionTitle),
                      const SizedBox(height: 4),
                      Text(widget.template.description, style: AppTextStyles.categoryDesc),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 템플릿 미리보기
          Expanded(
            child: Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildTemplatePreview(),
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
                // 텍스트 오버레이 편집 (텍스트 영역이 있는 경우만)
                if (_hasTextOverlay()) ...[
                  Text('텍스트 편집', style: AppTextStyles.sectionTitle),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '오버레이 텍스트',
                      hintText: '여기에 텍스트를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    controller: _textController, // State 변수로 변경
                    onChanged: (value) {
                      setState(() {
                        _overlayText = value.isEmpty ? '텍스트를 입력하세요' : value;
                      });
                    },
                    maxLength: 50,
                  ),
                  const SizedBox(height: 16),
                ],

                // 저장 버튼
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: '이미지 변경',
                        isOutlined: true,
                        icon: Icons.image,
                        onPressed: _changeImage,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: '저장',
                        icon: Icons.save,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? () {} : _saveTemplate,
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

  Widget _buildTemplatePreview() {
    if (_processedImage == null) {
      return Container(
        width: 300,
        height: 300 / widget.template.aspectRatio,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return RepaintBoundary(
      key: _templateKey,
      child: AspectRatio(
        aspectRatio: widget.template.aspectRatio,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: _getBackgroundColor(widget.template.layout.background),
            gradient: _getBackgroundGradient(widget.template.layout.background),
          ),
          child: Stack(
            children: widget.template.elements.map((element) {
              return _buildTemplateElement(element);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateElement(TemplateElement element) {
    final bounds = element.bounds;
    
    return Positioned(
      left: bounds.left * 300,
      top: bounds.top * (300 / widget.template.aspectRatio),
      width: bounds.width * 300,
      height: bounds.height * (300 / widget.template.aspectRatio),
      child: _buildElementWidget(element),
    );
  }

  Widget _buildElementWidget(TemplateElement element) {
    switch (element.type) {
      case TemplateElementType.userImage:
        return _buildUserImageWidget(element);
      
      case TemplateElementType.textOverlay:
        return _buildTextOverlayWidget(element);
      
      default:
        return Container();
    }
  }

  Widget _buildUserImageWidget(TemplateElement element) {
    final style = element.style;
    final isCircle = style != null && style['shape'] == 'circle';
    final borderRadius = _getBorderRadius(style);
    final border = _getBorder(style);

    print('=== 템플릿 이미지 위젯 생성 시작 ===');
    print('템플릿 ID: ${widget.template.id}');
    print('요소 bounds: ${element.bounds}');
    print('원형 여부: $isCircle');

    // 템플릿 미리보기 크기 계산 (함수 시작 부분에서 미리 계산)
    const double templatePreviewWidth = 300.0;
    final double templatePreviewHeight = templatePreviewWidth / widget.template.aspectRatio;
    
    // 템플릿 요소의 실제 픽셀 크기 계산 (전체 함수에서 사용)
    final elementPixelLeft = element.bounds.left * templatePreviewWidth;
    final elementPixelTop = element.bounds.top * templatePreviewHeight;
    final elementPixelWidth = element.bounds.width * templatePreviewWidth;
    final elementPixelHeight = element.bounds.height * templatePreviewHeight;

    Widget imageWidget;

    // 이미지 조정 변환 적용 - 상대적 위치 기반 변환
    if (widget.initialScale != null || widget.initialOffset != null) {
      final originalScale = widget.initialScale ?? 1.0;
      final offset = widget.initialOffset ?? Offset.zero;
      final rotation = widget.initialRotation ?? 0.0;
      
      // 🔥 스케일 비율 변환 수정 (핵심 수정 부분)
      double adjustedScale = originalScale;
      if (widget.guideSize != null) {
        // 가이드라인 대비 템플릿 요소의 크기 비율 계산
        final scaleRatio = widget.guideSize!.width / elementPixelWidth;
        adjustedScale = originalScale * scaleRatio;
        
        // 🔥 최소 스케일 보장 (이미지가 템플릿 영역을 완전히 덮도록)
        final minScaleX = elementPixelWidth / elementPixelWidth; // 1.0
        final minScaleY = elementPixelHeight / elementPixelHeight; // 1.0
        final minScale = math.max(minScaleX, minScaleY); // 1.0
        
        // 조정된 스케일이 최소 스케일보다 작으면 최소 스케일 사용
        if (adjustedScale < minScale) {
          adjustedScale = minScale;
          print('=== 최소 스케일 적용 ===');
          print('계산된 스케일: ${originalScale * scaleRatio}');
          print('최소 스케일: $minScale');
          print('최종 적용 스케일: $adjustedScale');
        }
        
        print('=== 스케일 변환 (수정됨) ===');
        print('원본 스케일: $originalScale');
        print('가이드 크기: ${widget.guideSize!.width}');
        print('요소 크기: $elementPixelWidth');
        print('비율 (가이드/요소): $scaleRatio');
        print('조정된 스케일: $adjustedScale');
      }
      
      final scale = adjustedScale;
      
      print('=== 변환 정보 수신 ===');
      print('최종 Scale: $scale');
      print('Offset: $offset');
      print('Rotation: $rotation');
      print('가이드 크기: ${widget.guideSize}');
      
      print('=== 템플릿 미리보기 크기 ===');
      print('미리보기 폭: $templatePreviewWidth');
      print('미리보기 높이: $templatePreviewHeight');
      
      print('=== 템플릿 요소 실제 크기 ===');
      print('요소 left: $elementPixelLeft px');
      print('요소 top: $elementPixelTop px');
      print('요소 width: $elementPixelWidth px');
      print('요소 height: $elementPixelHeight px');
      
      // 상대적 위치 계산 (올바른 방식)
      double relativeX = 0.5; // 기본값: 중앙
      double relativeY = 0.5; // 기본값: 중앙
      
      if (widget.guideSize != null) {
        // 가이드라인 중심을 기준으로 상대적 위치 계산 (0~1 범위)
        relativeX = (offset.dx + widget.guideSize!.width / 2) / widget.guideSize!.width;
        relativeY = (offset.dy + widget.guideSize!.height / 2) / widget.guideSize!.height;
        
        // 0~1 범위로 클램핑
        relativeX = relativeX.clamp(0.0, 1.0);
        relativeY = relativeY.clamp(0.0, 1.0);
        
        print('=== 상대적 위치 계산 ===');
        print('가이드 중심 기준 계산:');
        print('  X: (${offset.dx} + ${widget.guideSize!.width / 2}) / ${widget.guideSize!.width} = $relativeX');
        print('  Y: (${offset.dy} + ${widget.guideSize!.height / 2}) / ${widget.guideSize!.height} = $relativeY');
      }
      
      
      // 스케일 적용된 이미지 크기
      final scaledImageWidth = elementPixelWidth * scale;
      final scaledImageHeight = elementPixelHeight * scale;
      
      print('=== 스케일된 이미지 크기 계산 ===');
      print('원본 요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
      print('최종 스케일: $scale');
      print('스케일된 크기: (${scaledImageWidth}, ${scaledImageHeight})');
      
      // 템플릿 요소의 경계 계산
      final elementPixelRight = elementPixelLeft + elementPixelWidth;
      final elementPixelBottom = elementPixelTop + elementPixelHeight;
      final elementCenterX = elementPixelLeft + elementPixelWidth / 2;
      final elementCenterY = elementPixelTop + elementPixelHeight / 2;
      
      print('=== 템플릿 요소 경계 정보 ===');
      print('요소 left: $elementPixelLeft, right: $elementPixelRight');
      print('요소 top: $elementPixelTop, bottom: $elementPixelBottom');
      print('요소 중심: ($elementCenterX, $elementCenterY)');
      
      // 중심점 허용 범위 계산 (이미지가 템플릿 요소를 충분히 덮도록)
      double minCenterX, maxCenterX, minCenterY, maxCenterY;
      
      // 이미지가 요소를 완전히 덮을 수 있는 중심점의 최대 이동 범위 계산
      final maxMoveX = math.max(0.0, (scaledImageWidth - elementPixelWidth) / 2);
      final maxMoveY = math.max(0.0, (scaledImageHeight - elementPixelHeight) / 2);
      
      minCenterX = elementCenterX - maxMoveX;
      maxCenterX = elementCenterX + maxMoveX;
      minCenterY = elementCenterY - maxMoveY;
      maxCenterY = elementCenterY + maxMoveY;
      
      print('=== 허용 범위 계산 (개선됨) ===');
      print('이미지 크기: (${scaledImageWidth}, ${scaledImageHeight})');
      print('요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
      print('최대 이동 거리: X=$maxMoveX, Y=$maxMoveY');
      print('중심점 허용 범위: X($minCenterX ~ $maxCenterX), Y($minCenterY ~ $maxCenterY)');
      
      // 유효성 검사
      final isValidX = minCenterX.isFinite && maxCenterX.isFinite && minCenterX <= maxCenterX;
      final isValidY = minCenterY.isFinite && maxCenterY.isFinite && minCenterY <= maxCenterY;
      
      print('=== 유효성 검사 ===');
      print('X 범위 유효성: $isValidX (min: $minCenterX, max: $maxCenterX)');
      print('Y 범위 유효성: $isValidY (min: $minCenterY, max: $maxCenterY)');
      
      // 상대적 위치를 허용 범위 내에서 직접 계산
      double actualCenterX, actualCenterY;
      
      if (isValidX && maxCenterX > minCenterX) {
        // 상대적 위치를 허용 범위에 직접 매핑
        actualCenterX = minCenterX + relativeX * (maxCenterX - minCenterX);
      } else {
        // 범위가 유효하지 않거나 범위가 없는 경우 요소 중심 사용
        actualCenterX = elementCenterX;
        print('경고: X 범위가 유효하지 않아 요소 중심점 사용');
      }
      
      if (isValidY && maxCenterY > minCenterY) {
        // 상대적 위치를 허용 범위에 직접 매핑
        actualCenterY = minCenterY + relativeY * (maxCenterY - minCenterY);
      } else {
        // 범위가 유효하지 않거나 범위가 없는 경우 요소 중심 사용
        actualCenterY = elementCenterY;
        print('경고: Y 범위가 유효하지 않아 요소 중심점 사용');
      }
      
      // 이미지 중심을 기준으로 위치 조정
      final centeredX = actualCenterX - scaledImageWidth / 2;
      final centeredY = actualCenterY - scaledImageHeight / 2;
      
      print('=== 최종 위치 계산 ===');
      print('상대적 위치: ($relativeX, $relativeY)');
      print('중심점 허용 범위: X($minCenterX ~ $maxCenterX), Y($minCenterY ~ $maxCenterY)');
      print('최종 중심점: ($actualCenterX, $actualCenterY)');
      print('스케일된 크기: (${scaledImageWidth}, ${scaledImageHeight})');
      print('최종 위치 (좌상단): ($centeredX, $centeredY)');
      print('최종 경계: left=$centeredX, top=$centeredY, right=${centeredX + scaledImageWidth}, bottom=${centeredY + scaledImageHeight}');
      print('템플릿 요소 경계: left=$elementPixelLeft, top=$elementPixelTop, right=$elementPixelRight, bottom=$elementPixelBottom');
      
      // 템플릿 요소 커버리지 확인 (이미지가 요소를 충분히 덮는지)
      final imageLeft = centeredX;
      final imageTop = centeredY;
      final imageRight = centeredX + scaledImageWidth;
      final imageBottom = centeredY + scaledImageHeight;
      
      final coversLeft = imageLeft <= elementPixelLeft;
      final coversTop = imageTop <= elementPixelTop;
      final coversRight = imageRight >= elementPixelRight;
      final coversBottom = imageBottom >= elementPixelBottom;
      final fullyCovered = coversLeft && coversTop && coversRight && coversBottom;
      
      print('=== 템플릿 요소 커버리지 검사 ===');
      print('이미지 경계: left=$imageLeft, top=$imageTop, right=$imageRight, bottom=$imageBottom');
      print('커버리지: left=$coversLeft, top=$coversTop, right=$coversRight, bottom=$coversBottom');
      print('완전 커버 여부: $fullyCovered');
      
      // 이미지가 템플릿 영역 내에 완전 포함되는지 확인 (작은 이미지의 경우)
      final withinLeft = imageLeft >= elementPixelLeft;
      final withinTop = imageTop >= elementPixelTop;
      final withinRight = imageRight <= elementPixelRight;
      final withinBottom = imageBottom <= elementPixelBottom;
      final fullyWithin = withinLeft && withinTop && withinRight && withinBottom;
      
      print('=== 템플릿 영역 내 포함 검사 ===');
      print('영역 내 포함: left=$withinLeft, top=$withinTop, right=$withinRight, bottom=$withinBottom');
      print('완전 포함 여부: $fullyWithin');
      
      // 이미지 위젯 생성 - Stack + Positioned 방식 (클리핑 강화)
      imageWidget = ClipRect(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            clipBehavior: Clip.hardEdge, // 영역 밖은 잘라냄
            children: [
              Positioned(
                left: centeredX,
                top: centeredY,
                width: scaledImageWidth,
                height: scaledImageHeight,
                child: Transform.rotate(
                  angle: rotation,
                  child: kIsWeb
                    ? Image.memory(
                        _processedImage as Uint8List,
                        fit: BoxFit.cover,
                        width: scaledImageWidth,
                        height: scaledImageHeight,
                      )
                    : Image.file(
                        _processedImage as File,
                        fit: BoxFit.cover,
                        width: scaledImageWidth,
                        height: scaledImageHeight,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      print('변환 정보 없음 - 기본 이미지 사용');
      // 변환 정보가 없는 경우 기본 이미지
      imageWidget = kIsWeb
        ? Image.memory(
            _processedImage as Uint8List,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          )
        : Image.file(
            _processedImage as File,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
    }

    // 모양 적용 (원형 또는 둥근 모서리)
    print('=== 모양 적용 시작 ===');
    print('원형 여부: $isCircle');
    
    if (isCircle) {
      print('=== 원형 클리핑 계산 ===');
      print('템플릿 요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
      
      // 원형 클리핑 적용
      try {
        imageWidget = ClipOval(child: imageWidget);
        print('원형 클리핑 성공적으로 적용');
      } catch (e) {
        print('원형 클리핑 오류: $e');
        // 오류 발생 시 기본 사각형 클리핑 사용
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: imageWidget,
        );
        print('기본 사각형 클리핑으로 대체');
      }
    } else {
      print('=== 사각형 클리핑 계산 ===');
      final borderRadiusValue = _getBorderRadius(style);
      print('BorderRadius: $borderRadiusValue');
      
      try {
        imageWidget = ClipRRect(
          borderRadius: borderRadiusValue,
          child: imageWidget,
        );
        print('사각형 클리핑 성공적으로 적용');
      } catch (e) {
        print('사각형 클리핑 오류: $e');
        // 오류 발생 시 기본 클리핑 사용
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: imageWidget,
        );
        print('기본 클리핑으로 대체');
      }
    }

    print('=== 템플릿 이미지 위젯 생성 완료 ===');

    return Container(
      decoration: BoxDecoration(
        borderRadius: isCircle ? null : borderRadius,
        border: border,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: imageWidget,
    );
  }

  Widget _buildTextOverlayWidget(TemplateElement element) {
    final style = element.style;
    final textColor = _getTextColor(style);
    final backgroundColor = _getTextBackgroundColor(style);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text(
          _overlayText,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Color _getBackgroundColor(TemplateBackground background) {
    if (background.type == TemplateBackgroundType.color) {
      final colorString = background.value as String;
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    }
    return Colors.white;
  }

  Gradient? _getBackgroundGradient(TemplateBackground background) {
    if (background.type == TemplateBackgroundType.gradient) {
      final colors = background.value as List<String>;
      return LinearGradient(
        colors: colors.map((color) => 
          Color(int.parse(color.replaceFirst('#', '0xff')))
        ).toList(),
      );
    }
    return null;
  }

  BorderRadius _getBorderRadius(dynamic style) {
    try {
      if (style != null && style['shape'] == 'circle') {
        // 원형의 경우 큰 값 사용 (하지만 안전한 범위 내)
        return BorderRadius.circular(500);
      } else if (style != null && style['borderRadius'] != null) {
        final radiusValue = style['borderRadius'];
        if (radiusValue is num && radiusValue.isFinite && radiusValue >= 0) {
          return BorderRadius.circular(radiusValue.toDouble());
        }
      }
    } catch (e) {
      print('BorderRadius 계산 오류: $e');
    }
    
    // 기본값: 모서리 없음
    return BorderRadius.circular(0);
  }

  BoxBorder? _getBorder(dynamic style) {
    if (style != null && style['borderWidth'] != null) {
      final borderColor = style['borderColor'] != null
        ? Color(int.parse(style['borderColor'].replaceFirst('#', '0xff')))
        : AppColors.border;
      return Border.all(
        color: borderColor,
        width: (style['borderWidth'] as int).toDouble(),
      );
    }
    return null;
  }

  Color _getTextBackgroundColor(dynamic style) {
    if (style != null && style['backgroundColor'] != null) {
      final colorString = style['backgroundColor'] as String;
      if (colorString.startsWith('rgba')) {
        return Colors.black.withOpacity(0.5);
      }
    }
    return Colors.transparent;
  }

  Color _getTextColor(dynamic style) {
    if (style != null && style['textColor'] != null) {
      final colorString = style['textColor'] as String;
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    }
    return AppColors.textPrimary;
  }

  bool _hasTextOverlay() {
    return widget.template.elements.any(
      (element) => element.type == TemplateElementType.textOverlay,
    );
  }

  Future<void> _changeImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _processedImage = bytes;
          });
        } else {
          setState(() {
            _processedImage = File(image.path);
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 변경 중 오류가 발생했습니다: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveTemplate() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // 템플릿 캡처
      RenderRepaintBoundary boundary = _templateKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        throw Exception('템플릿 캡처 실패');
      }

      final Uint8List imageBytes = byteData.buffer.asUint8List();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'template_${widget.template.name}_$timestamp.png';

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
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
                Text('템플릿이 갤러리에 저장되었습니다.'),
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


// import 'dart:io';
// import 'dart:typed_data';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/rendering.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:intl/intl.dart';
// import '../constants/colors.dart';
// import '../constants/text_styles.dart';
// import '../models/template.dart';
// import '../widgets/custom_button.dart';
// import 'dart:math' as math;

// class TemplateEditorScreen extends StatefulWidget {
//   final Template template;
//   final XFile userImage;
//   final double? initialScale;
//   final Offset? initialOffset;
//   final double? initialRotation;
//   final Size? guideSize; // 이미지 조정 화면의 가이드라인 크기
//   final Size? screenSize; // 이미지 조정 화면의 전체 크기
//   final Size? originalImageSize; // 원본 이미지 크기

//   const TemplateEditorScreen({
//     Key? key,
//     required this.template,
//     required this.userImage,
//     this.initialScale,
//     this.initialOffset,
//     this.initialRotation,
//     this.guideSize,
//     this.screenSize,
//     this.originalImageSize,
//   }) : super(key: key);

//   @override
//   _TemplateEditorScreenState createState() => _TemplateEditorScreenState();
// }

// class _TemplateEditorScreenState extends State<TemplateEditorScreen> {
//   dynamic _processedImage; // 처리된 사용자 이미지
//   String _overlayText = '여기에 텍스트 입력';
//   bool _isSaving = false;
//   final GlobalKey _templateKey = GlobalKey(); // RepaintBoundary 키
//   late double _templateWidth;
//   late double _templateHeight;
//   late TextEditingController _textController; // 텍스트 컨트롤러 추가

//   @override
//   void initState() {
//     super.initState();
    
//     print('=== 템플릿 편집 화면 초기화 시작 ===');
//     print('템플릿 ID: ${widget.template.id}');
//     print('템플릿 이름: ${widget.template.name}');
//     print('템플릿 비율: ${widget.template.aspectRatio}');
//     print('템플릿 요소 개수: ${widget.template.elements.length}');
    
//     _templateWidth = widget.template.layout.width;
//     _templateHeight = widget.template.layout.height;
    
//     // 템플릿에 따라 기본 텍스트 설정
//     if (widget.template.categoryId == 'instagram_story') {
//       _overlayText = '나만의 스토리';
//     } else if (widget.template.categoryId == 'business_card') {
//       _overlayText = '비즈니스 정보';
//     } else {
//       _overlayText = '텍스트를 입력하세요';
//     }
    
//     // 텍스트 컨트롤러 초기화
//     _textController = TextEditingController(text: _overlayText);
    
//     print('=== 전달받은 이미지 조정 데이터 ===');
//     print('Scale: ${widget.initialScale}');
//     print('Offset: ${widget.initialOffset}');
//     print('Rotation: ${widget.initialRotation}');
//     print('가이드 크기: ${widget.guideSize}');
//     print('화면 크기: ${widget.screenSize}');
//     print('원본 이미지 크기: ${widget.originalImageSize}');
    
//     // 템플릿 요소별 정보 출력
//     for (int i = 0; i < widget.template.elements.length; i++) {
//       final element = widget.template.elements[i];
//       print('요소 $i: ${element.type}, bounds: ${element.bounds}, style: ${element.style}');
//     }
//     print('=====================================');
    
//     _loadUserImage();
//   }

//   @override
//   void dispose() {
//     _textController.dispose(); // 컨트롤러 메모리 해제
//     super.dispose();
//   }

//   Future<void> _loadUserImage() async {
//     try {
//       print('사용자 이미지 로드 시작');
//       if (kIsWeb) {
//         final bytes = await widget.userImage.readAsBytes();
//         print('웹 이미지 로드 완료: ${bytes.length} bytes');
//         setState(() {
//           _processedImage = bytes;
//         });
//       } else {
//         print('모바일 이미지 로드: ${widget.userImage.path}');
//         setState(() {
//           _processedImage = File(widget.userImage.path);
//         });
//       }
//       print('이미지 로드 성공');
//     } catch (e) {
//       print('이미지 로드 오류: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('이미지 로드 중 오류가 발생했습니다.'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppBar(
//         backgroundColor: AppColors.surface,
//         elevation: 0,
//         title: Text('템플릿 편집', style: AppTextStyles.sectionTitle),
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: _isSaving
//               ? const SizedBox(
//                   width: 20,
//                   height: 20,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//               : Icon(Icons.save, color: AppColors.primary),
//             onPressed: _isSaving ? null : _saveTemplate,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // 템플릿 정보
//           Container(
//             padding: const EdgeInsets.all(16),
//             margin: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: AppColors.border),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.image, color: AppColors.primary, size: 24),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(widget.template.name, style: AppTextStyles.sectionTitle),
//                       const SizedBox(height: 4),
//                       Text(widget.template.description, style: AppTextStyles.categoryDesc),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // 템플릿 미리보기
//           Expanded(
//             child: Center(
//               child: Container(
//                 margin: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: AppColors.surface,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: AppColors.border),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 20,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(12),
//                   child: _buildTemplatePreview(),
//                 ),
//               ),
//             ),
//           ),

//           // 편집 컨트롤 영역
//           Container(
//             padding: const EdgeInsets.all(20),
//             decoration: BoxDecoration(
//               color: AppColors.surface,
//               borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 // 텍스트 오버레이 편집 (텍스트 영역이 있는 경우만)
//                 if (_hasTextOverlay()) ...[
//                   Text('텍스트 편집', style: AppTextStyles.sectionTitle),
//                   const SizedBox(height: 12),
//                   TextField(
//                     decoration: InputDecoration(
//                       labelText: '오버레이 텍스트',
//                       hintText: '여기에 텍스트를 입력하세요',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 16,
//                       ),
//                     ),
//                     controller: _textController, // State 변수로 변경
//                     onChanged: (value) {
//                       setState(() {
//                         _overlayText = value.isEmpty ? '텍스트를 입력하세요' : value;
//                       });
//                     },
//                     maxLength: 50,
//                   ),
//                   const SizedBox(height: 16),
//                 ],

//                 // 저장 버튼
//                 Row(
//                   children: [
//                     Expanded(
//                       child: CustomButton(
//                         text: '이미지 변경',
//                         isOutlined: true,
//                         icon: Icons.image,
//                         onPressed: _changeImage,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: CustomButton(
//                         text: '저장',
//                         icon: Icons.save,
//                         isLoading: _isSaving,
//                         onPressed: _isSaving ? () {} : _saveTemplate,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTemplatePreview() {
//     if (_processedImage == null) {
//       return Container(
//         width: 300,
//         height: 300 / widget.template.aspectRatio,
//         child: const Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return RepaintBoundary(
//       key: _templateKey,
//       child: AspectRatio(
//         aspectRatio: widget.template.aspectRatio,
//         child: Container(
//           width: 300,
//           decoration: BoxDecoration(
//             color: _getBackgroundColor(widget.template.layout.background),
//             gradient: _getBackgroundGradient(widget.template.layout.background),
//           ),
//           child: Stack(
//             children: widget.template.elements.map((element) {
//               return _buildTemplateElement(element);
//             }).toList(),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTemplateElement(TemplateElement element) {
//     final bounds = element.bounds;
    
//     return Positioned(
//       left: bounds.left * 300,
//       top: bounds.top * (300 / widget.template.aspectRatio),
//       width: bounds.width * 300,
//       height: bounds.height * (300 / widget.template.aspectRatio),
//       child: _buildElementWidget(element),
//     );
//   }

//   Widget _buildElementWidget(TemplateElement element) {
//     switch (element.type) {
//       case TemplateElementType.userImage:
//         return _buildUserImageWidget(element);
      
//       case TemplateElementType.textOverlay:
//         return _buildTextOverlayWidget(element);
      
//       default:
//         return Container();
//     }
//   }

//   Widget _buildUserImageWidget(TemplateElement element) {
//     final style = element.style;
//     final isCircle = style != null && style['shape'] == 'circle';
//     final borderRadius = _getBorderRadius(style);
//     final border = _getBorder(style);

//     print('=== 템플릿 이미지 위젯 생성 시작 ===');
//     print('템플릿 ID: ${widget.template.id}');
//     print('요소 bounds: ${element.bounds}');
//     print('원형 여부: $isCircle');

//     // 템플릿 미리보기 크기 계산 (함수 시작 부분에서 미리 계산)
//     const double templatePreviewWidth = 300.0;
//     final double templatePreviewHeight = templatePreviewWidth / widget.template.aspectRatio;
    
//     // 템플릿 요소의 실제 픽셀 크기 계산 (전체 함수에서 사용)
//     final elementPixelLeft = element.bounds.left * templatePreviewWidth;
//     final elementPixelTop = element.bounds.top * templatePreviewHeight;
//     final elementPixelWidth = element.bounds.width * templatePreviewWidth;
//     final elementPixelHeight = element.bounds.height * templatePreviewHeight;

//     Widget imageWidget;

//     // 이미지 조정 변환 적용 - 상대적 위치 기반 변환
//     if (widget.initialScale != null || widget.initialOffset != null) {
//       final originalScale = widget.initialScale ?? 1.0;
//       final offset = widget.initialOffset ?? Offset.zero;
//       final rotation = widget.initialRotation ?? 0.0;
      
//       // 스케일 비율 변환 추가
//       double adjustedScale = originalScale;
//       if (widget.guideSize != null) {
//         // 가이드라인 대비 템플릿 요소의 크기 비율 계산
//         final scaleRatio = elementPixelWidth / widget.guideSize!.width;
//         adjustedScale = originalScale * scaleRatio;
        
//         print('=== 스케일 변환 ===');
//         print('원본 스케일: $originalScale');
//         print('비율: $scaleRatio');
//         print('조정된 스케일: $adjustedScale');
//       }
      
//       final scale = adjustedScale;
      
//       print('=== 변환 정보 수신 ===');
//       print('Scale: $scale');
//       print('Offset: $offset');
//       print('Rotation: $rotation');
//       print('가이드 크기: ${widget.guideSize}');
      
//       print('=== 템플릿 미리보기 크기 ===');
//       print('미리보기 폭: $templatePreviewWidth');
//       print('미리보기 높이: $templatePreviewHeight');
      
//       print('=== 템플릿 요소 실제 크기 ===');
//       print('요소 left: $elementPixelLeft px');
//       print('요소 top: $elementPixelTop px');
//       print('요소 width: $elementPixelWidth px');
//       print('요소 height: $elementPixelHeight px');
      
//       // 상대적 위치 계산 (올바른 방식)
//       double relativeX = 0.5; // 기본값: 중앙
//       double relativeY = 0.5; // 기본값: 중앙
      
//       if (widget.guideSize != null) {
//         // 가이드라인 중심을 기준으로 상대적 위치 계산 (0~1 범위)
//         relativeX = (offset.dx + widget.guideSize!.width / 2) / widget.guideSize!.width;
//         relativeY = (offset.dy + widget.guideSize!.height / 2) / widget.guideSize!.height;
        
//         // 0~1 범위로 클램핑
//         relativeX = relativeX.clamp(0.0, 1.0);
//         relativeY = relativeY.clamp(0.0, 1.0);
        
//         print('=== 상대적 위치 계산 ===');
//         print('가이드 중심 기준 계산:');
//         print('  X: (${offset.dx} + ${widget.guideSize!.width / 2}) / ${widget.guideSize!.width} = $relativeX');
//         print('  Y: (${offset.dy} + ${widget.guideSize!.height / 2}) / ${widget.guideSize!.height} = $relativeY');
//       }
      
      
//       // 스케일 적용된 이미지 크기
//       final scaledImageWidth = elementPixelWidth * scale;
//       final scaledImageHeight = elementPixelHeight * scale;
      
//       print('=== 스케일된 이미지 크기 계산 ===');
//       print('원본 요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
//       print('스케일: $scale');
//       print('스케일된 크기: (${scaledImageWidth}, ${scaledImageHeight})');
      
//       // 템플릿 요소의 경계 계산
//       final elementPixelRight = elementPixelLeft + elementPixelWidth;
//       final elementPixelBottom = elementPixelTop + elementPixelHeight;
//       final elementCenterX = elementPixelLeft + elementPixelWidth / 2;
//       final elementCenterY = elementPixelTop + elementPixelHeight / 2;
      
//       print('=== 템플릿 요소 경계 정보 ===');
//       print('요소 left: $elementPixelLeft, right: $elementPixelRight');
//       print('요소 top: $elementPixelTop, bottom: $elementPixelBottom');
//       print('요소 중심: ($elementCenterX, $elementCenterY)');
      
//       // 중심점 허용 범위 계산 (이미지가 템플릿 요소를 충분히 덮도록)
//       double minCenterX, maxCenterX, minCenterY, maxCenterY;
      
//       // 이미지가 요소를 완전히 덮을 수 있는 중심점의 최대 이동 범위 계산
//       final maxMoveX = math.max(0.0, (scaledImageWidth - elementPixelWidth) / 2);
//       final maxMoveY = math.max(0.0, (scaledImageHeight - elementPixelHeight) / 2);
      
//       minCenterX = elementCenterX - maxMoveX;
//       maxCenterX = elementCenterX + maxMoveX;
//       minCenterY = elementCenterY - maxMoveY;
//       maxCenterY = elementCenterY + maxMoveY;
      
//       print('=== 허용 범위 계산 (개선됨) ===');
//       print('이미지 크기: (${scaledImageWidth}, ${scaledImageHeight})');
//       print('요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
//       print('최대 이동 거리: X=$maxMoveX, Y=$maxMoveY');
//       print('중심점 허용 범위: X($minCenterX ~ $maxCenterX), Y($minCenterY ~ $maxCenterY)');
      
//       // 유효성 검사
//       final isValidX = minCenterX.isFinite && maxCenterX.isFinite && minCenterX <= maxCenterX;
//       final isValidY = minCenterY.isFinite && maxCenterY.isFinite && minCenterY <= maxCenterY;
      
//       print('=== 유효성 검사 ===');
//       print('X 범위 유효성: $isValidX (min: $minCenterX, max: $maxCenterX)');
//       print('Y 범위 유효성: $isValidY (min: $minCenterY, max: $maxCenterY)');
      
//       // 상대적 위치를 허용 범위 내에서 직접 계산
//       double actualCenterX, actualCenterY;
      
//       if (isValidX && maxCenterX > minCenterX) {
//         // 상대적 위치를 허용 범위에 직접 매핑
//         actualCenterX = minCenterX + relativeX * (maxCenterX - minCenterX);
//       } else {
//         // 범위가 유효하지 않거나 범위가 없는 경우 요소 중심 사용
//         actualCenterX = elementCenterX;
//         print('경고: X 범위가 유효하지 않아 요소 중심점 사용');
//       }
      
//       if (isValidY && maxCenterY > minCenterY) {
//         // 상대적 위치를 허용 범위에 직접 매핑
//         actualCenterY = minCenterY + relativeY * (maxCenterY - minCenterY);
//       } else {
//         // 범위가 유효하지 않거나 범위가 없는 경우 요소 중심 사용
//         actualCenterY = elementCenterY;
//         print('경고: Y 범위가 유효하지 않아 요소 중심점 사용');
//       }
      
//       // 이미지 중심을 기준으로 위치 조정
//       final centeredX = actualCenterX - scaledImageWidth / 2;
//       final centeredY = actualCenterY - scaledImageHeight / 2;
      
//       print('=== 최종 위치 계산 ===');
//       print('상대적 위치: ($relativeX, $relativeY)');
//       print('중심점 허용 범위: X($minCenterX ~ $maxCenterX), Y($minCenterY ~ $maxCenterY)');
//       print('최종 중심점: ($actualCenterX, $actualCenterY)');
//       print('스케일된 크기: (${scaledImageWidth}, ${scaledImageHeight})');
//       print('최종 위치 (좌상단): ($centeredX, $centeredY)');
//       print('최종 경계: left=$centeredX, top=$centeredY, right=${centeredX + scaledImageWidth}, bottom=${centeredY + scaledImageHeight}');
//       print('템플릿 요소 경계: left=$elementPixelLeft, top=$elementPixelTop, right=$elementPixelRight, bottom=$elementPixelBottom');
      
//       // 템플릿 요소 커버리지 확인 (이미지가 요소를 충분히 덮는지)
//       final imageLeft = centeredX;
//       final imageTop = centeredY;
//       final imageRight = centeredX + scaledImageWidth;
//       final imageBottom = centeredY + scaledImageHeight;
      
//       final coversLeft = imageLeft <= elementPixelLeft;
//       final coversTop = imageTop <= elementPixelTop;
//       final coversRight = imageRight >= elementPixelRight;
//       final coversBottom = imageBottom >= elementPixelBottom;
//       final fullyCovered = coversLeft && coversTop && coversRight && coversBottom;
      
//       print('=== 템플릿 요소 커버리지 검사 ===');
//       print('이미지 경계: left=$imageLeft, top=$imageTop, right=$imageRight, bottom=$imageBottom');
//       print('커버리지: left=$coversLeft, top=$coversTop, right=$coversRight, bottom=$coversBottom');
//       print('완전 커버 여부: $fullyCovered');
      
//       // 이미지가 템플릿 영역 내에 완전 포함되는지 확인 (작은 이미지의 경우)
//       final withinLeft = imageLeft >= elementPixelLeft;
//       final withinTop = imageTop >= elementPixelTop;
//       final withinRight = imageRight <= elementPixelRight;
//       final withinBottom = imageBottom <= elementPixelBottom;
//       final fullyWithin = withinLeft && withinTop && withinRight && withinBottom;
      
//       print('=== 템플릿 영역 내 포함 검사 ===');
//       print('영역 내 포함: left=$withinLeft, top=$withinTop, right=$withinRight, bottom=$withinBottom');
//       print('완전 포함 여부: $fullyWithin');
      
//       // 이미지 위젯 생성 - Stack + Positioned 방식 (클리핑 강화)
//       imageWidget = ClipRect(
//         child: Container(
//           width: double.infinity,
//           height: double.infinity,
//           child: Stack(
//             clipBehavior: Clip.hardEdge, // 영역 밖은 잘라냄
//             children: [
//               Positioned(
//                 left: centeredX,
//                 top: centeredY,
//                 width: scaledImageWidth,
//                 height: scaledImageHeight,
//                 child: Transform.rotate(
//                   angle: rotation,
//                   child: kIsWeb
//                     ? Image.memory(
//                         _processedImage as Uint8List,
//                         fit: BoxFit.cover,
//                         width: scaledImageWidth,
//                         height: scaledImageHeight,
//                       )
//                     : Image.file(
//                         _processedImage as File,
//                         fit: BoxFit.cover,
//                         width: scaledImageWidth,
//                         height: scaledImageHeight,
//                       ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     } else {
//       print('변환 정보 없음 - 기본 이미지 사용');
//       // 변환 정보가 없는 경우 기본 이미지
//       imageWidget = kIsWeb
//         ? Image.memory(
//             _processedImage as Uint8List,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           )
//         : Image.file(
//             _processedImage as File,
//             fit: BoxFit.cover,
//             width: double.infinity,
//             height: double.infinity,
//           );
//     }

//     // 모양 적용 (원형 또는 둥근 모서리)
//     print('=== 모양 적용 시작 ===');
//     print('원형 여부: $isCircle');
    
//     if (isCircle) {
//       print('=== 원형 클리핑 계산 ===');
//       print('템플릿 요소 크기: (${elementPixelWidth}, ${elementPixelHeight})');
      
//       // 원형 클리핑 적용
//       try {
//         imageWidget = ClipOval(child: imageWidget);
//         print('원형 클리핑 성공적으로 적용');
//       } catch (e) {
//         print('원형 클리핑 오류: $e');
//         // 오류 발생 시 기본 사각형 클리핑 사용
//         imageWidget = ClipRRect(
//           borderRadius: BorderRadius.circular(8),
//           child: imageWidget,
//         );
//         print('기본 사각형 클리핑으로 대체');
//       }
//     } else {
//       print('=== 사각형 클리핑 계산 ===');
//       final borderRadiusValue = _getBorderRadius(style);
//       print('BorderRadius: $borderRadiusValue');
      
//       try {
//         imageWidget = ClipRRect(
//           borderRadius: borderRadiusValue,
//           child: imageWidget,
//         );
//         print('사각형 클리핑 성공적으로 적용');
//       } catch (e) {
//         print('사각형 클리핑 오류: $e');
//         // 오류 발생 시 기본 클리핑 사용
//         imageWidget = ClipRRect(
//           borderRadius: BorderRadius.circular(0),
//           child: imageWidget,
//         );
//         print('기본 클리핑으로 대체');
//       }
//     }

//     print('=== 템플릿 이미지 위젯 생성 완료 ===');

//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: isCircle ? null : borderRadius,
//         border: border,
//         shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
//       ),
//       child: imageWidget,
//     );
//   }

//   Widget _buildTextOverlayWidget(TemplateElement element) {
//     final style = element.style;
//     final textColor = _getTextColor(style);
//     final backgroundColor = _getTextBackgroundColor(style);

//     return Container(
//       decoration: BoxDecoration(
//         color: backgroundColor,
//         borderRadius: BorderRadius.circular(8),
//       ),
//       padding: const EdgeInsets.all(8),
//       child: Center(
//         child: Text(
//           _overlayText,
//           style: TextStyle(
//             color: textColor,
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//           ),
//           textAlign: TextAlign.center,
//           maxLines: 3,
//           overflow: TextOverflow.ellipsis,
//         ),
//       ),
//     );
//   }

//   Color _getBackgroundColor(TemplateBackground background) {
//     if (background.type == TemplateBackgroundType.color) {
//       final colorString = background.value as String;
//       return Color(int.parse(colorString.replaceFirst('#', '0xff')));
//     }
//     return Colors.white;
//   }

//   Gradient? _getBackgroundGradient(TemplateBackground background) {
//     if (background.type == TemplateBackgroundType.gradient) {
//       final colors = background.value as List<String>;
//       return LinearGradient(
//         colors: colors.map((color) => 
//           Color(int.parse(color.replaceFirst('#', '0xff')))
//         ).toList(),
//       );
//     }
//     return null;
//   }

//   BorderRadius _getBorderRadius(dynamic style) {
//     try {
//       if (style != null && style['shape'] == 'circle') {
//         // 원형의 경우 큰 값 사용 (하지만 안전한 범위 내)
//         return BorderRadius.circular(500);
//       } else if (style != null && style['borderRadius'] != null) {
//         final radiusValue = style['borderRadius'];
//         if (radiusValue is num && radiusValue.isFinite && radiusValue >= 0) {
//           return BorderRadius.circular(radiusValue.toDouble());
//         }
//       }
//     } catch (e) {
//       print('BorderRadius 계산 오류: $e');
//     }
    
//     // 기본값: 모서리 없음
//     return BorderRadius.circular(0);
//   }

//   BoxBorder? _getBorder(dynamic style) {
//     if (style != null && style['borderWidth'] != null) {
//       final borderColor = style['borderColor'] != null
//         ? Color(int.parse(style['borderColor'].replaceFirst('#', '0xff')))
//         : AppColors.border;
//       return Border.all(
//         color: borderColor,
//         width: (style['borderWidth'] as int).toDouble(),
//       );
//     }
//     return null;
//   }

//   Color _getTextBackgroundColor(dynamic style) {
//     if (style != null && style['backgroundColor'] != null) {
//       final colorString = style['backgroundColor'] as String;
//       if (colorString.startsWith('rgba')) {
//         return Colors.black.withOpacity(0.5);
//       }
//     }
//     return Colors.transparent;
//   }

//   Color _getTextColor(dynamic style) {
//     if (style != null && style['textColor'] != null) {
//       final colorString = style['textColor'] as String;
//       return Color(int.parse(colorString.replaceFirst('#', '0xff')));
//     }
//     return AppColors.textPrimary;
//   }

//   bool _hasTextOverlay() {
//     return widget.template.elements.any(
//       (element) => element.type == TemplateElementType.textOverlay,
//     );
//   }

//   Future<void> _changeImage() async {
//     final ImagePicker picker = ImagePicker();
//     final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
//     if (image != null) {
//       try {
//         if (kIsWeb) {
//           final bytes = await image.readAsBytes();
//           setState(() {
//             _processedImage = bytes;
//           });
//         } else {
//           setState(() {
//             _processedImage = File(image.path);
//           });
//         }
//       } catch (e) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('이미지 변경 중 오류가 발생했습니다: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _saveTemplate() async {
//     if (_isSaving) return;

//     setState(() {
//       _isSaving = true;
//     });

//     try {
//       // 템플릿 캡처
//       RenderRepaintBoundary boundary = _templateKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
//       ui.Image image = await boundary.toImage(pixelRatio: 3.0);
//       ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
//       if (byteData == null) {
//         throw Exception('템플릿 캡처 실패');
//       }

//       final Uint8List imageBytes = byteData.buffer.asUint8List();
//       final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
//       final fileName = 'template_${widget.template.name}_$timestamp.png';

//       final result = await ImageGallerySaver.saveImage(
//         imageBytes,
//         name: fileName,
//         quality: 100,
//       );
      
//       if (result['isSuccess'] == true || result['isSuccess'] == 1) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Row(
//               children: [
//                 Icon(Icons.check_circle, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Text('템플릿이 갤러리에 저장되었습니다.'),
//               ],
//             ),
//             backgroundColor: Colors.green,
//             duration: const Duration(seconds: 2),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       } else {
//         throw Exception('이미지 저장 실패');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.error, color: Colors.white),
//               const SizedBox(width: 8),
//               Expanded(child: Text('저장 중 오류가 발생했습니다: ${e.toString()}')),
//             ],
//           ),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 3),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } finally {
//       setState(() {
//         _isSaving = false;
//       });
//     }
//   }
// } 