import '../utils/filter_utils.dart';

class FilterOption {
  final String name;
  final String category;
  final String description;
  final Map<String, double> adjustments;
  
  const FilterOption({
    required this.name,
    required this.category,
    required this.description,
    required this.adjustments,
  });
  
  factory FilterOption.fromPreset(String name, String category) {
    final preset = FilterUtils.getFilterPreset(name);
    final description = _getDescription(name);
    return FilterOption(
      name: name,
      category: category,
      description: description,
      adjustments: preset,
    );
  }

  static String _getDescription(String name) {
    switch (name) {
      // 음식 카테고리
      case '카페 무드':
        return '아늑하고 포근한 카페 분위기';
      case '홈메이드 감성':
        return '정겨운 집밥의 따뜻한 온기';
      case '소프트 파스텔':
        return '부드럽고 달콤한 베이커리 느낌';
      case '비비드 컬러':
        return '신선하고 생생한 색감';
      case '미니멀 그레이':
        return '세련되고 모던한 플레이팅';
      // 매장 카테고리
      case '모던 블랙':
        return '고급스럽고 전문적인 공간';
      case '웜 우드':
        return '자연스럽고 편안한 인테리어';
      case '미니멀':
        return '깔끔하고 현대적인 공간';
      // 제품 카테고리
      case '럭셔리':
        return '프리미엄하고 우아한 느낌';
      case '클린':
        return '깔끔하고 정확한 색감';
      // 패션 카테고리
      case '트렌디':
        return '세련되고 스타일리시한 룩';
      case '빈티지':
        return '따뜻하고 그리운 필름 감성';
      default:
        return '자연스러운 색감';
    }
  }
  
  static const Map<String, List<FilterOption>> categoryFilters = {
    '음식': [
      FilterOption(
        name: '카페 무드',
        category: '음식',
        description: '아늑하고 포근한 카페 분위기',
        adjustments: {'brightness': 15, 'warmth': 20, 'saturation': 10},
      ),
      FilterOption(
        name: '홈메이드 감성',
        category: '음식',
        description: '정겨운 집밥의 따뜻한 온기',
        adjustments: {'brightness': 10, 'contrast': 15, 'saturation': 25},
      ),
      FilterOption(
        name: '소프트 파스텔',
        category: '음식',
        description: '부드럽고 달콤한 베이커리 느낌',
        adjustments: {'contrast': 20, 'warmth': -10, 'saturation': 5},
      ),
      FilterOption(
        name: '비비드 컬러',
        category: '음식',
        description: '신선하고 생생한 색감',
        adjustments: {'brightness': 5, 'warmth': 15, 'saturation': -5},
      ),
      FilterOption(
        name: '미니멀 그레이',
        category: '음식',
        description: '세련되고 모던한 플레이팅',
        adjustments: {'brightness': -5, 'contrast': 10, 'warmth': 10},
      ),
    ],
    '매장': [
      FilterOption(
        name: '모던 블랙',
        category: '매장',
        description: '고급스럽고 전문적인 공간',
        adjustments: {'brightness': -15, 'contrast': 20, 'warmth': -10},
      ),
      FilterOption(
        name: '웜 우드',
        category: '매장',
        description: '자연스럽고 편안한 인테리어',
        adjustments: {'brightness': 10, 'contrast': 0, 'warmth': 15},
      ),
      FilterOption(
        name: '미니멀',
        category: '매장',
        description: '깔끔하고 현대적인 공간',
        adjustments: {'brightness': 20, 'contrast': -10, 'warmth': 0},
      ),
    ],
    '제품': [
      FilterOption(
        name: '럭셔리',
        category: '제품',
        description: '프리미엄하고 우아한 느낌',
        adjustments: {'brightness': -5, 'contrast': 10, 'warmth': -10},
      ),
      FilterOption(
        name: '클린',
        category: '제품',
        description: '깔끔하고 정확한 색감',
        adjustments: {'brightness': 15, 'contrast': -5, 'warmth': -5},
      ),
    ],
    '패션': [
      FilterOption(
        name: '트렌디',
        category: '패션',
        description: '세련되고 스타일리시한 룩',
        adjustments: {'brightness': 8, 'contrast': 8, 'warmth': 12},
      ),
      FilterOption(
        name: '빈티지',
        category: '패션',
        description: '따뜻하고 그리운 필름 감성',
        adjustments: {'brightness': 5, 'contrast': -10, 'warmth': 15},
      ),
    ],
  };
} 