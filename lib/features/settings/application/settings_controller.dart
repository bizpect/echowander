import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/notifications/notification_preference_repository.dart';
import '../../../core/push/device_id_store.dart';
import '../../../core/push/push_token_repository.dart';
import '../../../core/session/session_manager.dart';

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
  late final NotificationPreferenceRepository _preferenceRepository;
  late final PushTokenRepository _pushTokenRepository;
  final DeviceIdStore _deviceIdStore = DeviceIdStore();

  @override
  SettingsState build() {
    _preferenceRepository = ref.read(notificationPreferenceRepositoryProvider);
    _pushTokenRepository = PushTokenRepository(config: AppConfigStore.current);
    return const SettingsState(
      notificationsEnabled: true,
      isLoading: false,
      message: null,
    );
  }

  Future<void> load() async {
    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: SettingsMessage.missingSession);
      return;
    }
    state = state.copyWith(isLoading: true, clearMessage: true);
    try {
      final enabled = await _preferenceRepository.fetchEnabled(
        accessToken: accessToken,
      );
      state = state.copyWith(
        notificationsEnabled: enabled,
        isLoading: false,
      );
    } on NotificationPreferenceException catch (error) {
      if (kDebugMode) {
        debugPrint('settings: 알림 설정 로드 실패 (${error.error})');
      }
      final message = error.error == NotificationPreferenceError.unauthorized
          ? SettingsMessage.missingSession
          : SettingsMessage.loadFailed;
      state = state.copyWith(isLoading: false, message: message);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('settings: 알림 설정 로드 알 수 없는 오류');
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
