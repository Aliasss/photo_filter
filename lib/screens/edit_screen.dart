import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:intl/intl.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_category.dart';
import '../models/filter_preset.dart';
import '../utils/filter_utils.dart';
import '../utils/favorites_storage.dart';
import '../utils/image_state.dart';
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
  bool _isSavingPreset = false; // 프리셋 저장 중 상태
  final GlobalKey _imageKey = GlobalKey(); // RepaintBoundary 키
  final FavoritesStorage _favoritesStorage = FavoritesStorage(); // 즐겨찾기 저장소
  final ImageState _imageState = ImageState(); // 전역 상태 관리
  
  // 크롭 관련 변수들
  bool _isCropMode = false;
  final CropController _cropController = CropController();
  Uint8List? _originalImageBytes;
  Uint8List? _croppedImageBytes;
  double _selectedAspectRatio = -1; // -1: 자유 비율, 1: 1:1, 4/3: 4:3, 16/9: 16:9

  @override
  void initState() {
    super.initState();
    _prepareOriginalImageBytes();
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

  Future<void> _prepareOriginalImageBytes() async {
    try {
      if (kIsWeb) {
        _originalImageBytes = widget.image as Uint8List;
      } else {
        final file = widget.image as File;
        _originalImageBytes = await file.readAsBytes();
      }
    } catch (e) {
      print('원본 이미지 바이트 준비 오류: $e');
    }
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
    
    // 상태 업데이트 - 실시간으로 ImageState에 편집값 반영
    _imageState.updateAdjustments(
      brightness: _brightness,
      contrast: _contrast,
      saturation: _saturation,
      warmth: _warmth,
    );
    _imageState.updateMatrix(_currentMatrix);
    
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
        title: Text(_isCropMode ? '이미지 자르기' : '사진 편집', style: AppTextStyles.sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (_isCropMode) {
              _exitCropMode();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: _isCropMode ? [
          // 크롭 모드에서의 액션 버튼들
          TextButton(
            onPressed: () => _exitCropMode(),
            child: Text(
              '취소',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _applyCrop();
            },
            child: Text(
              '적용',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ] : [
          // 초기화 버튼을 상단으로 이동
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _resetValues,
            tooltip: '초기화',
          ),
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
          // 브랜딩 화면으로 이동 버튼 추가
          IconButton(
            icon: Icon(Icons.palette, color: AppColors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BrandingScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 이미지 미리보기 영역
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(_isCropMode ? 0 : 16),
              child: _isCropMode ? _buildCropView() : _buildEditView(),
            ),
          ),
          // 편집 컨트롤 영역
          _isCropMode ? _buildCropControls() : _buildEditControls(),
        ],
      ),
    );
  }

  Widget _buildEditView() {
    return Center(
      child: RepaintBoundary(
        key: _imageKey,
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_currentMatrix),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _getCurrentImageWidget(),
          ),
        ),
      ),
    );
  }

  Widget _buildCropView() {
    if (_originalImageBytes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return Crop(
      key: ValueKey(_selectedAspectRatio),
      image: _originalImageBytes!,
      controller: _cropController,
      onCropped: _onCropCompleted,
      aspectRatio: _selectedAspectRatio == -1 ? null : _selectedAspectRatio,
      baseColor: AppColors.background,
      maskColor: Colors.black.withOpacity(0.5),
      progressIndicator: const CircularProgressIndicator(),
    );
  }

  Widget _getCurrentImageWidget() {
    // 크롭된 이미지가 있으면 크롭된 이미지 사용, 없으면 원본 이미지 사용
    if (_croppedImageBytes != null) {
      return Image.memory(
        _croppedImageBytes!,
        fit: BoxFit.contain,
      );
    } else if (kIsWeb) {
      return Image.memory(
        widget.image as Uint8List,
        fit: BoxFit.contain,
      );
    } else {
      return Image.file(
        widget.image as File,
        fit: BoxFit.contain,
      );
    }
  }

  Widget _buildCropControls() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '비율 선택',
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildAspectRatioButton('자유', -1),
                const SizedBox(width: 8),
                _buildAspectRatioButton('1:1', 1.0),
                const SizedBox(width: 8),
                _buildAspectRatioButton('4:3', 4.0 / 3.0),
                const SizedBox(width: 8),
                _buildAspectRatioButton('16:9', 16.0 / 9.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAspectRatioButton(String label, double ratio) {
    final isSelected = _selectedAspectRatio == ratio;
    
    return GestureDetector(
      onTap: () => _setAspectRatio(ratio),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildEditControls() {
    return Container(
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
          // 하단 액션 버튼들 (초기화 버튼 제거)
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: '자르기',
                  icon: Icons.crop,
                  isOutlined: true,
                  onPressed: _enterCropMode,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: '프리셋 저장',
                  icon: Icons.favorite,
                  isOutlined: true,
                  isLoading: _isSavingPreset,
                  onPressed: _isSavingPreset ? () {} : _showSavePresetDialog,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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

  void _showSavePresetDialog() {
    final TextEditingController nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('프리셋 저장', style: AppTextStyles.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 설정을 프리셋으로 저장합니다.',
              style: AppTextStyles.categoryDesc,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: '프리셋 이름',
                hintText: '예) 내 스타일, 따뜻한 느낌 등',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              maxLength: 20,
            ),
            const SizedBox(height: 8),
            if (widget.selectedFilter != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '포함될 설정:',
                      style: AppTextStyles.categoryDesc.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('• 필터: ${widget.selectedFilter}', style: AppTextStyles.categoryDesc),
                    Text('• 밝기: ${_brightness.round()}', style: AppTextStyles.categoryDesc),
                    Text('• 대비: ${_contrast.round()}', style: AppTextStyles.categoryDesc),
                    Text('• 채도: ${_saturation.round()}', style: AppTextStyles.categoryDesc),
                    Text('• 따뜻함: ${_warmth.round()}', style: AppTextStyles.categoryDesc),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context);
                _savePreset(name);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('프리셋 이름을 입력해주세요.'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: Text(
              '저장',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreset(String name) async {
    setState(() {
      _isSavingPreset = true;
    });

    try {
      // 중복 이름 체크
      final isExists = await _favoritesStorage.isNameExists(name);
      if (isExists) {
        final bool? shouldOverwrite = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('중복된 이름', style: AppTextStyles.sectionTitle),
            content: Text(
              "'$name' 이름의 프리셋이 이미 있습니다.\n덮어쓰시겠습니까?",
              style: AppTextStyles.categoryDesc,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  '취소',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  '덮어쓰기',
                  style: AppTextStyles.buttonText.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        );

        if (shouldOverwrite != true) {
          setState(() {
            _isSavingPreset = false;
          });
          return;
        }
      }

      // 프리셋 생성
      final preset = FilterPreset(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        filterType: widget.selectedFilter,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        warmth: _warmth,
        createdAt: DateTime.now(),
      );

      // 저장
      final success = await _favoritesStorage.savePreset(preset);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("'$name' 프리셋이 저장되었습니다."),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('저장 실패');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('프리셋 저장 중 오류가 발생했습니다: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isSavingPreset = false;
      });
    }
  }

  void _enterCropMode() {
    setState(() {
      _isCropMode = true;
      _selectedAspectRatio = -1; // 기본값: 자유 비율
    });
  }

  void _exitCropMode({bool applyCrop = false}) {
    setState(() {
      _isCropMode = false;
      if (!applyCrop) {
        _croppedImageBytes = null; // 취소 시 크롭된 이미지 제거
      }
    });
  }

  // Uint8List를 임시 파일로 저장하는 함수
  Future<File?> _saveUint8ListToTempFile(Uint8List data) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/cropped_image_$timestamp.jpg');
      await tempFile.writeAsBytes(data);
      return tempFile;
    } catch (e) {
      print('임시 파일 저장 오류: $e');
      return null;
    }
  }

  void _onCropCompleted(CropResult result) {
    switch (result) {
      case CropSuccess(:final croppedImage):
        // 크롭 성공 시 처리
        _saveCroppedImageAndUpdateState(croppedImage);
        
      case CropFailure(:final cause):
        // 크롭 실패 시 처리
        _exitCropMode(applyCrop: false);
        
        // 사용자에게 에러 알림
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('이미지 자르기 실패: $cause')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<void> _saveCroppedImageAndUpdateState(Uint8List croppedImage) async {
    setState(() {
      _croppedImageBytes = croppedImage;
    });

    // 웹이 아닌 경우 임시 파일로 저장
    if (!kIsWeb) {
      final tempFile = await _saveUint8ListToTempFile(croppedImage);
      if (tempFile != null) {
        // 임시 파일을 전역 상태에 업데이트
        _imageState.updateImage(tempFile);
      }
    } else {
      // 웹의 경우 Uint8List 그대로 전달
      _imageState.updateImage(croppedImage);
    }
    
    // 크롭 완료 후 자동으로 편집 모드로 돌아가기
    _exitCropMode(applyCrop: true);
    
    // 사용자에게 성공 알림
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('이미지가 성공적으로 잘렸습니다.'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _applyCrop() {
    _cropController.crop();
  }

  void _setAspectRatio(double ratio) {
    setState(() {
      _selectedAspectRatio = ratio;
    });
    // 상태 변경으로 위젯이 다시 빌드되어 새로운 aspectRatio가 적용됩니다
  }
} 