import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final appPermissionServiceProvider = Provider<AppPermissionService>(
  (ref) => AppPermissionService(),
);

class AppPermissionService {
  Future<PermissionStatus> requestNotificationPermission() async {
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        return PermissionStatus.granted;
      }
      return PermissionStatus.denied;
    }
    if (Platform.isAndroid) {
      return Permission.notification.request();
    }
    return PermissionStatus.denied;
  }

  Future<PermissionStatus> requestPhotoPermission() async {
    if (Platform.isIOS) {
      return Permission.photos.request();
    }
    if (Platform.isAndroid) {
      final status = await Permission.photos.request();
      if (status.isGranted || status.isLimited) {
        return status;
      }
      return Permission.storage.request();
    }
    return PermissionStatus.denied;
  }
}
