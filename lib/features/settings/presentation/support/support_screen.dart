import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_header.dart';
import '../../../../core/presentation/widgets/app_icon_badge.dart';
import '../../../../core/presentation/widgets/app_scaffold.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/support_email_service.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
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

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.supportTitle,
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
          const SizedBox(height: AppSpacing.sm),
          const _SupportStatusCard(),
          const SizedBox(height: AppSpacing.lg),
          _SupportReleaseNotesTile(version: version),
          const SizedBox(height: AppSpacing.xl),
          _SupportCtaButtons(
            onSuggestion: () => SupportEmailService.composeSuggestion(context, ref),
            onBug: () => SupportEmailService.composeBug(context, ref),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: EdgeInsets.only(
              left: 0,
              top: AppSpacing.sm,
              right: AppSpacing.screenPaddingHorizontal,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              l10n.supportFaqTitle,
              style: AppTextStyles.titleMd.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SupportFaqSection(
            items: [
              _FaqItem(question: l10n.supportFaqQ1, answer: l10n.supportFaqA1),
              _FaqItem(question: l10n.supportFaqQ2, answer: l10n.supportFaqA2),
              _FaqItem(question: l10n.supportFaqQ3, answer: l10n.supportFaqA3),
              _FaqItem(question: l10n.supportFaqQ4, answer: l10n.supportFaqA4),
              _FaqItem(question: l10n.supportFaqQ5, answer: l10n.supportFaqA5),
            ],
          ),
        ],
      ),
    );
  }

}

class _SupportStatusCard extends StatelessWidget {
  const _SupportStatusCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          const AppIconBadge(
            icon: Icons.verified_outlined,
            backgroundColor: AppColors.primaryContainer,
            iconColor: AppColors.onPrimaryContainer,
            size: 44,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              l10n.supportStatusMessage,
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
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
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: AppColors.borderSubtle,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
        child: ExpansionTile(
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
            l10n.supportReleaseNotesTitle,
            style: AppTextStyles.bodyStrong.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            l10n.supportReleaseNotesHeader(version),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          children: [
            Text(
              l10n.supportReleaseNotesBody,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCtaButtons extends StatelessWidget {
  const _SupportCtaButtons({
    required this.onSuggestion,
    required this.onBug,
  });

  final Future<void> Function() onSuggestion;
  final Future<void> Function() onBug;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Semantics(
          button: true,
          label: l10n.supportSuggestCta,
          child: AppCardRow(
            title: l10n.supportSuggestCta,
            leading: const AppIconBadge(
              icon: Icons.lightbulb_outline,
              backgroundColor: AppColors.primaryContainer,
              iconColor: AppColors.onPrimaryContainer,
              size: 40,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
              size: 18,
            ),
            onTap: onSuggestion,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Semantics(
          button: true,
          label: l10n.supportReportCta,
          child: AppCardRow(
            title: l10n.supportReportCta,
            leading: const AppIconBadge(
              icon: Icons.bug_report_outlined,
              backgroundColor: AppColors.errorContainer,
              iconColor: AppColors.onErrorContainer,
              size: 40,
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.iconMuted,
              size: 18,
            ),
            onTap: onBug,
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
            bottom: index == items.length - 1 ? 0 : AppSpacing.sm,
          ),
          child: AppCard(
            padding: EdgeInsets.zero,
            borderColor: AppColors.borderSubtle,
            child: Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: AppColors.transparent),
              child: ExpansionTile(
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
                  item.question,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                children: [
                  Text(
                    item.answer,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
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
