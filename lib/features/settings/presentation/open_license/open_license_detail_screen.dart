import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/open_license_item.dart';

class OpenLicenseDetailScreen extends StatelessWidget {
  const OpenLicenseDetailScreen({super.key, required this.item});

  final OpenLicenseItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final versionLabel = item.version.isEmpty
        ? l10n.openLicenseUnknown
        : item.version;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.openLicenseDetailTitle(item.packageName)),
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
            _DetailHeaderCard(
              title: item.packageName,
              versionLabel: l10n.openLicenseChipVersion(versionLabel),
              licenseLabel: l10n.openLicenseChipLicense(
                _resolveLicenseLabel(l10n, item.licenseType),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing16),
            Text(
              item.licenseText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveLicenseLabel(AppLocalizations l10n, OpenLicenseType type) {
    switch (type) {
      case OpenLicenseType.mit:
        return l10n.openLicenseTypeMit;
      case OpenLicenseType.apache2:
        return l10n.openLicenseTypeApache;
      case OpenLicenseType.bsd3:
        return l10n.openLicenseTypeBsd3;
      case OpenLicenseType.bsd2:
        return l10n.openLicenseTypeBsd2;
      case OpenLicenseType.mpl2:
        return l10n.openLicenseTypeMpl2;
      case OpenLicenseType.gpl:
        return l10n.openLicenseTypeGpl;
      case OpenLicenseType.lgpl:
        return l10n.openLicenseTypeLgpl;
      case OpenLicenseType.isc:
        return l10n.openLicenseTypeIsc;
      case OpenLicenseType.unknown:
        return l10n.openLicenseTypeUnknown;
    }
  }
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({
    required this.title,
    required this.versionLabel,
    required this.licenseLabel,
  });

  final String title;
  final String versionLabel;
  final String licenseLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            Wrap(
              spacing: AppSpacing.spacing8,
              runSpacing: AppSpacing.spacing8,
              children: [
                _DetailChip(label: versionLabel),
                _DetailChip(label: licenseLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing12,
        vertical: AppSpacing.spacing8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}
