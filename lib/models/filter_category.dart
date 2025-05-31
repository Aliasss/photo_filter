class FilterCategory {
  final String name;
  final String icon;
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
      icon: '🍽️',
      description: '맛있어 보이게',
      filters: ['따뜻한 조명', '신선한 자연', '고급 레스토랑', '홈메이드 감성', '카페 무드'],
    ),
    FilterCategory(
      name: '매장',
      icon: '🏪',
      description: '깔끔하고 세련되게',
      filters: ['깔끔한 화이트', '모던 블랙', '따뜻한 우드', '미니멀 그레이', '럭셔리 골드'],
    ),
    FilterCategory(
      name: '제품',
      icon: '📦',
      description: '고급스럽게',
      filters: ['스튜디오 조명', '자연광 화이트', '프리미엄 블랙', '빈티지 필름', '모던 컬러'],
    ),
    FilterCategory(
      name: '패션',
      icon: '👕',
      description: '트렌디하게',
      filters: ['자연 채광', '스트릿 무드', '클래식 블랙', '소프트 파스텔', '비비드 컬러'],
    ),
  ];
} 