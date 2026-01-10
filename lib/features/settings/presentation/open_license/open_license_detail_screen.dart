import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_pill.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
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

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.openLicenseDetailTitle(item.packageName),
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
          _DetailHeaderCard(
            title: item.packageName,
            versionLabel: l10n.openLicenseChipVersion(versionLabel),
            licenseLabel: l10n.openLicenseChipLicense(
              _resolveLicenseLabel(l10n, item.licenseType),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            item.licenseText,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleSm.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppPill(label: versionLabel, tone: AppPillTone.neutral),
              AppPill(label: licenseLabel, tone: AppPillTone.neutral),
            ],
          ),
        ],
      ),
    );
  }
}
