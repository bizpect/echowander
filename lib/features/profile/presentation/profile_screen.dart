import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_button.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_icon_badge.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/app_skeleton.dart';
import '../../../core/presentation/navigation/tab_navigation_helper.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/session/session_state.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/domain/auth_provider.dart';
import '../application/avatar_signed_url_provider.dart';
import '../application/profile_provider.dart';

/// 프로필 탭 화면
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sessionState = ref.watch(sessionManagerProvider);
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;
    final displayName = (profile?.nickname?.trim().isNotEmpty ?? false)
        ? profile!.nickname!.trim()
        : l10n.profileDefaultNickname;
    final providerLabel = _resolveProviderLabel(
      l10n,
      authProviderFromString(sessionState.loginProvider),
    );
    if (kDebugMode) {
      debugPrint(
        '[ProfileScreen] loginProvider=${sessionState.loginProvider}',
      );
      debugPrint('[ProfileScreen] loginLabel=$providerLabel');
    }
    final isLoading =
        sessionState.bootState == SessionBootState.booting ||
        profileAsync.isLoading;
    final avatarSignedUrlAsync = ref.watch(
      avatarSignedUrlProvider(profile?.avatarPath),
    );
    final photoUrl = avatarSignedUrlAsync.value;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        TabNavigationHelper.goToHomeTab(context, ref);
      },
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.tabProfileLabel,
          alignTitleLeft: true,
        ),
        bodyPadding: EdgeInsets.zero,
        body: ListView(
          padding: AppSpacing.pagePadding.copyWith(bottom: AppSpacing.xxl),
          children: [
            _ProfileHeaderCard(
              l10n: l10n,
              displayName: displayName,
              providerLabel: providerLabel,
              isLoading: isLoading,
              photoUrl: photoUrl,
            ),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              button: true,
              label: l10n.profileEditCta,
              child: SizedBox(
                height: AppSpacing.minTouchTarget,
                width: double.infinity,
                child: AppFilledButton(
                  onPressed: () => context.push(AppRoutes.profileEdit),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.profileEditCta),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SettingsMenuCard(
              items: [
                _SettingsMenuItem(
                  icon: Icons.notifications_outlined,
                  iconBackground: AppColors.primaryContainer,
                  iconColor: AppColors.onPrimaryContainer,
                  title: l10n.profileAppSettings,
                  onTap: () => context.push(AppRoutes.settings),
                ),
                _SettingsMenuItem(
                  icon: Icons.campaign_outlined,
                  iconBackground: AppColors.secondaryContainer,
                  iconColor: AppColors.onSecondaryContainer,
                  title: l10n.profileMenuNotices,
                  onTap: () => context.push(AppRoutes.notice),
                ),
                _SettingsMenuItem(
                  icon: Icons.volunteer_activism_outlined,
                  iconBackground: AppColors.warningContainer,
                  iconColor: AppColors.onWarningContainer,
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
            const SizedBox(height: AppSpacing.xl),
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

  String _resolveProviderLabel(
    AppLocalizations l10n,
    AuthProviderType provider,
  ) {
    return authProviderLoginLabel(l10n, provider);
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

  Future<void> _confirmWithdraw(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: isLoading
                ? const _ProfileHeaderSkeleton()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMd.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        providerLabel,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
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
      return Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _FallbackAvatarContent(initial: initial);
          },
        ),
      );
    }
    return _FallbackAvatarContent(initial: initial);
  }
}

class _FallbackAvatarContent extends StatelessWidget {
  const _FallbackAvatarContent({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.titleMd.copyWith(
          color: AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  const _ProfileHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSkeleton(width: 140, height: 18),
        const SizedBox(height: AppSpacing.sm),
        const AppSkeleton(width: 110, height: 14),
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
  const _SettingsMenuCard({required this.items});

  final List<_SettingsMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCardRow(
            title: item.title,
            leading: AppIconBadge(
              icon: item.icon,
              backgroundColor: item.iconBackground,
              iconColor: item.iconColor,
              size: 40,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
              size: 18,
            ),
            onTap: item.onTap,
          ),
        );
      }),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: AppSpacing.minTouchTarget,
          width: double.infinity,
          child: AppOutlinedButton(
            onPressed: onSignOut,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: colorScheme.error),
          ),
            child: Center(
              child: Text(
                l10n.profileSignOutCta,
                style: TextStyle(
                  color: colorScheme.error,
                ),
          ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: AppSpacing.minTouchTarget,
          width: double.infinity,
          child: AppFilledButton(
            onPressed: onWithdraw,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
            ),
            child: Center(
              child: Text(
                l10n.profileWithdrawCta,
                style: TextStyle(
                  color: colorScheme.onError,
                ),
          ),
            ),
          ),
        ),
      ],
    );
  }
}
