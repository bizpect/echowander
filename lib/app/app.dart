import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/widgets/app_dialog.dart';
import '../core/presentation/widgets/fullscreen_loading.dart';
import '../core/push/push_coordinator.dart';
import '../core/push/push_payload.dart';
import '../core/push/push_state.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_state.dart';
import '../core/deeplink/deeplink_coordinator.dart';
import '../core/locale/locale_controller.dart';
import '../core/locale/locale_sync_controller.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  // 세션 만료 다이얼로그 중복 표시 방지 플래그
  SessionMessage? _lastShownMessage;

  @override
  void initState() {
    super.initState();
    ref.read(pushCoordinatorProvider.notifier).initialize();
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
        showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: message,
        ).then((_) {
          ref.read(sessionManagerProvider.notifier).clearMessage();
          _lastShownMessage = null;
        });
      });
    });
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      if (previous?.status == next.status) {
        return;
      }
      if (next.status == SessionStatus.authenticated) {
        ref
            .read(localeSyncControllerProvider.notifier)
            .sync(ref.read(localeControllerProvider));
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
    final isLoading = ref.watch(sessionManagerProvider).isBusy;

    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.dark(),
      scaffoldMessengerKey: _messengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        return FullScreenLoadingOverlay(
          isLoading: isLoading,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
                ref.read(deepLinkCoordinatorProvider.notifier).enqueuePath(message.route!);
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
      case SessionMessage.genericError:
        return l10n.errorGeneric;
    }
  }
}
