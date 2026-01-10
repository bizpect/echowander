import 'notification_item.dart';

enum NotificationInboxError {
  missingConfig,
  unauthorized,
  invalidPayload,
  serverRejected,
  network,
  unknown,
}

class NotificationInboxException implements Exception {
  NotificationInboxException(this.error);

  final NotificationInboxError error;
}

abstract class NotificationRepository {
  Future<List<NotificationItem>> fetchNotifications({
    required String accessToken,
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  });

  Future<int> fetchUnreadCount({required String accessToken});

  Future<void> markRead({
    required int notificationId,
    required String accessToken,
  });

  Future<void> deleteNotification({
    required int notificationId,
    required String accessToken,
  });
}
