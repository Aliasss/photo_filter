import 'dart:typed_data';
import 'dart:io';

class ImageState {
  static final ImageState _instance = ImageState._internal();
  factory ImageState() => _instance;
  ImageState._internal();

  // 현재 편집 중인 이미지 데이터
  dynamic _currentImage; // File 또는 Uint8List
  String? _selectedFilter;
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _warmth = 0;
  List<double> _currentMatrix = [
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // Getters
  dynamic get currentImage => _currentImage;
  String? get selectedFilter => _selectedFilter;
  double get brightness => _brightness;
  double get contrast => _contrast;
  double get saturation => _saturation;
  double get warmth => _warmth;
  List<double> get currentMatrix => List.from(_currentMatrix);

  // Setters
  void updateImage(dynamic image) {
    _currentImage = image;
  }

  void updateFilter(String? filter) {
    _selectedFilter = filter;
  }

  void updateAdjustments({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
  }) {
    if (brightness != null) _brightness = brightness;
    if (contrast != null) _contrast = contrast;
    if (saturation != null) _saturation = saturation;
    if (warmth != null) _warmth = warmth;
  }

  void updateMatrix(List<double> matrix) {
    _currentMatrix = List.from(matrix);
  }

  // 상태 초기화
  void reset() {
    _currentImage = null;
    _selectedFilter = null;
    _brightness = 0;
    _contrast = 0;
    _saturation = 0;
    _warmth = 0;
    _currentMatrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  // 편집된 이미지가 있는지 확인
  bool get hasEditedImage => _currentImage != null;
  
  // 편집 효과가 적용되었는지 확인
  bool get hasEdits => _selectedFilter != null || 
                       _brightness != 0 || 
                       _contrast != 0 || 
                       _saturation != 0 || 
                       _warmth != 0;
} 