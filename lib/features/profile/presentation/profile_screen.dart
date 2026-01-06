import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/session/session_manager.dart';
import '../../../features/notifications/application/notification_inbox_controller.dart';
import '../../../l10n/app_localizations.dart';

/// Profile 탭 화면
///
/// 특징:
/// - 사용자 식별 정보 (익명 닉네임 + user_id)
/// - 알림 수신 상태 요약
/// - 설정 및 기타 메뉴 접근
/// - 로그아웃 확인 다이얼로그
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notificationState = ref.watch(notificationInboxControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabProfileLabel),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(AppSpacing.spacing16),
          children: [
            // 사용자 정보 카드
            Card(
              color: AppColors.surface,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.spacing20),
                child: Column(
                  children: [
                    // 프로필 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.spacing16),

                    // 닉네임
                    Text(
                      l10n.profileDefaultNickname,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSpacing.spacing8),

                    // User ID (익명 식별)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint,
                          size: 16,
                          color: AppColors.onSurfaceVariant,
                        ),
                        SizedBox(width: AppSpacing.spacing4),
                        Text(
                          l10n.profileUserIdLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.spacing16),

                    // 알림 상태 요약
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing12,
                        vertical: AppSpacing.spacing8,
                      ),
                      decoration: BoxDecoration(
                        color: notificationState.unreadCount > 0
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            notificationState.unreadCount > 0
                                ? Icons.notifications_active
                                : Icons.notifications_none,
                            size: 18,
                            color: notificationState.unreadCount > 0
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                          SizedBox(width: AppSpacing.spacing8),
                          Text(
                            notificationState.unreadCount > 0
                                ? '${notificationState.unreadCount} ${l10n.notificationsUnread}'
                                : l10n.notificationsEmpty,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: notificationState.unreadCount > 0
                                      ? AppColors.warning
                                      : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: AppSpacing.spacing24),

            // 메뉴 카드
            Card(
              color: AppColors.surface,
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.send,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      l10n.journeyListCta,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () => context.push(AppRoutes.journeyList),
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
                        Icons.settings,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      l10n.settingsCta,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                          ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                    ),
                    onTap: () => context.push(AppRoutes.settings),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.spacing24),

            // 로그아웃 버튼 (위험 행동 - 확인 다이얼로그)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () => _confirmSignOut(context, ref, l10n),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 18),
                    SizedBox(width: AppSpacing.spacing8),
                    Text(l10n.profileSignOutCta),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.profileSignOutTitle,
      message: l10n.profileSignOutMessage,
      confirmLabel: l10n.profileSignOutConfirm,
      cancelLabel: l10n.composeCancel,
    );

    if (confirmed == true) {
      ref.read(sessionManagerProvider.notifier).signOut();
    }
  }
}
