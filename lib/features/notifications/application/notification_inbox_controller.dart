import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../data/supabase_notification_repository.dart';
import '../domain/notification_item.dart';
import '../domain/notification_repository.dart';

enum NotificationInboxMessage {
  missingSession,
  loadFailed,
  actionFailed,
}

class NotificationInboxState {
  const NotificationInboxState({
    required this.items,
    required this.isLoading,
    required this.unreadOnly,
    required this.unreadCount,
    this.message,
  });

  final List<NotificationItem> items;
  final bool isLoading;
  final bool unreadOnly;
  final int unreadCount;
  final NotificationInboxMessage? message;

  NotificationInboxState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? unreadOnly,
    int? unreadCount,
    NotificationInboxMessage? message,
    bool clearMessage = false,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      unreadCount: unreadCount ?? this.unreadCount,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final notificationInboxControllerProvider =
    NotifierProvider<NotificationInboxController, NotificationInboxState>(
  NotificationInboxController.new,
);

class NotificationInboxController extends Notifier<NotificationInboxState> {
  static const int _defaultLimit = 50;
  late final NotificationRepository _repository;

  @override
  NotificationInboxState build() {
    _repository = ref.read(notificationRepositoryProvider);
    return const NotificationInboxState(
      items: [],
      isLoading: false,
      unreadOnly: false,
      unreadCount: 0,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: NotificationInboxMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final items = await _repository.fetchNotifications(
        accessToken: accessToken,
        limit: limit,
        offset: offset,
        unreadOnly: state.unreadOnly,
      );
      final unreadCount = await _repository.fetchUnreadCount(
        accessToken: accessToken,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } on NotificationInboxException catch (error) {
      final message = error.error == NotificationInboxError.unauthorized
          ? NotificationInboxMessage.missingSession
          : NotificationInboxMessage.loadFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      state = state.copyWith(isLoading: false, message: NotificationInboxMessage.loadFailed);
    }
  }

  Future<void> markRead(int notificationId) async {
    NotificationItem? target;
    for (final item in state.items) {
      if (item.id == notificationId) {
        target = item;
        break;
      }
    }
    if (target == null || target.isRead) {
      return;
    }
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: NotificationInboxMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.markRead(
        notificationId: notificationId,
        accessToken: accessToken,
      );
      final updatedItems = state.items
          .map(
            (item) => item.id == notificationId
                ? item.copyWith(readAt: DateTime.now())
                : item,
          )
          .toList();
      final unreadCount = await _repository.fetchUnreadCount(
        accessToken: accessToken,
      );
      state = state.copyWith(items: updatedItems, isLoading: false);
      state = state.copyWith(unreadCount: unreadCount);
    } on NotificationInboxException catch (error) {
      final message = error.error == NotificationInboxError.unauthorized
          ? NotificationInboxMessage.missingSession
          : NotificationInboxMessage.actionFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      state = state.copyWith(isLoading: false, message: NotificationInboxMessage.actionFailed);
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: NotificationInboxMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _repository.deleteNotification(
        notificationId: notificationId,
        accessToken: accessToken,
      );
      final items = state.items.where((item) => item.id != notificationId).toList();
      final unreadCount = await _repository.fetchUnreadCount(
        accessToken: accessToken,
      );
      state = state.copyWith(
        items: items,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } on NotificationInboxException catch (error) {
      final message = error.error == NotificationInboxError.unauthorized
          ? NotificationInboxMessage.missingSession
          : NotificationInboxMessage.actionFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      state = state.copyWith(isLoading: false, message: NotificationInboxMessage.actionFailed);
    }
  }

  Future<void> loadUnreadCount() async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: NotificationInboxMessage.missingSession);
      return;
    }
    try {
      final unreadCount = await _repository.fetchUnreadCount(
        accessToken: accessToken,
      );
      state = state.copyWith(unreadCount: unreadCount);
    } on NotificationInboxException catch (error) {
      if (error.error == NotificationInboxError.unauthorized) {
        state = state.copyWith(message: NotificationInboxMessage.missingSession);
      }
    }
  }

  Future<void> toggleUnreadOnly(bool value) async {
    state = state.copyWith(unreadOnly: value);
    await load();
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
