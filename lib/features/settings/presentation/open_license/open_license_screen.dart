import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_pill.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../core/presentation/widgets/app_section.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/open_license_service.dart';
import '../../domain/open_license_item.dart';
import 'open_license_detail_screen.dart';

final openLicenseServiceProvider = Provider<OpenLicenseService>((ref) {
  return OpenLicenseService();
});

class OpenLicenseScreen extends ConsumerStatefulWidget {
  const OpenLicenseScreen({super.key});

  @override
  ConsumerState<OpenLicenseScreen> createState() => _OpenLicenseScreenState();
}

class _OpenLicenseScreenState extends ConsumerState<OpenLicenseScreen> {
  late Future<List<OpenLicenseItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(openLicenseServiceProvider).loadLicenses();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.openLicenseTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        leadingSemanticLabel: MaterialLocalizations.of(
          context,
        ).backButtonTooltip,
      ),
      bodyPadding: EdgeInsets.zero,
      body: FutureBuilder<List<OpenLicenseItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          return ListView(
            padding: AppSpacing.pagePadding.copyWith(bottom: AppSpacing.xxl),
            children: [
              _OpenLicenseHeaderCard(
                title: l10n.openLicenseHeaderTitle,
                body: l10n.openLicenseHeaderBody,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSection(
                title: l10n.openLicenseSectionTitle,
                subtitle: l10n.openLicenseSectionSubtitle,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (items.isEmpty)
                AppEmptyState(
                  icon: Icons.library_books_outlined,
                  title: l10n.openLicenseEmptyMessage,
                )
              else
                ...items.map((item) => _OpenLicenseCard(item: item)),
            ],
          );
        },
      ),
    );
  }
}

class _OpenLicenseHeaderCard extends StatelessWidget {
  const _OpenLicenseHeaderCard({required this.title, required this.body});

  final String title;
  final String body;

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
          Text(
            body,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpenLicenseCard extends StatelessWidget {
  const _OpenLicenseCard({required this.item});

  final OpenLicenseItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = item.version.isEmpty
        ? l10n.openLicenseUnknown
        : item.version;
    final licenseLabel = _resolveLicenseLabel(l10n, item.licenseType);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        borderColor: AppColors.borderSubtle,
        onTap: () {
          if (kDebugMode) {
            debugPrint(
              '[OpenLicense] tap: package=${item.packageName}, version=${item.version}, type=${item.licenseType}',
            );
          }
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OpenLicenseDetailScreen(item: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.packageName,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppPill(
                  label: l10n.openLicenseChipVersion(version),
                  tone: AppPillTone.neutral,
                ),
                AppPill(
                  label: l10n.openLicenseChipLicense(licenseLabel),
                  tone: AppPillTone.neutral,
                ),
                AppPill(
                  label: l10n.openLicenseChipDetails,
                  tone: AppPillTone.neutral,
                ),
              ],
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
