import FirebaseCore
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureFirebaseIfNeeded()
    return super.application(application, willFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    configureFirebaseIfNeeded()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func configureFirebaseIfNeeded() {
    if FirebaseApp.app() != nil {
      return
    }
    if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let options = FirebaseOptions(contentsOfFile: filePath) {
      FirebaseApp.configure(options: options)
      return
    }
    let fallbackOptions = FirebaseOptions(
      googleAppID: "1:242212293972:ios:eec7b04b5b41cc642b4cc1",
      gcmSenderID: "242212293972"
    )
    fallbackOptions.apiKey = "AIzaSyArB6uoPsPxqlnLOS7kPHxD2lOpbgu3sTo"
    fallbackOptions.projectID = "echowander"
    fallbackOptions.storageBucket = "echowander.firebasestorage.app"
    fallbackOptions.bundleID = "com.bizpect.echowander"
    fallbackOptions.clientID =
      "242212293972-m5qsl1vt6rj9d06de53b4siuvkhpohk3.apps.googleusercontent.com"
    fallbackOptions.androidClientID =
      "242212293972-qi1759456v1g6url5ji2pnbmjakcss3u.apps.googleusercontent.com"
    FirebaseApp.configure(options: fallbackOptions)
  }
}
