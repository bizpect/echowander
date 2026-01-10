package com.bizpect.echowander

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

class MainActivity : FlutterActivity() {
    private val nativeAdFactoryId = "exit_confirm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // 종료 확인 바텀시트 네이티브 광고 팩토리 등록
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            nativeAdFactoryId,
            ExitConfirmNativeAdFactory(layoutInflater),
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        // 종료 확인 바텀시트 네이티브 광고 팩토리 해제
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(
            flutterEngine,
            nativeAdFactoryId,
        )
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
