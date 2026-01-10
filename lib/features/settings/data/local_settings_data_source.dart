import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _logPrefix = '[LocalSettingsDataSource]';

/// 로컬 설정 데이터 소스
///
/// 언어 및 테마 설정을 SharedPreferences에 저장/로드합니다.
class LocalSettingsDataSource {
  static const String _keyLanguageCode = 'settings_language_code';
  static const String _keyThemeMode = 'settings_theme_mode';

  final SharedPreferences _prefs;

  LocalSettingsDataSource(this._prefs);

  /// 언어 코드 저장
  Future<void> saveLanguageCode(String? languageCode) async {
    try {
      if (languageCode == null) {
        await _prefs.remove(_keyLanguageCode);
      } else {
        await _prefs.setString(_keyLanguageCode, languageCode);
      }
      if (kDebugMode) {
        debugPrint('$_logPrefix saveLanguageCode: $languageCode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix saveLanguageCode error: $e');
      }
      rethrow;
    }
  }

  /// 언어 코드 로드
  String? loadLanguageCode() {
    try {
      final value = _prefs.getString(_keyLanguageCode);
      if (kDebugMode) {
        debugPrint('$_logPrefix loadLanguageCode: $value');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix loadLanguageCode error: $e');
      }
      return null;
    }
  }

  /// 테마 모드 저장
  Future<void> saveThemeMode(String themeMode) async {
    try {
      await _prefs.setString(_keyThemeMode, themeMode);
      if (kDebugMode) {
        debugPrint('$_logPrefix saveThemeMode: $themeMode');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix saveThemeMode error: $e');
      }
      rethrow;
    }
  }

  /// 테마 모드 로드
  String? loadThemeMode() {
    try {
      final value = _prefs.getString(_keyThemeMode);
      if (kDebugMode) {
        debugPrint('$_logPrefix loadThemeMode: $value');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix loadThemeMode error: $e');
      }
      return null;
    }
  }
}
