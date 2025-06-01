import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FilterUtils {
  // 필터별 기본 값 정의
  static Map<String, Map<String, double>> filterPresets = {
    // 매장 카테고리
    'modern_black': {'brightness': -0.1, 'contrast': 0.2, 'warmth': -0.05},
    'warm_wood': {'brightness': 0.05, 'contrast': 0.0, 'warmth': 0.15},
    'minimal': {'brightness': 0.1, 'contrast': -0.05, 'warmth': 0.0},
    
    // 음식 카테고리
    'delicious': {'brightness': 0.05, 'contrast': 0.1, 'warmth': 0.1},
    'vivid': {'brightness': 0.0, 'contrast': 0.15, 'warmth': 0.05},
    
    // 제품 카테고리
    'luxury': {'brightness': -0.05, 'contrast': 0.1, 'warmth': -0.1},
    'clean': {'brightness': 0.15, 'contrast': 0.0, 'warmth': -0.05},
    
    // 패션 카테고리
    'trendy': {'brightness': 0.0, 'contrast': 0.05, 'warmth': 0.05},
    'vintage': {'brightness': -0.05, 'contrast': -0.05, 'warmth': 0.2},
  };

  // 필터별 ColorMatrix 생성
  static List<double> getMatrixForFilter(String filterName) {
    final preset = filterPresets[filterName] ?? 
      {'brightness': 0.0, 'contrast': 0.0, 'warmth': 0.0};
    
    return createAdjustmentMatrix(
      brightness: preset['brightness']!,
      contrast: preset['contrast']!,
      warmth: preset['warmth']!,
    );
  }

  // 조정값으로 ColorMatrix 생성
  static List<double> createAdjustmentMatrix({
    required double brightness,
    required double contrast,
    required double warmth,
  }) {
    // 기본 행렬 (단위 행렬)
    List<double> matrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 밝기 조정
    List<double> brightnessMatrix = [
      1.0, 0.0, 0.0, 0.0, brightness,
      0.0, 1.0, 0.0, 0.0, brightness,
      0.0, 0.0, 1.0, 0.0, brightness,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 대비 조정
    double contrastFactor = 1.0 + contrast;
    List<double> contrastMatrix = [
      contrastFactor, 0.0, 0.0, 0.0, 0.0,
      0.0, contrastFactor, 0.0, 0.0, 0.0,
      0.0, 0.0, contrastFactor, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 따뜻함 조정 (RGB 채널 조정)
    List<double> warmthMatrix = [
      1.0 + warmth, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0 - warmth, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 행렬 곱셈으로 모든 효과 결합
    matrix = multiplyMatrices(matrix, brightnessMatrix);
    matrix = multiplyMatrices(matrix, contrastMatrix);
    matrix = multiplyMatrices(matrix, warmthMatrix);

    return matrix;
  }

  // 행렬 곱셈 함수
  static List<double> multiplyMatrices(List<double> a, List<double> b) {
    List<double> result = List<double>.filled(20, 0.0);
    
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 5; j++) {
        double sum = 0.0;
        for (int k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        if (j == 4) {
          sum += a[i * 5 + 4];
        }
        result[i * 5 + j] = sum;
      }
    }
    
    return result;
  }

  // 필터 이름으로 기본값 가져오기
  static Map<String, double> getFilterPreset(String filterName) {
    return filterPresets[filterName] ?? 
      {'brightness': 0.0, 'contrast': 0.0, 'warmth': 0.0};
  }
} 