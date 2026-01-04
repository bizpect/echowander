import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/presentation/widgets/app_dialog.dart';
import '../core/presentation/widgets/fullscreen_loading.dart';
import '../core/session/session_manager.dart';
import '../core/session/session_state.dart';
import '../l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  Widget build(BuildContext context) {
    ref.listen<SessionState>(sessionManagerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
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
        showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: message,
        ).then((_) => ref.read(sessionManagerProvider.notifier).clearMessage());
      });
    });
    final isLoading = ref.watch(sessionManagerProvider).isBusy;

    return MaterialApp.router(
      routerConfig: ref.watch(appRouterProvider),
      theme: AppTheme.dark(),
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
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
