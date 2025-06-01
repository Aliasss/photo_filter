import 'dart:convert';

class FilterPreset {
  final String id;
  final String name;
  final String? filterType; // 적용된 필터 (옵션)
  final double brightness;
  final double contrast;
  final double saturation;
  final double warmth;
  final DateTime createdAt;

  FilterPreset({
    required this.id,
    required this.name,
    this.filterType,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.warmth,
    required this.createdAt,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filterType': filterType,
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'warmth': warmth,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // JSON에서 변환
  factory FilterPreset.fromJson(Map<String, dynamic> json) {
    return FilterPreset(
      id: json['id'],
      name: json['name'],
      filterType: json['filterType'],
      brightness: json['brightness']?.toDouble() ?? 0.0,
      contrast: json['contrast']?.toDouble() ?? 0.0,
      saturation: json['saturation']?.toDouble() ?? 0.0,
      warmth: json['warmth']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // 문자열로 변환 (디버깅용)
  @override
  String toString() {
    return 'FilterPreset(name: $name, filter: $filterType, brightness: $brightness, contrast: $contrast, saturation: $saturation, warmth: $warmth)';
  }

  // 복사 생성자
  FilterPreset copyWith({
    String? id,
    String? name,
    String? filterType,
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    DateTime? createdAt,
  }) {
    return FilterPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      filterType: filterType ?? this.filterType,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      createdAt: createdAt ?? this.createdAt,
    );
  }
} 