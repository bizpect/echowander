import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../config/app_config.dart';

class AppBootstrap {
  Future<void> initialize() async {
    await dotenv.load(fileName: '.env.local');
    final config = AppConfig.fromEnvironment();
    AppConfigStore.current = config;
    if (config.kakaoNativeAppKey.isNotEmpty) {
      KakaoSdk.init(nativeAppKey: config.kakaoNativeAppKey);
    }
  }
}
