import Flutter
import google_mobile_ads
import UIKit

@objc class AppDelegate: FlutterAppDelegate {
  private let nativeAdFactoryId = "exit_confirm"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    // 종료 확인 바텀시트 네이티브 광고 팩토리 등록
    FLTGoogleMobileAdsPlugin.registerNativeAdFactory(
      self,
      factoryId: nativeAdFactoryId,
      nativeAdFactory: ExitConfirmNativeAdFactory()
    )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationWillTerminate(_ application: UIApplication) {
    // 종료 확인 바텀시트 네이티브 광고 팩토리 해제
    FLTGoogleMobileAdsPlugin.unregisterNativeAdFactory(
      self,
      factoryId: nativeAdFactoryId
    )
    super.applicationWillTerminate(application)
  }
}
