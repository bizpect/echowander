import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/widgets/app_dialog.dart';
import '../core/push/push_coordinator.dart';
import '../core/push/push_payload.dart';
import '../core/push/push_state.dart';
import '../core/session/auth_executor.dart';
import '../core/session/session_invalidation_targets.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_state.dart';
import '../core/deeplink/deeplink_coordinator.dart';
import '../core/locale/locale_controller.dart';
import '../core/locale/locale_sync_controller.dart';
import '../core/theme/theme_controller.dart';
import '../features/settings/data/local_settings_data_source.dart';
import '../features/notifications/application/unread_notification_count_provider.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 세션 준비 모드
enum EnsureSessionMode { blocking, silent }

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  // 세션 만료 다이얼로그 중복 표시 방지 플래그
  SessionMessage? _lastShownMessage;
  // 팝업 루프 차단: 마지막 팝업 표시 시각
  DateTime? _lastPopupAt;
  static const _popupCooldown = Duration(seconds: 30);
  static const _ignoreResumeThreshold = Duration(seconds: 2);
  static const _unreadRefreshCooldown = Duration(seconds: 45);
  DateTime? _pausedAt;
  DateTime? _inactiveAt;
  AppLifecycleState? _lastLifecycleState;
  DateTime? _lastUnreadRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ref.read(pushCoordinatorProvider.notifier).initialize();
    Future.microtask(() => _initializeLocalSettings());
  }

  Future<void> _initializeLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final dataSource = LocalSettingsDataSource(prefs);
    await ref.read(localeControllerProvider.notifier).initDataSource(dataSource);
    await ref.read(themeControllerProvider.notifier).initDataSource(dataSource);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final previous = _lastLifecycleState;
    _lastLifecycleState = state;
    final now = DateTime.now();
    if (state == AppLifecycleState.paused) {
      _pausedAt = now;
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _inactiveAt = now;
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final lastBackgroundAt = _pausedAt ?? _inactiveAt;
      if (lastBackgroundAt != null) {
        final elapsed = now.difference(lastBackgroundAt);
        if (elapsed < _ignoreResumeThreshold) {
          if (kDebugMode) {
            debugPrint(
              '[AppLifecycleGate] ignore resume '
              '(elapsed=${elapsed.inMilliseconds}ms, reason=transient_system_ui)',
            );
          }
          _pausedAt = null;
          _inactiveAt = null;
          return;
        }
      }
      if (kDebugMode && previous != null) {
        debugPrint('[AppLifecycleGate] resume from $previous');
      }
      _pausedAt = null;
      _inactiveAt = null;
      // 복귀 시: 복구 먼저, 조회 나중
      _handleAppResumed(mode: EnsureSessionMode.silent);
      _refreshUnreadCountIfNeeded();
    }
  }

  void _handleAppResumed({required EnsureSessionMode mode}) {
    // 복귀 시: 복구 먼저, 조회 나중
    _ensureSessionReady(mode: mode);
  }

  void _refreshUnreadCountIfNeeded() {
    final now = DateTime.now();
    if (_lastUnreadRefreshAt != null &&
        now.difference(_lastUnreadRefreshAt!) < _unreadRefreshCooldown) {
      if (kDebugMode) {
        debugPrint('[AppLifecycleGate] unread refresh skipped (cooldown)');
      }
      return;
    }
    final sessionState = ref.read(sessionManagerProvider);
    if (sessionState.status != SessionStatus.authenticated) {
      return;
    }
    _lastUnreadRefreshAt = now;
    ref.invalidate(unreadNotificationCountProvider);
  }

  /// 세션 준비 보장 (복귀 시 Query 폭주 방지)
  /// 반드시 await 형태로 호출하여 복구가 끝나기 전에는 Query 실행을 미룬다.
  Future<void> _ensureSessionReady({
    required EnsureSessionMode mode,
  }) async {
    if (kDebugMode) {
      debugPrint('[App] resumed → ensureSessionReady (mode=$mode)');
    }

    final sessionManager = ref.read(sessionManagerProvider.notifier);
    final sessionState = ref.read(sessionManagerProvider);

    // ✅ SSOT: restoreInFlight가 존재하면 restoreSession을 호출하지 말고 그 Future만 await
    final inFlight = sessionManager.restoreInFlight;
    if (inFlight != null) {
      if (kDebugMode) {
        debugPrint('[App] inFlight exists → await');
      }
      await _awaitRestoreInFlight(inFlight);
      return;
    }

    // ✅ unauthenticated 상태에서는 restoreSession 호출 금지 (루프 방지)
    if (sessionState.status == SessionStatus.unauthenticated) {
      if (kDebugMode) {
        debugPrint(
          '[App] ensureSessionReady 차단: 이미 unauthenticated 상태 (루프 방지)',
        );
      }
      return;
    }

    final accessToken = sessionState.accessToken;
    final hasToken = accessToken != null && accessToken.isNotEmpty;
    final isExpiring = hasToken &&
        JwtUtils.isExpiringSoon(accessToken, thresholdSeconds: 60);
    final needsRestore = !hasToken || isExpiring;

    if (!needsRestore) {
      if (kDebugMode) {
        debugPrint('[App] 세션 준비 완료 (토큰 유효)');
      }
      return;
    }

    if (mode == EnsureSessionMode.silent && hasToken) {
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 세션 갱신 필요 → silentRefreshIfNeeded');
      }
      await _silentRefreshSafely(sessionManager);
      return;
    }

    // accessToken이 없거나 만료/임박이면 restoreSession 선제 호출
    // (이 호출이 single-flight를 걸어줌)
    if (kDebugMode) {
      if (!hasToken) {
        debugPrint('[App] 복귀 시 accessToken 없음 → restoreSession 선제 호출');
      } else {
        debugPrint('[App] 복귀 시 세션 갱신 필요 → restoreSession 선제 호출');
      }
    }
    await _restoreSessionSafely(sessionManager);
  }

  /// restoreInFlight await (재호출 금지)
  Future<void> _awaitRestoreInFlight(Future<void> inFlight) async {
    try {
      await inFlight;
    } on RestoreSessionBlockedException {
      // 쿨다운 중 - 정상적인 상황
      if (kDebugMode) {
        debugPrint('[App] restoreInFlight 쿨다운 중 → 건너뜀');
      }
    } on RestoreSessionFailedException {
      // 인증 실패 확정 - 이미 unauthenticated로 전환됨
      if (kDebugMode) {
        debugPrint('[App] restoreInFlight 인증 실패 → 로그인 유도');
      }
    } on RestoreSessionTransientException {
      // 일시 장애 - 토큰 유지, 앱 계속 진행
      if (kDebugMode) {
        debugPrint('[App] restoreInFlight 일시 장애 → 앱 계속 진행');
      }
    } catch (error) {
      // 예상치 못한 오류 - 로그만 남기고 앱 계속 진행
      if (kDebugMode) {
        debugPrint('[App] restoreInFlight 예외: $error');
      }
    }
  }

  /// restoreSession 안전 호출 (Unhandled Exception 방지)
  Future<void> _restoreSessionSafely(SessionManager sessionManager) async {
    try {
      // single-flight로 중복 호출 방지됨
      await sessionManager.restoreSession();
    } on RestoreSessionBlockedException {
      // 쿨다운 중 - 정상적인 상황
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 restoreSession 쿨다운 중 → 건너뜀');
      }
    } on RestoreSessionFailedException {
      // 인증 실패 확정 - 이미 unauthenticated로 전환됨
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 restoreSession 인증 실패 → 로그인 유도');
      }
    } on RestoreSessionTransientException {
      // 일시 장애 - 토큰 유지, 앱 계속 진행
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 restoreSession 일시 장애 → 앱 계속 진행');
      }
    } catch (error) {
      // 예상치 못한 오류 - 로그만 남기고 앱 계속 진행
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 restoreSession 예외: $error');
      }
    }
  }

  /// silentRefresh 안전 호출 (Unhandled Exception 방지)
  Future<void> _silentRefreshSafely(SessionManager sessionManager) async {
    try {
      await sessionManager.silentRefreshIfNeeded(reason: 'resume');
    } on RestoreSessionFailedException {
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 silentRefresh 인증 실패 → 로그인 유도');
      }
    } on RestoreSessionTransientException {
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 silentRefresh 일시 장애 → 앱 계속 진행');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[App] 복귀 시 silentRefresh 예외: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      // 동일한 메시지를 이미 표시한 경우 중복 방지
      if (_lastShownMessage == next.message) {
        return;
      }

      // unauthenticated 상태면 팝업 대신 로그인 유도만 (팝업 루프 방지)
      if (next.status == SessionStatus.unauthenticated) {
        if (kDebugMode) {
          debugPrint('[App] unauthenticated 상태 → 팝업 차단 (로그인 유도만)');
        }
        return;
      }

      // 팝업 쿨다운 체크 (30초 내 중복 방지)
      final now = DateTime.now();
      if (_lastPopupAt != null &&
          now.difference(_lastPopupAt!) < _popupCooldown) {
        if (kDebugMode) {
          debugPrint('[App] 팝업 쿨다운 중 → 표시 건너뜀');
        }
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        if (l10n == null) {
          return;
        }
        final message = _resolveMessage(l10n, next.message!);
        _lastShownMessage = next.message;
        _lastPopupAt = now;
        showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: message,
          confirmLabel: l10n.commonOk,
        ).then((_) {
          ref.read(sessionManagerProvider.notifier).clearMessage();
          _lastShownMessage = null;
        });
      });
    });
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      // 세션 상태 변경 감지
      final statusChanged = previous?.status != next.status;
      // accessToken 변경 감지 (계정 전환/로그아웃/로그인)
      final accessTokenChanged = previous?.accessToken != next.accessToken;

      // 계정 전환/로그아웃/로그인 시 중앙 관리 목록의 모든 Provider invalidate
      // → 이전 사용자의 데이터 잔상 방지
      if (accessTokenChanged) {
        for (final target in sessionInvalidationTargets) {
          ref.invalidate(target);
        }
      }

      if (statusChanged) {
        if (next.status == SessionStatus.authenticated) {
          ref
              .read(localeSyncControllerProvider.notifier)
              .sync(ref.read(localeControllerProvider));
        } else if (next.status == SessionStatus.unauthenticated &&
            previous?.status == SessionStatus.authenticated) {
          // ✅ authenticated → unauthenticated 전환 시 알럿 표시 후 로그인 화면 이동
          // ✅ SessionMessage consume 방식으로 정확히 1회 보장
          if (next.message == SessionMessage.sessionExpired) {
            // ✅ router를 사전에 확보 (컨텍스트/redirect 충돌 방지)
            final router = ref.read(appRouterProvider);
            final sessionManager = ref.read(sessionManagerProvider.notifier);

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) {
                return;
              }
              final l10n = AppLocalizations.of(context);
              if (l10n == null) {
                return;
              }

              // ✅ 현재 위치 확인 (router 인스턴스 확보 후)
              final currentLocation =
                  router.routerDelegate.currentConfiguration.uri.path;

              // 이미 로그인 화면이면 알럿만 표시
              if (currentLocation == AppRoutes.login) {
                showAppAlertDialog(
                  context: context,
                  title: l10n.errorTitle,
                  message: l10n.errorSessionExpired,
                  confirmLabel: l10n.commonOk,
                ).then((_) {
                  if (!mounted) {
                    return;
                  }
                  // ✅ 알럿 표시 후 consume (중복 방지)
                  sessionManager.consumeMessage(SessionMessage.sessionExpired);
                });
              } else {
                // 로그인 화면이 아니면 알럿 표시 후 이동
                showAppAlertDialog(
                  context: context,
                  title: l10n.errorTitle,
                  message: l10n.errorSessionExpired,
                  confirmLabel: l10n.commonOk,
                ).then((_) {
                  if (!mounted) {
                    return;
                  }
                  // ✅ 알럿 표시 후 consume (중복 방지)
                  sessionManager.consumeMessage(SessionMessage.sessionExpired);
                  // ✅ router.go() 호출 보장 (redirect 충돌 방지)
                  if (kDebugMode) {
                    debugPrint('[App] sessionExpired confirm -> go(login)');
                  }
                  router.go(AppRoutes.login);
                });
              }
            });
          }
        }
      }
    });
    ref.listen<Locale?>(localeControllerProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      ref.read(localeSyncControllerProvider.notifier).sync(next);
    });
    ref.listen<PushState>(pushCoordinatorProvider, (previous, next) {
      if (next.foregroundMessage == null ||
          next.foregroundMessage == previous?.foregroundMessage) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        if (l10n == null) {
          return;
        }
        final message = next.foregroundMessage!;
        _showForegroundBanner(l10n, message);
        ref.read(pushCoordinatorProvider.notifier).clearForegroundMessage();
      });
    });
    ref.listen<DeepLinkState>(deepLinkCoordinatorProvider, (previous, next) {
      final path = next.pendingPath;
      if (path == null || path == previous?.pendingPath) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(appRouterProvider).go(path);
        ref.read(deepLinkCoordinatorProvider.notifier).consumeCurrent();
      });
    });
    // ✅ UI 로딩 인디케이터는 제거 (silent refresh는 사용자 모르게 처리)
    // final isLoading = ref.watch(sessionManagerProvider).isBusy;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    final themeMode = ref.watch(themeControllerProvider);
    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark().copyWith(
        // 모바일에서 Tooltip 비활성화 (fail-safe)
        tooltipTheme: isMobile
            ? const TooltipThemeData(
                waitDuration: Duration(days: 365),
                showDuration: Duration.zero,
              )
            : null,
      ),
      themeMode: themeMode,
      scaffoldMessengerKey: _messengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // ✅ silent refresh는 사용자 모르게 처리하므로 로딩 오버레이 제거
    );
  }

  void _showForegroundBanner(AppLocalizations l10n, PushPayload message) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) {
      return;
    }
    messenger.hideCurrentMaterialBanner();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surface,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.title.isEmpty ? l10n.notificationTitle : message.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (message.body.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(message.body),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: Text(l10n.notificationDismiss),
          ),
          if (message.route != null)
            FilledButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                ref
                    .read(deepLinkCoordinatorProvider.notifier)
                    .enqueuePath(message.route!);
              },
              child: Text(l10n.notificationOpen),
            ),
        ],
      ),
    );
  }

  String _resolveMessage(AppLocalizations l10n, SessionMessage message) {
    switch (message) {
      case SessionMessage.loginFailed:
        return l10n.errorLoginFailed;
      case SessionMessage.loginCancelled:
        return l10n.errorLoginCancelled;
      case SessionMessage.loginNetworkError:
        return l10n.errorLoginNetwork;
      case SessionMessage.loginInvalidToken:
        return l10n.errorLoginInvalidToken;
      case SessionMessage.loginUnsupportedProvider:
        return l10n.errorLoginUnsupportedProvider;
      case SessionMessage.loginUserSyncFailed:
        return l10n.errorLoginUserSyncFailed;
      case SessionMessage.loginServiceUnavailable:
        return l10n.errorLoginServiceUnavailable;
      case SessionMessage.sessionExpired:
        return l10n.errorSessionExpired;
      case SessionMessage.authRefreshFailed:
        return l10n.errorAuthRefreshFailed;
      case SessionMessage.genericError:
        return l10n.errorGeneric;
    }
  }
}
