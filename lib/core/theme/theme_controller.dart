import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/local_settings_data_source.dart';

/// 테마 모드 컨트롤러
///
/// 앱의 테마 모드(라이트/다크)를 관리합니다.
/// 기본값은 다크이며, 시스템 옵션은 지원하지 않습니다.
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);

class ThemeController extends Notifier<ThemeMode> {
  LocalSettingsDataSource? _dataSource;

  @override
  ThemeMode build() {
    // 초기값은 무조건 다크
    return ThemeMode.dark;
  }

  /// 데이터 소스 초기화 및 저장된 테마 모드 로드
  Future<void> initDataSource(LocalSettingsDataSource dataSource) async {
    _dataSource = dataSource;
    final savedMode = _dataSource!.loadThemeMode();
    if (savedMode != null) {
      final themeMode = _parseThemeMode(savedMode);
      if (themeMode != null) {
        state = themeMode;
        return;
      }
    }
    // null이거나 파싱 실패 시 기본값 ThemeMode.dark 유지
    // (build()에서 이미 ThemeMode.dark 반환)
  }

  /// 테마 모드 설정
  Future<void> setThemeMode(ThemeMode mode) async {
    // system은 허용하지 않음
    if (mode == ThemeMode.system) {
      mode = ThemeMode.dark;
    }
    state = mode;
    if (_dataSource != null) {
      await _dataSource!.saveThemeMode(_themeModeToString(mode));
    }
  }

  ThemeMode? _parseThemeMode(String value) {
    switch (value) {
      case 'system':
        // 마이그레이션: system이 저장되어 있으면 dark로 치환
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    // system은 저장하지 않음 (항상 dark로 치환)
    switch (mode) {
      case ThemeMode.system:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
