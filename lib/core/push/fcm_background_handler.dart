import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
