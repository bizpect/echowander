import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/auth_executor.dart';
import '../../../core/session/session_manager.dart';
import '../data/supabase_notification_repository.dart';
import '../domain/notification_item.dart';
import '../domain/notification_repository.dart';

const _logPrefix = '[NotificationInbox]';

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

  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  @override
  NotificationInboxState build() {
    return const NotificationInboxState(
      items: [],
      isLoading: false,
      unreadOnly: false,
      unreadCount: 0,
      message: null,
    );
  }

  Future<void> load({int limit = _defaultLimit, int offset = 0}) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix load - start, limit: $limit, offset: $offset');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final executor = AuthExecutor(ref);
      // 알림 목록과 읽지 않은 개수를 한 번에 조회
      final result = await executor.execute<(List<NotificationItem>, int)>(
        operation: (accessToken) async {
          final items = await _repository.fetchNotifications(
            accessToken: accessToken,
            limit: limit,
            offset: offset,
            unreadOnly: state.unreadOnly,
          );
          final unreadCount = await _repository.fetchUnreadCount(
            accessToken: accessToken,
          );
          return (items, unreadCount);
        },
        isUnauthorized: (error) =>
            error is NotificationInboxException &&
            error.error == NotificationInboxError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<(List<NotificationItem>, int)>(:final data):
          final (items, unreadCount) = data;
          if (kDebugMode) {
            debugPrint('$_logPrefix load - completed, items: ${items.length}, unread: $unreadCount');
          }
          state = state.copyWith(
            items: items,
            isLoading: false,
            unreadCount: unreadCount,
          );
        case AuthExecutorNoSession<(List<NotificationItem>, int)>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - missing accessToken');
          }
          state = state.copyWith(
            isLoading: false,
            message: NotificationInboxMessage.missingSession,
          );
        case AuthExecutorUnauthorized<(List<NotificationItem>, int)>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - unauthorized after retry');
          }
          state = state.copyWith(
            isLoading: false,
            message: NotificationInboxMessage.missingSession,
          );
        case AuthExecutorTransientError<(List<NotificationItem>, int)>():
          // 일시 장애: 네트워크/서버 문제 (로그아웃 아님)
          if (kDebugMode) {
            debugPrint('$_logPrefix load - transient error (network/server)');
          }
          state = state.copyWith(
            isLoading: false,
            message: NotificationInboxMessage.loadFailed,
          );
      }
    } on NotificationInboxException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외
      if (kDebugMode) {
        debugPrint('$_logPrefix load - NotificationInboxException: ${error.error}');
      }
      state = state.copyWith(
        isLoading: false,
        message: NotificationInboxMessage.loadFailed,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix load - unknown error: $error');
      }
      state = state.copyWith(
        isLoading: false,
        message: NotificationInboxMessage.loadFailed,
      );
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
    if (kDebugMode) {
      debugPrint('$_logPrefix loadUnreadCount - start');
    }

    try {
      final executor = AuthExecutor(ref);
      final result = await executor.execute<int>(
        operation: (accessToken) => _repository.fetchUnreadCount(
          accessToken: accessToken,
        ),
        isUnauthorized: (error) =>
            error is NotificationInboxException &&
            error.error == NotificationInboxError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<int>(:final data):
          if (kDebugMode) {
            debugPrint('$_logPrefix loadUnreadCount - completed, count: $data');
          }
          state = state.copyWith(unreadCount: data);
        case AuthExecutorNoSession<int>():
          if (kDebugMode) {
            debugPrint('$_logPrefix loadUnreadCount - missing accessToken');
          }
          state = state.copyWith(message: NotificationInboxMessage.missingSession);
        case AuthExecutorUnauthorized<int>():
          if (kDebugMode) {
            debugPrint('$_logPrefix loadUnreadCount - unauthorized after retry');
          }
          state = state.copyWith(message: NotificationInboxMessage.missingSession);
        case AuthExecutorTransientError<int>():
          // 일시 장애: unreadCount 갱신 실패만, 로그아웃 아님
          if (kDebugMode) {
            debugPrint('$_logPrefix loadUnreadCount - transient error (network/server)');
          }
          // unreadCount는 실패해도 UI에 큰 영향 없음, 메시지 없이 무시
      }
    } on NotificationInboxException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외는 무시 (unreadCount 갱신 실패만)
      if (kDebugMode) {
        debugPrint('$_logPrefix loadUnreadCount - error: ${error.error}');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix loadUnreadCount - unknown error: $error');
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
