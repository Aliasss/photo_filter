import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class FilterUtils {
  // 기본 필터 매트릭스
  static List<double> getVividMatrix() => [
    1.2, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.2, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.2, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  static List<double> getClassicMatrix() => [
    1.1, 0.0, 0.0, 0.0, 0.1,
    0.0, 1.1, 0.0, 0.0, 0.1,
    0.0, 0.0, 1.0, 0.0, 0.1,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  static List<double> getModernMatrix() => [
    1.3, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.3, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.3, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  static List<double> getVintageMatrix() => [
    0.393, 0.769, 0.189, 0.0, 0.0,
    0.349, 0.686, 0.168, 0.0, 0.0,
    0.272, 0.534, 0.131, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  static List<double> getDramaticMatrix() => [
    1.4, 0.0, 0.0, 0.0, -0.1,
    0.0, 1.4, 0.0, 0.0, -0.1,
    0.0, 0.0, 1.4, 0.0, -0.1,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ];

  // 조정값에 따른 매트릭스 생성
  static List<double> createAdjustmentMatrix({
    required double brightness,
    required double contrast,
    required double warmth,
  }) {
    // 밝기 조정
    final brightnessMatrix = [
      1.0, 0.0, 0.0, 0.0, brightness,
      0.0, 1.0, 0.0, 0.0, brightness,
      0.0, 0.0, 1.0, 0.0, brightness,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 대비 조정
    final contrastFactor = 1.0 + contrast;
    final contrastMatrix = [
      contrastFactor, 0.0, 0.0, 0.0, 0.0,
      0.0, contrastFactor, 0.0, 0.0, 0.0,
      0.0, 0.0, contrastFactor, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 따뜻함 조정
    final warmthMatrix = [
      1.0 + warmth * 0.1, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0 - warmth * 0.1, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    // 매트릭스 곱셈 (단순화된 버전)
    return multiplyMatrices([
      brightnessMatrix,
      contrastMatrix,
      warmthMatrix,
    ]);
  }

  // 매트릭스 곱셈 (단순화된 버전)
  static List<double> multiplyMatrices(List<List<double>> matrices) {
    if (matrices.isEmpty) return [
      1.0, 0.0, 0.0, 0.0, 0.0,
      0.0, 1.0, 0.0, 0.0, 0.0,
      0.0, 0.0, 1.0, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];

    var result = matrices[0];
    for (var i = 1; i < matrices.length; i++) {
      result = _multiplyTwoMatrices(result, matrices[i]);
    }
    return result;
  }

  static List<double> _multiplyTwoMatrices(List<double> a, List<double> b) {
    final result = List<double>.filled(20, 0.0);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 5; j++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += a[i * 5 + k] * b[k * 5 + j];
        }
        result[i * 5 + j] = sum + (j == 4 ? a[i * 5 + 4] + b[i * 5 + 4] : 0.0);
      }
    }
    return result;
  }

  // 필터 이름에 따른 매트릭스 반환
  static List<double> getMatrixForFilter(String filterName) {
    switch (filterName) {
      case '비비드':
        return getVividMatrix();
      case '클래식':
        return getClassicMatrix();
      case '모던':
        return getModernMatrix();
      case '빈티지':
        return getVintageMatrix();
      case '드라마틱':
        return getDramaticMatrix();
      default:
        return [
          1.0, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
    }
  }
} 