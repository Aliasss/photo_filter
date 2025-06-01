import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../constants/text_styles.dart';
import '../models/filter_preset.dart';
import '../utils/favorites_storage.dart';
import '../widgets/custom_button.dart';

class FavoritesScreen extends StatefulWidget {
  final Function(FilterPreset)? onPresetSelected;
  
  const FavoritesScreen({
    Key? key,
    this.onPresetSelected,
  }) : super(key: key);
  
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<FilterPreset> _presets = [];
  bool _isLoading = true;
  final FavoritesStorage _storage = FavoritesStorage();

  @override
  void initState() {
    super.initState();
    _loadPresets();
  }

  Future<void> _loadPresets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final presets = await _storage.loadPresets();
      setState(() {
        _presets = presets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('프리셋을 불러오는데 실패했습니다: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePreset(FilterPreset preset) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('프리셋 삭제', style: AppTextStyles.sectionTitle),
        content: Text(
          "'${preset.name}' 프리셋을 삭제하시겠습니까?",
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
              '삭제',
              style: AppTextStyles.buttonText.copyWith(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _storage.deletePreset(preset.id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text("'${preset.name}' 프리셋이 삭제되었습니다."),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadPresets(); // 목록 새로고침
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프리셋 삭제에 실패했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyPreset(FilterPreset preset) {
    if (widget.onPresetSelected != null) {
      widget.onPresetSelected!(preset);
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              const SizedBox(width: 8),
              Text("'${preset.name}' 프리셋이 선택되었습니다."),
            ],
          ),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('즐겨찾기', style: AppTextStyles.sectionTitle),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: _loadPresets,
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _presets.isEmpty
          ? _buildEmptyState()
          : _buildPresetsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 24),
            Text(
              '저장된 즐겨찾기가 없습니다',
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '편집 화면에서 마음에 드는\n필터 조합을 저장해보세요!',
              style: AppTextStyles.categoryDesc.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: '새로고침',
              icon: Icons.refresh,
              onPressed: _loadPresets,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final preset = _presets[index];
        return _buildPresetCard(preset);
      },
    );
  }

  Widget _buildPresetCard(FilterPreset preset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _applyPreset(preset),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 섹션
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preset.name,
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 4),
                        if (preset.filterType != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              preset.filterType!,
                              style: AppTextStyles.categoryDesc.copyWith(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => _deletePreset(preset),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 파라미터 섹션
              Row(
                children: [
                  Expanded(
                    child: _buildParameterChip(
                      '밝기', 
                      preset.brightness.round().toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildParameterChip(
                      '대비', 
                      preset.contrast.round().toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildParameterChip(
                      '채도', 
                      preset.saturation.round().toString(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildParameterChip(
                      '따뜻함', 
                      preset.warmth.round().toString(),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // 생성 날짜 및 적용 버튼
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '생성: ${DateFormat('yyyy.MM.dd HH:mm').format(preset.createdAt)}',
                      style: AppTextStyles.categoryDesc.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12, 
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '적용',
                          style: AppTextStyles.categoryDesc.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.categoryDesc.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.categoryDesc.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
} 