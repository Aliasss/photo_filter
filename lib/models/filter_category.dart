import 'package:flutter/material.dart';

class FilterCategory {
  final String name;
  final IconData icon;
  final String description;
  final List<String> filters;

  const FilterCategory({
    required this.name,
    required this.icon,
    required this.description,
    required this.filters,
  });

  static const List<FilterCategory> categories = [
    FilterCategory(
      name: '음식',
      icon: Icons.restaurant,
      description: '맛있어 보이게',
      filters: ['카페 무드', '홈메이드 감성', '소프트 파스텔', '비비드 컬러', '미니멀 그레이'],
    ),
    FilterCategory(
      name: '매장',
      icon: Icons.store,
      description: '깔끔하고 세련되게',
      filters: ['모던 블랙', '웜 우드', '미니멀'],
    ),
    FilterCategory(
      name: '제품',
      icon: Icons.shopping_bag,
      description: '고급스럽게',
      filters: ['럭셔리', '클린'],
    ),
    FilterCategory(
      name: '패션',
      icon: Icons.checkroom,
      description: '트렌디하게',
      filters: ['트렌디', '빈티지'],
    ),
  ];
} 