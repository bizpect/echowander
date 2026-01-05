import 'dart:async';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../session/session_manager.dart';
import '../session/session_state.dart';
import '../deeplink/deeplink_coordinator.dart';
import '../notifications/notification_preference_repository.dart';
import 'device_id_store.dart';
import 'push_payload.dart';
import 'push_state.dart';
import 'push_token_repository.dart';

final pushCoordinatorProvider = NotifierProvider<PushCoordinator, PushState>(
  PushCoordinator.new,
);

class PushCoordinator extends Notifier<PushState> {
  bool _initialized = false;
  String? _cachedAccessToken;
  StreamSubscription<RemoteMessage>? _messageSub;
  StreamSubscription<RemoteMessage>? _openSub;
  StreamSubscription<String>? _tokenSub;
  Timer? _apnsRetryTimer;
  int _apnsRetryCount = 0;
  static const int _apnsRetryLimit = 6;
  Timer? _accessRetryTimer;
  int _accessRetryCount = 0;
  static const int _accessRetryLimit = 6;

  @override
  PushState build() {
    ref.onDispose(_dispose);
    return const PushState();
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _listenMessages();
    await _handleInitialMessage();
    _listenSession();
    // 이미 로그인된 상태면 초기 실행 시에도 토큰을 등록한다.
    final session = ref.read(sessionManagerProvider);
    if (session.status == SessionStatus.authenticated) {
      await _registerToken();
    }
  }

  void clearForegroundMessage() {
    state = state.copyWith(clearMessage: true);
  }

  void _dispose() {
    _messageSub?.cancel();
    _openSub?.cancel();
    _tokenSub?.cancel();
    _apnsRetryTimer?.cancel();
    _accessRetryTimer?.cancel();
  }

