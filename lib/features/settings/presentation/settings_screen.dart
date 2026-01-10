import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/locale/locale_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/presentation/widgets/app_dialog.dart';
import '../../../core/presentation/widgets/app_card.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_icon_badge.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/app_section.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';
import 'widgets/language_selection_bottom_sheet.dart';
import 'widgets/theme_selection_bottom_sheet.dart';

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
    Future.microtask(
      () => ref.read(settingsControllerProvider.notifier).load(),
    );
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
      child: AppScaffold(
        appBar: AppHeader(
          title: l10n.settingsTitle,
          leadingIcon: Icons.arrow_back,
          onLeadingTap: () => _handleBack(context),
          leadingSemanticLabel: MaterialLocalizations.of(
            context,
          ).backButtonTooltip,
        ),
        bodyPadding: EdgeInsets.zero,
        body: LoadingOverlay(
          isLoading: state.isLoading,
          child: ListView(
            padding: AppSpacing.pagePadding.copyWith(bottom: AppSpacing.xl),
            children: [
              AppCard(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: SwitchListTile.adaptive(
                  value: state.notificationsEnabled,
                  onChanged: state.isLoading
                      ? null
                      : controller.updateNotifications,
                  title: Text(
                    l10n.settingsNotificationToggle,
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    l10n.settingsNotificationHint,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCardRow(
                title: l10n.settingsLanguage,
                leading: const AppIconBadge(
                  icon: Icons.language,
                  backgroundColor: AppColors.primaryContainer,
                  iconColor: AppColors.onPrimaryContainer,
                  size: 40,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getLanguageLabel(
                        l10n,
                        ref.watch(localeControllerProvider.notifier).getCurrentLanguageCode(),
                      ),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.iconMuted,
                      size: 18,
                    ),
                  ],
                ),
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => const LanguageSelectionBottomSheet(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppCardRow(
                title: l10n.settingsTheme,
                leading: const AppIconBadge(
                  icon: Icons.palette,
                  backgroundColor: AppColors.secondaryContainer,
                  iconColor: AppColors.onSecondaryContainer,
                  size: 40,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getThemeLabel(
                        l10n,
                        ref.watch(themeControllerProvider),
                      ),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.iconMuted,
                      size: 18,
                    ),
                  ],
                ),
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => const ThemeSelectionBottomSheet(),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              AppSection(
                title: l10n.settingsSectionSafety,
              ),
              AppCardRow(
                title: l10n.settingsBlockedUsers,
                leading: const AppIconBadge(
                  icon: Icons.block,
                  backgroundColor: AppColors.errorContainer,
                  iconColor: AppColors.onErrorContainer,
                  size: 40,
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.iconMuted,
                  size: 18,
                ),
                onTap: () => context.go(AppRoutes.blockList),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMessage(
    AppLocalizations l10n,
    SettingsMessage message,
  ) async {
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

  String _getLanguageLabel(AppLocalizations l10n, String code) {
    switch (code) {
      case 'system':
        return l10n.languageSystem;
      case 'ko':
        return l10n.languageKorean;
      case 'en':
        return l10n.languageEnglish;
      case 'ja':
        return l10n.languageJapanese;
      case 'es':
        return l10n.languageSpanish;
      case 'fr':
        return l10n.languageFrench;
      case 'pt':
        return l10n.languagePortuguese;
      case 'zh':
        return l10n.languageChinese;
      default:
        return l10n.languageSystem;
    }
  }

  String _getThemeLabel(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        // system은 더 이상 지원하지 않으므로 dark로 처리
        return l10n.themeDark;
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
    }
  }
}
