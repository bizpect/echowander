import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.openLicenseTitle),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<OpenLicenseItem>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _OpenLicenseHeaderCard(
                  title: l10n.openLicenseHeaderTitle,
                  body: l10n.openLicenseHeaderBody,
                ),
                const SizedBox(height: AppSpacing.spacing16),
                if (items.isEmpty)
                  _OpenLicenseEmptyState(message: l10n.openLicenseEmptyMessage)
                else
                  ...items.map((item) => _OpenLicenseCard(item: item)),
              ],
            );
          },
        ),
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
        padding: const EdgeInsets.all(AppSpacing.spacing20),
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
            const SizedBox(height: AppSpacing.spacing8),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenLicenseEmptyState extends StatelessWidget {
  const _OpenLicenseEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing24),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
        textAlign: TextAlign.center,
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
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing16),
      child: Card(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(color: AppColors.outlineVariant),
        ),
        child: InkWell(
          borderRadius: AppRadius.large,
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
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.spacing16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.packageName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.spacing12),
                Wrap(
                  spacing: AppSpacing.spacing8,
                  runSpacing: AppSpacing.spacing8,
                  children: [
                    _LicenseChip(
                      label: l10n.openLicenseChipVersion(version),
                    ),
                    _LicenseChip(
                      label: l10n.openLicenseChipLicense(licenseLabel),
                    ),
                    _LicenseChip(
                      label: l10n.openLicenseChipDetails,
                      icon: Icons.open_in_new,
                    ),
                  ],
                ),
              ],
            ),
          ),
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

class _LicenseChip extends StatelessWidget {
  const _LicenseChip({required this.label, this.icon});

  final String label;
  final IconData? icon;

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.onSurfaceVariant),
            const SizedBox(width: AppSpacing.spacing4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
