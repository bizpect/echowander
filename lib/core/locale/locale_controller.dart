import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/settings/data/local_settings_data_source.dart';

final localeControllerProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale?> {
  LocalSettingsDataSource? _dataSource;

  @override
  Locale? build() {
    // 초기화 시 저장된 언어 코드 로드
    _loadLanguageCode();
    return null;
  }

  void _loadLanguageCode() {
    // SharedPreferences는 비동기이므로 초기값은 null(시스템 기본)
    // 실제 로드는 initDataSource 후에 수행
  }

  /// 데이터 소스 초기화 및 저장된 언어 코드 로드
  Future<void> initDataSource(LocalSettingsDataSource dataSource) async {
    _dataSource = dataSource;
    final savedCode = _dataSource!.loadLanguageCode();
    if (savedCode != null && savedCode != 'system') {
      setLocaleTag(savedCode);
    }
  }

  void setLocaleTag(String tag) {
    if (tag == 'system') {
      state = null;
    } else if (tag == 'pt_BR') {
      state = const Locale('pt', 'BR');
    } else {
      state = Locale(tag);
    }
    // 저장
    if (_dataSource != null) {
      _dataSource!.saveLanguageCode(tag == 'system' ? null : tag);
    }
  }

  /// 현재 언어 코드 반환 (시스템 기본이면 'system')
  String getCurrentLanguageCode() {
    if (state == null) {
      return 'system';
    }
    if (state == const Locale('pt', 'BR')) {
      return 'pt_BR';
    }
    return state!.languageCode;
  }
}
