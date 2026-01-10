import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';

/// AdMob 설정 헬퍼
class AdConfig {
  static const _androidNativeTestId = 'ca-app-pub-3940256099942544/2247696110';
  static const _iosNativeTestId = 'ca-app-pub-3940256099942544/3986624511';

  /// 종료 확인 바텀시트용 Native Ad Unit ID
  static String exitConfirmNativeUnitId(AppConfig config) {
    if (config.environment != AppEnvironment.prod) {
      return _platformTestNativeId();
    }
    if (Platform.isIOS) {
      return config.admobNativeUnitIdIosProd;
    }
    return config.admobNativeUnitIdAndroidProd;
  }

  static String _platformTestNativeId() {
    if (kIsWeb) {
      return '';
    }
    if (Platform.isIOS) {
      return _iosNativeTestId;
    }
    return _androidNativeTestId;
  }
}