  Future<void> _listenMessages() async {
    _messageSub = FirebaseMessaging.onMessage.listen((message) {
      final payload = _toPayload(message);
      if (payload == null) {
        return;
      }
      state = state.copyWith(foregroundMessage: payload);
    });

    _openSub = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final route = _resolveRoute(message);
      if (route == null) {
        return;
      }
      ref.read(deepLinkCoordinatorProvider.notifier).enqueuePath(route);
    });
  }

  Future<void> _handleInitialMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    final route = _resolveRoute(message);
    if (route == null) {
      return;
    }
    ref.read(deepLinkCoordinatorProvider.notifier).enqueuePath(route);
  }

  void _listenSession() {
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      if (next.status == SessionStatus.authenticated) {
        _registerToken();
      } else if (previous?.status == SessionStatus.authenticated &&
          next.status == SessionStatus.unauthenticated) {
        _deactivateToken();
      }
      final previousAccessToken = previous?.accessToken;
      final nextAccessToken = next.accessToken;
      if (nextAccessToken != null &&
          nextAccessToken.isNotEmpty &&
          nextAccessToken != previousAccessToken) {
        _registerToken();
      }
    });
  }

  Future<void> _registerToken() async {
    final accessToken = await _readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      // ignore: avoid_print
      print('액세스 토큰 없음: 토큰 등록 중단');
      _scheduleAccessRetry();
      return;
    }
    final enabled = await _isNotificationsEnabled(accessToken);
    if (!enabled) {
      // ignore: avoid_print
      print('알림 비활성화: 토큰 등록 건너뜀');
      return;
    }
    if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) {
        // APNs 토큰이 아직 준비되지 않은 상태를 기록한다.
        // ignore: avoid_print
        print('APNs 토큰 없음: 토큰 등록 재시도 대기');
      } else {
        // ignore: avoid_print
        print('APNs 토큰 확인 완료');
      }
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      // ignore: avoid_print
      print('FCM 토큰 없음: 토큰 등록 재시도 예약');
      _scheduleApnsRetry();
      return;
    }
    final deviceId = await DeviceIdStore().getOrCreate();
    await _upsertToken(fcmToken, deviceId, accessToken: accessToken);
    _apnsRetryTimer?.cancel();
    _apnsRetryCount = 0;
    _tokenSub ??= FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final accessToken = await _readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return;
      }
      final enabled = await _isNotificationsEnabled(accessToken);
      if (!enabled) {
        return;
      }
      await _upsertToken(newToken, deviceId, accessToken: accessToken);
    });
  }

  void _scheduleApnsRetry() {
    if (_apnsRetryCount >= _apnsRetryLimit) {
      return;
    }
    _apnsRetryCount += 1;
    _apnsRetryTimer?.cancel();
    _apnsRetryTimer = Timer(const Duration(seconds: 2), _registerToken);
  }

  void _scheduleAccessRetry() {
    if (_accessRetryCount >= _accessRetryLimit) {
      return;
    }
    _accessRetryCount += 1;
    _accessRetryTimer?.cancel();
    _accessRetryTimer = Timer(const Duration(seconds: 2), _registerToken);
  }

  Future<void> _deactivateToken() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null || fcmToken.isEmpty) {
      return;
    }
    final accessToken = await _readAccessToken() ?? _cachedAccessToken;
    if (accessToken == null || accessToken.isEmpty) {
      return;
    }
    await PushTokenRepository(config: AppConfigStore.current)
        .deactivateToken(accessToken: accessToken, token: fcmToken);
  }

  Future<void> _upsertToken(
    String token,
    String deviceId, {
    String? accessToken,
  }) async {
    final tokenToUse = accessToken ?? await _readAccessToken();
    if (tokenToUse == null || tokenToUse.isEmpty) {
      // ignore: avoid_print
      print('액세스 토큰 없음: 토큰 업서트 중단');
      _scheduleAccessRetry();
      return;
    }
    await PushTokenRepository(config: AppConfigStore.current).upsertToken(
      accessToken: tokenToUse,
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
      deviceId: deviceId,
    );
    _accessRetryTimer?.cancel();
    _accessRetryCount = 0;
  }

  Future<String?> _readAccessToken() async {
    final sessionAccessToken = ref.read(sessionManagerProvider).accessToken;
    if (sessionAccessToken != null && sessionAccessToken.isNotEmpty) {
      // ignore: avoid_print
      print('세션 상태 accessToken 확인: 길이 ${sessionAccessToken.length}');
      _cachedAccessToken = sessionAccessToken;
      return sessionAccessToken;
    }
    // ignore: avoid_print
    print('세션 상태 accessToken 없음: 저장소 조회 시도');
    final tokenStore = ref.read(tokenStoreProvider);
    final tokens = await tokenStore.read();
    final accessToken = tokens?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      // ignore: avoid_print
      print('저장소 accessToken 확인: 길이 ${accessToken.length}');
      _cachedAccessToken = accessToken;
    }
    return accessToken;
  }

  Future<bool> _isNotificationsEnabled(String accessToken) async {
    try {
      return await ref.read(notificationPreferenceRepositoryProvider).fetchEnabled(
            accessToken: accessToken,
          );
    } catch (_) {
      return true;
    }
  }

  PushPayload? _toPayload(RemoteMessage message) {
    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ?? (data['title'] as String? ?? '');
    final body = notification?.body ?? (data['body'] as String? ?? '');
    final route = _resolveRoute(message);
    if (title.isEmpty && body.isEmpty && route == null) {
      return null;
    }
    return PushPayload(
      title: title,
      body: body,
      route: route,
    );
  }

  String? _resolveRoute(RemoteMessage? message) {
    if (message == null) {
      return null;
    }
    final route = message.data['route'];
    if (route is String && route.isNotEmpty) {
      return route;
    }
    final deeplink = message.data['deeplink'];
    if (deeplink is String && deeplink.isNotEmpty) {
      final uri = Uri.tryParse(deeplink);
      if (uri == null) {
        return null;
      }
      if (uri.scheme.isEmpty) {
        return deeplink;
      }
      if (uri.path.isNotEmpty) {
        return uri.path;
      }
      if (uri.host.isNotEmpty) {
        return '/${uri.host}';
      }
    }
    return null;
  }
}
