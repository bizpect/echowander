import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/presentation/widgets/app_dialog.dart';
import '../../../../l10n/app_localizations.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
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
    final version = _version ?? l10n.supportVersionUnknown;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.supportTitle),
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
            const SizedBox(height: AppSpacing.spacing8),
            const _SupportStatusCard(),
            const SizedBox(height: AppSpacing.spacing16),
            _SupportReleaseNotesTile(version: version),
            const SizedBox(height: AppSpacing.spacing20),
            _SupportCtaButtons(onAction: _showPreparingDialog),
            const SizedBox(height: AppSpacing.spacing24),
            Text(
              l10n.supportFaqTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.spacing12),
            _SupportFaqSection(
              items: [
                _FaqItem(
                  question: l10n.supportFaqQ1,
                  answer: l10n.supportFaqA1,
                ),
                _FaqItem(
                  question: l10n.supportFaqQ2,
                  answer: l10n.supportFaqA2,
                ),
                _FaqItem(
                  question: l10n.supportFaqQ3,
                  answer: l10n.supportFaqA3,
                ),
                _FaqItem(
                  question: l10n.supportFaqQ4,
                  answer: l10n.supportFaqA4,
                ),
                _FaqItem(
                  question: l10n.supportFaqQ5,
                  answer: l10n.supportFaqA5,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPreparingDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (!context.mounted) {
      return;
    }
    await showAppAlertDialog(
      context: context,
      title: l10n.supportActionPreparingTitle,
      message: l10n.supportActionPreparingBody,
      confirmLabel: l10n.commonOk,
    );
  }
}

class _SupportStatusCard extends StatelessWidget {
  const _SupportStatusCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.large,
        color: AppColors.surface,
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
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.verified_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: Text(
                l10n.supportStatusMessage,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportReleaseNotesTile extends StatelessWidget {
  const _SupportReleaseNotesTile({required this.version});

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
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing16,
            vertical: AppSpacing.spacing8,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          collapsedIconColor: AppColors.onSurfaceVariant,
          iconColor: AppColors.onSurfaceVariant,
          title: Text(
            l10n.supportReleaseNotesTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
          ),
          subtitle: Text(
            l10n.supportReleaseNotesHeader(version),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          children: [
            Text(
              l10n.supportReleaseNotesBody,
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
}

class _SupportCtaButtons extends StatelessWidget {
  const _SupportCtaButtons({required this.onAction});

  final Future<void> Function(BuildContext context) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Semantics(
          button: true,
          label: l10n.supportSuggestCta,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onAction(context),
              icon: const Icon(Icons.lightbulb_outline),
              label: Text(l10n.supportSuggestCta),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing12),
        Semantics(
          button: true,
          label: l10n.supportReportCta,
          child: SizedBox(
            height: 56,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => onAction(context),
              icon: const Icon(Icons.bug_report_outlined),
              label: Text(l10n.supportReportCta),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.medium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}

class _SupportFaqSection extends StatelessWidget {
  const _SupportFaqSection({required this.items});

  final List<_FaqItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index == items.length - 1 ? 0 : AppSpacing.spacing12,
          ),
          child: Card(
            color: AppColors.surface,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.large,
              side: BorderSide(color: AppColors.outlineVariant),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing16,
                  vertical: AppSpacing.spacing8,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                collapsedIconColor: AppColors.onSurfaceVariant,
                iconColor: AppColors.onSurfaceVariant,
                title: Text(
                  item.question,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                children: [
                  Text(
                    item.answer,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          height: 1.5,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
