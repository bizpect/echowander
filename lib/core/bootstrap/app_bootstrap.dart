import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../firebase_options.dart';
import '../config/app_config.dart';
import '../push/fcm_background_handler.dart';

class AppBootstrap {
  Future<void> initialize() async {
    await dotenv.load(fileName: '.env.local');
    final config = AppConfig.fromEnvironment();
    AppConfigStore.current = config;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
    await MobileAds.instance.initialize();
    if (config.kakaoNativeAppKey.isNotEmpty) {
      KakaoSdk.init(nativeAppKey: config.kakaoNativeAppKey);
    }
  }
}
