import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_icon_badge.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../l10n/app_localizations.dart';

class AppInfoScreen extends StatefulWidget {
  const AppInfoScreen({super.key});

  @override
  State<AppInfoScreen> createState() => _AppInfoScreenState();
}

class _AppInfoScreenState extends State<AppInfoScreen> {
  String? _version;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) {
        return;
      }
      setState(() {
        _version = info.version;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _version = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = _version ?? l10n.appInfoVersionUnknown;

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.appInfoTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        leadingSemanticLabel: MaterialLocalizations.of(
          context,
        ).backButtonTooltip,
      ),
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: AppSpacing.pagePadding.copyWith(bottom: AppSpacing.xxl),
        children: [
          AppInfoVersionCard(versionLabel: l10n.appInfoVersionLabel(version)),
          const SizedBox(height: AppSpacing.lg),
          AppInfoOpenLicenseTile(version: version),
          const SizedBox(height: AppSpacing.lg),
          _AppInfoRelatedAppsExpansion(
            items: [
              _RelatedAppItem(
                title: l10n.appInfoRelatedApp1Title,
                description: l10n.appInfoRelatedApp1Description,
              ),
              _RelatedAppItem(
                title: l10n.appInfoRelatedApp2Title,
                description: l10n.appInfoRelatedApp2Description,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppInfoVersionCard extends StatelessWidget {
  const AppInfoVersionCard({super.key, required this.versionLabel});

  final String versionLabel;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const AppIconBadge(
            icon: Icons.apps,
            backgroundColor: AppColors.primaryContainer,
            iconColor: AppColors.onPrimaryContainer,
            size: 72,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            versionLabel,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class AppInfoOpenLicenseTile extends StatelessWidget {
  const AppInfoOpenLicenseTile({super.key, required this.version});

  final String version;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCardRow(
      title: l10n.appInfoOpenLicenseTitle,
      leading: const AppIconBadge(
        icon: Icons.library_books_outlined,
        backgroundColor: AppColors.surfaceVariant,
        iconColor: AppColors.onSurfaceVariant,
        size: 40,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.iconMuted,
        size: 18,
      ),
      onTap: () => context.push(AppRoutes.openLicense),
    );
  }
}

class _RelatedAppItem {
  const _RelatedAppItem({required this.title, required this.description});

  final String title;
  final String description;
}

class _AppInfoRelatedAppsExpansion extends StatelessWidget {
  const _AppInfoRelatedAppsExpansion({required this.items});

  final List<_RelatedAppItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderSubtle,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          collapsedIconColor: AppColors.iconMuted,
          iconColor: AppColors.iconMuted,
          title: Text(
            l10n.appInfoRelatedAppsTitle,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : AppSpacing.sm,
              ),
              child: _RelatedAppRow(item: item),
            );
          }),
        ),
      ),
    );
  }
}

class _RelatedAppRow extends StatelessWidget {
  const _RelatedAppRow({required this.item});

  final _RelatedAppItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCardRow(
      title: item.title,
      subtitle: item.description,
      leading: const AppIconBadge(
        icon: Icons.apps,
        backgroundColor: AppColors.surfaceVariant,
        iconColor: AppColors.onSurfaceVariant,
        size: 40,
      ),
      trailing: Semantics(
        button: true,
        label: l10n.appInfoExternalLinkLabel,
        child: const Icon(
          Icons.open_in_new,
          color: AppColors.iconMuted,
          size: 18,
        ),
      ),
      onTap: () => _showPreparingDialog(context, l10n),
    );
  }

  Future<void> _showPreparingDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!context.mounted) {
      return;
    }
    await showAppAlertDialog(
      context: context,
      title: l10n.appInfoLinkPreparingTitle,
      message: l10n.appInfoLinkPreparingBody,
      confirmLabel: l10n.commonOk,
    );
  }
}
