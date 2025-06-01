import 'package:flutter/material.dart';

class Template {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double aspectRatio; // 가로:세로 비율
  final TemplateLayout layout;
  final List<TemplateElement> elements;

  Template({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.aspectRatio,
    required this.layout,
    required this.elements,
  });
}

class TemplateLayout {
  final double width;
  final double height;
  final TemplateBackground background;

  TemplateLayout({
    required this.width,
    required this.height,
    required this.background,
  });
}

class TemplateBackground {
  final TemplateBackgroundType type;
  final dynamic value; // Color, Gradient, or asset path

  TemplateBackground({
    required this.type,
    required this.value,
  });
}

enum TemplateBackgroundType {
  color,
  gradient,
  image,
}

class TemplateElement {
  final String id;
  final TemplateElementType type;
  final Rect bounds; // 위치와 크기 (0-1 사이의 상대적 값)
  final dynamic style; // 텍스트 스타일, 이미지 스타일 등

  TemplateElement({
    required this.id,
    required this.type,
    required this.bounds,
    this.style,
  });
}

enum TemplateElementType {
  userImage, // 사용자가 업로드한 이미지가 들어갈 영역
  textOverlay, // 텍스트 오버레이 영역
  frame, // 프레임/보더
  decoration, // 장식 요소
}

class TemplateCategory {
  final String id;
  final String name;
  final String description;
  final String icon;
  final List<Template> templates;

  TemplateCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.templates,
  });

  // 미리 정의된 템플릿 카테고리들
  static List<TemplateCategory> get categories => [
    // 인스타그램 스토리 템플릿
    TemplateCategory(
      id: 'instagram_story',
      name: '스토리',
      description: '1080x1920 세로형 스토리',
      icon: '📱',
      templates: _storyTemplates,
    ),
    
    // 프로필 사진 프레임
    TemplateCategory(
      id: 'profile_frame',
      name: '프로필 사진',
      description: '1:1 비율 프로필 프레임',
      icon: '👤',
      templates: _profileTemplates,
    ),
    
    // 명함/포스터 레이아웃
    TemplateCategory(
      id: 'business_card',
      name: '명함/포스터',
      description: '비즈니스용 깔끔한 디자인',
      icon: '💼',
      templates: _businessTemplates,
    ),
  ];

  // 인스타그램 스토리 템플릿들
  static List<Template> get _storyTemplates => [
    // 상단 이미지 + 하단 텍스트 오버레이
    Template(
      id: 'story_top_image',
      name: '상단 이미지',
      description: '위쪽 이미지 + 아래 텍스트 영역',
      categoryId: 'instagram_story',
      aspectRatio: 9 / 16, // 1080:1920
      layout: TemplateLayout(
        width: 1080,
        height: 1920,
        background: TemplateBackground(
          type: TemplateBackgroundType.gradient,
          value: ['#667eea', '#764ba2'], // 보라-파랑 그라데이션
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.1, 0.15, 0.8, 0.5), // 상단 80% 폭, 50% 높이
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.1, 0.7, 0.8, 0.2), // 하단 텍스트 영역
        ),
      ],
    ),

    // 중앙 원형 이미지 + 그라데이션
    Template(
      id: 'story_center_circle',
      name: '중앙 원형',
      description: '가운데 원형 이미지 + 그라데이션',
      categoryId: 'instagram_story',
      aspectRatio: 9 / 16,
      layout: TemplateLayout(
        width: 1080,
        height: 1920,
        background: TemplateBackground(
          type: TemplateBackgroundType.gradient,
          value: ['#ffecd2', '#fcb69f'], // 오렌지 그라데이션
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.2, 0.3, 0.6, 0.6), // 중앙 원형
          style: {'shape': 'circle'},
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.1, 0.05, 0.8, 0.2), // 상단 텍스트
        ),
      ],
    ),

    // 전체 배경 이미지 + 오버레이
    Template(
      id: 'story_full_background',
      name: '전체 배경',
      description: '전체 배경 이미지 + 텍스트 오버레이',
      categoryId: 'instagram_story',
      aspectRatio: 9 / 16,
      layout: TemplateLayout(
        width: 1080,
        height: 1920,
        background: TemplateBackground(
          type: TemplateBackgroundType.color,
          value: '#000000',
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.0, 0.0, 1.0, 1.0), // 전체 배경
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.1, 0.8, 0.8, 0.15), // 하단 오버레이
          style: {'backgroundColor': 'rgba(0,0,0,0.5)'},
        ),
      ],
    ),
  ];

  // 프로필 사진 프레임 템플릿들
  static List<Template> get _profileTemplates => [
    // 단순 원형 프레임
    Template(
      id: 'profile_circle_simple',
      name: '원형 프레임',
      description: '깔끔한 원형 프로필 프레임',
      categoryId: 'profile_frame',
      aspectRatio: 1.0, // 1:1
      layout: TemplateLayout(
        width: 500,
        height: 500,
        background: TemplateBackground(
          type: TemplateBackgroundType.color,
          value: '#ffffff',
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.1, 0.1, 0.8, 0.8),
          style: {'shape': 'circle', 'borderWidth': 5, 'borderColor': '#4F46E5'},
        ),
      ],
    ),

    // 정사각형 프레임
    Template(
      id: 'profile_square_border',
      name: '정사각 프레임',
      description: '모던한 정사각형 프레임',
      categoryId: 'profile_frame',
      aspectRatio: 1.0,
      layout: TemplateLayout(
        width: 500,
        height: 500,
        background: TemplateBackground(
          type: TemplateBackgroundType.gradient,
          value: ['#f8fafc', '#e2e8f0'],
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.15, 0.15, 0.7, 0.7),
          style: {'shape': 'rounded_square', 'borderRadius': 20, 'borderWidth': 3, 'borderColor': '#7C3AED'},
        ),
      ],
    ),

    // 그라데이션 원형 프레임
    Template(
      id: 'profile_gradient_circle',
      name: '그라데이션 원형',
      description: '그라데이션 배경의 원형 프레임',
      categoryId: 'profile_frame',
      aspectRatio: 1.0,
      layout: TemplateLayout(
        width: 500,
        height: 500,
        background: TemplateBackground(
          type: TemplateBackgroundType.gradient,
          value: ['#667eea', '#764ba2'],
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.2, 0.2, 0.6, 0.6),
          style: {'shape': 'circle', 'borderWidth': 8, 'borderColor': '#ffffff'},
        ),
      ],
    ),
  ];

  // 명함/포스터 템플릿들
  static List<Template> get _businessTemplates => [
    // 좌측 이미지 + 우측 텍스트
    Template(
      id: 'business_left_image',
      name: '좌측 이미지형',
      description: '왼쪽 이미지 + 오른쪽 정보',
      categoryId: 'business_card',
      aspectRatio: 1.6, // 16:10 비율
      layout: TemplateLayout(
        width: 800,
        height: 500,
        background: TemplateBackground(
          type: TemplateBackgroundType.color,
          value: '#ffffff',
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.05, 0.1, 0.4, 0.8),
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.5, 0.2, 0.45, 0.6),
        ),
      ],
    ),

    // 상단 이미지 + 하단 정보
    Template(
      id: 'business_top_image',
      name: '상단 이미지형',
      description: '위쪽 이미지 + 아래 정보',
      categoryId: 'business_card',
      aspectRatio: 1.4, // 7:5 비율
      layout: TemplateLayout(
        width: 700,
        height: 500,
        background: TemplateBackground(
          type: TemplateBackgroundType.gradient,
          value: ['#f8fafc', '#e2e8f0'],
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.1, 0.1, 0.8, 0.5),
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.1, 0.65, 0.8, 0.25),
        ),
      ],
    ),

    // 미니멀 중앙 이미지
    Template(
      id: 'business_minimal',
      name: '미니멀형',
      description: '중앙 이미지 + 심플 디자인',
      categoryId: 'business_card',
      aspectRatio: 1.5,
      layout: TemplateLayout(
        width: 600,
        height: 400,
        background: TemplateBackground(
          type: TemplateBackgroundType.color,
          value: '#1f2937',
        ),
      ),
      elements: [
        TemplateElement(
          id: 'main_image',
          type: TemplateElementType.userImage,
          bounds: Rect.fromLTWH(0.2, 0.25, 0.6, 0.5),
          style: {'shape': 'rounded_square', 'borderRadius': 10},
        ),
        TemplateElement(
          id: 'text_overlay',
          type: TemplateElementType.textOverlay,
          bounds: Rect.fromLTWH(0.1, 0.8, 0.8, 0.15),
          style: {'textColor': '#ffffff'},
        ),
      ],
    ),
  ];
} 