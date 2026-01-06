import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

/// Settings 화면
///
/// 특징:
/// - 알림 설정 토글
/// - 차단 목록 관리 접근
/// - 정책/가이드라인 링크
/// - LoadingOverlay로 로딩 상태 처리
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
      onPopInvokedWithResult: (didPop, result) {
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
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
        ),
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.spacing16),
              children: [
                // 알림 섹션
                _SectionHeader(title: l10n.settingsSectionNotification),
                SizedBox(height: AppSpacing.spacing12),

                Card(
                  color: AppColors.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: state.notificationsEnabled,
                        onChanged: state.isLoading ? null : controller.updateNotifications,
                        title: Text(
                          l10n.settingsNotificationToggle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurface,
                              ),
                        ),
                        subtitle: Text(
                          l10n.settingsNotificationHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing16,
                          vertical: AppSpacing.spacing8,
                        ),
                      ),
                      Divider(
                        height: 1,
                        color: AppColors.onSurface.withValues(alpha: 0.12),
                      ),
                      ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.inbox,
                            size: 20,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          l10n.settingsNotificationInbox,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.onSurface,
                              ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onTap: () => context.go(AppRoutes.notifications),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: AppSpacing.spacing24),

                // 안전 섹션
                _SectionHeader(title: l10n.settingsSectionSafety),
                SizedBox(height: AppSpacing.spacing12),

                Card(
                  color: AppColors.surface,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.medium,
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.block,
                        size: 20,
                        color: AppColors.error,
                      ),
                    ),
                    title: Text(
                      l10n.settingsBlockedUsers,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () => context.go(AppRoutes.blockList),
                  ),
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

/// 섹션 헤더
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
