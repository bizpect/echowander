import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/fullscreen_loading.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(settingsControllerProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    ref.listen<SettingsState>(settingsControllerProvider, (previous, next) {
      if (next.message == null || next.message == previous?.message) {
        return;
      }
      unawaited(_handleMessage(l10n, next.message!));
      controller.clearMessage();
    });

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        _handleBack(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settingsTitle),
          leading: IconButton(
            onPressed: () => _handleBack(context),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: FullScreenLoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(
                  l10n.settingsSectionNotification,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: state.notificationsEnabled,
                  onChanged: state.isLoading ? null : controller.updateNotifications,
                  title: Text(l10n.settingsNotificationToggle),
                  subtitle: Text(l10n.settingsNotificationHint),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.settingsSectionSafety,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsBlockedUsers),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppRoutes.blockList),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMessage(AppLocalizations l10n, SettingsMessage message) async {
    switch (message) {
      case SettingsMessage.missingSession:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.errorSessionExpired,
          confirmLabel: l10n.composeOk,
        );
        return;
      case SettingsMessage.loadFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.settingsLoadFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
      case SettingsMessage.updateFailed:
        await showAppAlertDialog(
          context: context,
          title: l10n.errorTitle,
          message: l10n.settingsUpdateFailed,
          confirmLabel: l10n.composeOk,
        );
        return;
    }
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }
}
