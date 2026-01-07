import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/notifications/notification_preference_repository.dart';
import '../../../core/push/device_id_store.dart';
import '../../../core/push/push_token_repository.dart';
import '../../../core/session/auth_executor.dart';
import '../../../core/session/session_manager.dart';

const _logPrefix = '[Settings]';

enum SettingsMessage {
  missingSession,
  loadFailed,
  updateFailed,
}

class SettingsState {
  const SettingsState({
    required this.notificationsEnabled,
    required this.isLoading,
    this.message,
  });

  final bool notificationsEnabled;
  final bool isLoading;
  final SettingsMessage? message;

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? isLoading,
    SettingsMessage? message,
    bool clearMessage = false,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isLoading: isLoading ?? this.isLoading,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);

class SettingsController extends Notifier<SettingsState> {
  /// build 재호출 시 LateInitializationError 방지를 위해 getter로 접근
  NotificationPreferenceRepository get _preferenceRepository =>
      ref.read(notificationPreferenceRepositoryProvider);
  PushTokenRepository get _pushTokenRepository =>
      PushTokenRepository(config: AppConfigStore.current);
  final DeviceIdStore _deviceIdStore = DeviceIdStore();

  @override
  SettingsState build() {
    return const SettingsState(
      notificationsEnabled: true,
      isLoading: false,
      message: null,
    );
  }

  Future<void> load() async {
    if (kDebugMode) {
      debugPrint('$_logPrefix load - start');
    }
    state = state.copyWith(isLoading: true, clearMessage: true);

    try {
      final executor = AuthExecutor(ref);
      final result = await executor.execute<bool>(
        operation: (accessToken) => _preferenceRepository.fetchEnabled(
          accessToken: accessToken,
        ),
        isUnauthorized: (error) =>
            error is NotificationPreferenceException &&
            error.error == NotificationPreferenceError.unauthorized,
      );

      switch (result) {
        case AuthExecutorSuccess<bool>(:final data):
          if (kDebugMode) {
            debugPrint('$_logPrefix load - completed, enabled: $data');
          }
          state = state.copyWith(
            notificationsEnabled: data,
            isLoading: false,
          );
        case AuthExecutorNoSession<bool>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - missing accessToken');
          }
          state = state.copyWith(
            isLoading: false,
            message: SettingsMessage.missingSession,
          );
        case AuthExecutorUnauthorized<bool>():
          if (kDebugMode) {
            debugPrint('$_logPrefix load - unauthorized after retry');
          }
          state = state.copyWith(
            isLoading: false,
            message: SettingsMessage.missingSession,
          );
        case AuthExecutorTransientError<bool>():
          // 일시 장애: 네트워크/서버 문제 (로그아웃 아님)
          if (kDebugMode) {
            debugPrint('$_logPrefix load - transient error (network/server)');
          }
          state = state.copyWith(
            isLoading: false,
            message: SettingsMessage.loadFailed,
          );
      }
    } on NotificationPreferenceException catch (error) {
      // 네트워크 오류 등 401이 아닌 예외
      if (kDebugMode) {
        debugPrint('$_logPrefix load - NotificationPreferenceException: ${error.error}');
      }
      state = state.copyWith(isLoading: false, message: SettingsMessage.loadFailed);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix load - unknown error: $error');
      }
      state = state.copyWith(isLoading: false, message: SettingsMessage.loadFailed);
    }
  }

  Future<void> updateNotifications(bool enabled) async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: SettingsMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      await _preferenceRepository.updateEnabled(
        accessToken: accessToken,
        enabled: enabled,
      );
      await _syncPushToken(accessToken: accessToken, enabled: enabled);
      state = state.copyWith(
        notificationsEnabled: enabled,
        isLoading: false,
      );
    } on NotificationPreferenceException catch (error) {
      if (kDebugMode) {
        debugPrint('settings: 알림 설정 업데이트 실패 (${error.error})');
      }
      final message = error.error == NotificationPreferenceError.unauthorized
          ? SettingsMessage.missingSession
          : SettingsMessage.updateFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('settings: 알림 설정 업데이트 알 수 없는 오류');
      }
      state = state.copyWith(isLoading: false, message: SettingsMessage.updateFailed);
    }
  }

  Future<void> _syncPushToken({
    required String accessToken,
    required bool enabled,
  }) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }
    if (!enabled) {
      await _pushTokenRepository.deactivateToken(
        accessToken: accessToken,
        token: token,
      );
      return;
    }
    final deviceId = await _deviceIdStore.getOrCreate();
    await _pushTokenRepository.upsertToken(
      accessToken: accessToken,
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      deviceId: deviceId,
    );
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }
}
