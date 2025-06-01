import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/filter_preset.dart';

class FavoritesStorage {
  static const String _key = 'filter_presets';
  
  // 싱글톤 패턴
  static final FavoritesStorage _instance = FavoritesStorage._internal();
  factory FavoritesStorage() => _instance;
  FavoritesStorage._internal();

  // 모든 프리셋 불러오기
  Future<List<FilterPreset>> loadPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? presetsJson = prefs.getString(_key);
      
      if (presetsJson == null) {
        return [];
      }

      final List<dynamic> presetsList = json.decode(presetsJson);
      return presetsList
          .map((presetMap) => FilterPreset.fromJson(presetMap))
          .toList();
    } catch (e) {
      print('프리셋 불러오기 오류: $e');
      return [];
    }
  }

  // 프리셋 저장하기
  Future<bool> savePreset(FilterPreset preset) async {
    try {
      final presets = await loadPresets();
      
      // 중복 체크 (같은 이름이 있으면 덮어쓰기)
      final existingIndex = presets.indexWhere((p) => p.name == preset.name);
      if (existingIndex != -1) {
        presets[existingIndex] = preset;
      } else {
        presets.add(preset);
      }

      return await _savePresets(presets);
    } catch (e) {
      print('프리셋 저장 오류: $e');
      return false;
    }
  }

  // 프리셋 삭제하기
  Future<bool> deletePreset(String presetId) async {
    try {
      final presets = await loadPresets();
      presets.removeWhere((preset) => preset.id == presetId);
      return await _savePresets(presets);
    } catch (e) {
      print('프리셋 삭제 오류: $e');
      return false;
    }
  }

  // 프리셋 이름 중복 체크
  Future<bool> isNameExists(String name) async {
    final presets = await loadPresets();
    return presets.any((preset) => preset.name == name);
  }

  // 프리셋 목록을 SharedPreferences에 저장
  Future<bool> _savePresets(List<FilterPreset> presets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final presetsJson = json.encode(presets.map((p) => p.toJson()).toList());
      return await prefs.setString(_key, presetsJson);
    } catch (e) {
      print('프리셋 목록 저장 오류: $e');
      return false;
    }
  }

  // 모든 프리셋 삭제 (초기화)
  Future<bool> clearAllPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_key);
    } catch (e) {
      print('프리셋 전체 삭제 오류: $e');
      return false;
    }
  }

  // 프리셋 개수 가져오기
  Future<int> getPresetsCount() async {
    final presets = await loadPresets();
    return presets.length;
  }
} 