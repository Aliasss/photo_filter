class FilterOption {
  final String name;
  final String category;
  final Map<String, double> adjustments;
  
  const FilterOption({
    required this.name,
    required this.category,
    required this.adjustments,
  });
  
  static const Map<String, List<FilterOption>> categoryFilters = {
    '음식': [
      FilterOption(
        name: '따뜻한 조명',
        category: '음식',
        adjustments: {'brightness': 15, 'warmth': 20, 'saturation': 10},
      ),
      FilterOption(
        name: '신선한 자연',
        category: '음식',
        adjustments: {'brightness': 10, 'contrast': 15, 'saturation': 25},
      ),
      FilterOption(
        name: '고급 레스토랑',
        category: '음식',
        adjustments: {'contrast': 20, 'warmth': -10, 'saturation': 5},
      ),
      FilterOption(
        name: '홈메이드 감성',
        category: '음식',
        adjustments: {'brightness': 5, 'warmth': 15, 'saturation': -5},
      ),
      FilterOption(
        name: '카페 무드',
        category: '음식',
        adjustments: {'brightness': -5, 'contrast': 10, 'warmth': 10},
      ),
    ],
    // 다른 카테고리들도 유사하게 정의...
  };
} 