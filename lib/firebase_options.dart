import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions는 현재 플랫폼을 지원하지 않습니다.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtHPmvk_pKRSHX8FKxYPc_-k8rStU3NUw',
    appId: '1:242212293972:android:76d4ed5859095c132b4cc1',
    messagingSenderId: '242212293972',
    projectId: 'echowander',
    storageBucket: 'echowander.firebasestorage.app',
    androidClientId:
        '242212293972-8vm6ee1525blnu5af4v8f3ngg9i3aku0.apps.googleusercontent.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArB6uoPsPxqlnLOS7kPHxD2lOpbgu3sTo',
    appId: '1:242212293972:ios:eec7b04b5b41cc642b4cc1',
    messagingSenderId: '242212293972',
    projectId: 'echowander',
    storageBucket: 'echowander.firebasestorage.app',
    iosBundleId: 'com.bizpect.echowander',
    iosClientId:
        '242212293972-m5qsl1vt6rj9d06de53b4siuvkhpohk3.apps.googleusercontent.com',
    androidClientId:
        '242212293972-qi1759456v1g6url5ji2pnbmjakcss3u.apps.googleusercontent.com',
  );
}
