import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';

/// 프로필 탭 화면
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionState = ref.watch(sessionManagerProvider);
    final displayName = l10n.profileDefaultNickname;
    final providerLabel = _resolveProviderLabel(l10n, null);
    final isLoading = sessionState.status == SessionStatus.unknown ||
        sessionState.status == SessionStatus.refreshing;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppHeader(
        title: l10n.tabProfileLabel,
        alignLeft: true,
        extraTopPadding: AppSpacing.spacing8,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _ProfileHeaderCard(
              l10n: l10n,
              displayName: displayName,
              providerLabel: providerLabel,
              isLoading: isLoading,
              photoUrl: null,
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Semantics(
              button: true,
              label: l10n.profileEditCta,
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: AppFilledButton(
                  onPressed: () => _showFeaturePreparingDialog(context, l10n),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: AppSpacing.spacing8),
                      Text(l10n.profileEditCta),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing20),
            _SettingsMenuCard(
              l10n: l10n,
              items: [
                _SettingsMenuItem(
                  icon: Icons.notifications_outlined,
                  iconBackground: AppColors.primary.withValues(alpha: 0.12),
                  iconColor: AppColors.primary,
                  title: l10n.profileMenuNotifications,
                  onTap: () => context.push(AppRoutes.settings),
                ),
                _SettingsMenuItem(
                  icon: Icons.campaign_outlined,
                  iconBackground: AppColors.secondary.withValues(alpha: 0.12),
                  iconColor: AppColors.secondary,
                  title: l10n.profileMenuNotices,
                  onTap: () => context.push(AppRoutes.notifications),
                ),
                _SettingsMenuItem(
                  icon: Icons.volunteer_activism_outlined,
                  iconBackground: AppColors.warning.withValues(alpha: 0.12),
                  iconColor: AppColors.warning,
                  title: l10n.profileMenuSupport,
                  onTap: () => context.push(AppRoutes.support),
                ),
                _SettingsMenuItem(
                  icon: Icons.info_outline,
                  iconBackground: AppColors.surfaceVariant,
                  iconColor: AppColors.onSurfaceVariant,
                  title: l10n.profileMenuAppInfo,
                  onTap: () => context.push(AppRoutes.appInfo),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing24),
            _DangerActionSection(
              l10n: l10n,
              onSignOut: () => _confirmSignOut(context, ref, l10n),
              onWithdraw: () => _confirmWithdraw(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveProviderLabel(AppLocalizations l10n, String? provider) {
    switch (provider) {
      case 'google':
        return l10n.profileLoginProviderGoogle;
      case 'apple':
        return l10n.profileLoginProviderApple;
      case 'email':
        return l10n.profileLoginProviderEmail;
      default:
        return l10n.profileLoginProviderUnknown;
    }
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

  Future<void> _confirmWithdraw(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.profileWithdrawTitle,
      message: l10n.profileWithdrawMessage,
      confirmLabel: l10n.profileWithdrawConfirm,
      cancelLabel: l10n.composeCancel,
    );

    if (confirmed == true && context.mounted) {
      await _showFeaturePreparingDialog(context, l10n);
    }
  }

  Future<void> _showFeaturePreparingDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) {
      return;
    }
    await showAppAlertDialog(
      context: context,
      title: l10n.profileFeaturePreparingTitle,
      message: l10n.profileFeaturePreparingBody,
      confirmLabel: l10n.commonOk,
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.l10n,
    required this.displayName,
    required this.providerLabel,
    required this.isLoading,
    required this.photoUrl,
  });

  final AppLocalizations l10n;
  final String displayName;
  final String providerLabel;
  final bool isLoading;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceVariant,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Row(
          children: [
            Semantics(
              image: true,
              label: l10n.profileAvatarSemantics,
              child: _ProfileAvatar(
                displayName: displayName,
                photoUrl: photoUrl,
                isLoading: isLoading,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: isLoading
                  ? _ProfileHeaderSkeleton()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.spacing8),
                        Text(
                          providerLabel,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.photoUrl,
    required this.isLoading,
  });

  final String displayName;
  final String? photoUrl;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surfaceDim,
          shape: BoxShape.circle,
        ),
      );
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : '?';
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 32,
        backgroundImage: NetworkImage(photoUrl!),
        backgroundColor: AppColors.surfaceVariant,
      );
    }
    return CircleAvatar(
      radius: 32,
      backgroundColor: AppColors.primaryContainer,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 140,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Container(
          width: 110,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.surfaceDim,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuItem {
  const _SettingsMenuItem({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
}

class _SettingsMenuCard extends StatelessWidget {
  const _SettingsMenuCard({
    required this.l10n,
    required this.items,
  });

  final AppLocalizations l10n;
  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(
          color: AppColors.outlineVariant,
        ),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing4,
                ),
                minLeadingWidth: 0,
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 22),
                ),
                title: Text(
                  item.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                      ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: item.onTap,
              ),
              if (index != items.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.divider,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _DangerActionSection extends StatelessWidget {
  const _DangerActionSection({
    required this.l10n,
    required this.onSignOut,
    required this.onWithdraw,
  });

  final AppLocalizations l10n;
  final VoidCallback onSignOut;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: onSignOut,
            icon: Icon(Icons.logout, color: AppColors.error),
            label: Text(
              l10n.profileSignOutCta,
              style: TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.error),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: onWithdraw,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.outline),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.medium,
              ),
            ),
            child: Text(
              l10n.profileWithdrawCta,
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
        ),
      ],
    );
  }
}
