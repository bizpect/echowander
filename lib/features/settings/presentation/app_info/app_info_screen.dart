import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.appInfoTitle),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            AppInfoVersionCard(versionLabel: l10n.appInfoVersionLabel(version)),
            const SizedBox(height: AppSpacing.spacing16),
            AppInfoOpenLicenseTile(version: version),
            const SizedBox(height: AppSpacing.spacing16),
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
      ),
    );
  }
}

class AppInfoVersionCard extends StatelessWidget {
  const AppInfoVersionCard({super.key, required this.versionLabel});

  final String versionLabel;

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
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing20),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.apps,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              versionLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
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
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing16,
          vertical: AppSpacing.spacing4,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.library_books_outlined,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        title: Text(
          l10n.appInfoOpenLicenseTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.onSurface,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.onSurfaceVariant,
        ),
        onTap: () => context.push(AppRoutes.openLicense),
      ),
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
    return Card(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.large,
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedIconColor: AppColors.onSurfaceVariant,
          iconColor: AppColors.onSurfaceVariant,
          title: Text(
            l10n.appInfoRelatedAppsTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          children: List.generate(items.length, (index) {
            final item = items[index];
            return Column(
              children: [
                _RelatedAppRow(item: item),
                if (index != items.length - 1)
                  Divider(
                    height: 1,
                    color: AppColors.divider,
                  ),
              ],
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
    return InkWell(
      onTap: () => _showPreparingDialog(context, l10n),
      borderRadius: AppRadius.medium,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.spacing4),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Semantics(
              button: true,
              label: l10n.appInfoExternalLinkLabel,
              child: Icon(
                Icons.open_in_new,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
