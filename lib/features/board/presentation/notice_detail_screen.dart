import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router/app_router.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../app/theme/app_radius.dart';
import '../../../core/common_codes/common_code_constants.dart';
import '../../../core/common_codes/common_codes_provider.dart';
import '../../../core/presentation/widgets/app_header.dart';
import '../../../core/presentation/widgets/app_scaffold.dart';
import '../../../core/presentation/widgets/error_state.dart';
import '../../../core/presentation/widgets/loading_overlay.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../l10n/app_localizations.dart';
import '../application/board_posts_provider.dart';

class NoticeDetailScreen extends ConsumerWidget {
  const NoticeDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final postAsync = ref.watch(boardPostDetailProvider(postId));
    final typeCodesAsync =
        ref.watch(commonCodesProvider(CommonCodeType.noticeType));
    final typeCodes = typeCodesAsync.value ?? const [];
    final typeLabelMap = {
      for (final code in typeCodes) code.codeValue: code.resolveLabel(locale),
    };

    return AppScaffold(
      appBar: AppHeader(
        title: l10n.noticeDetailTitle,
        leadingIcon: Icons.arrow_back,
        onLeadingTap: () => _handleBack(context),
        leadingSemanticLabel: MaterialLocalizations.of(
          context,
        ).backButtonTooltip,
      ),
      bodyPadding: EdgeInsets.zero,
      body: postAsync.when(
        loading: () => const LoadingOverlay(
          isLoading: true,
          child: SizedBox.expand(),
        ),
        error: (error, stackTrace) => ErrorStateWidget(
          icon: Icons.wifi_off,
          title: l10n.noticeErrorTitle,
          description: l10n.noticeErrorDescription,
          actionLabel: l10n.errorRetry,
          onRetry: () => ref.refresh(boardPostDetailProvider(postId)),
        ),
        data: (post) {
          final typeLabel = post.typeCode == null
              ? l10n.noticeTypeUnknown
              : (typeLabelMap[post.typeCode] ?? post.typeCode!);
          final publishedLabel =
              AnnouncementDateFormatter.formatLocalDateTime(
            post.publishedAt,
            locale,
            pattern: DateFormat.yMMMd(locale),
          );

          return ListView(
            padding: AppSpacing.pagePadding.copyWith(bottom: AppSpacing.xl),
            children: [
              Row(
                children: [
                  _NoticeTypeChip(
                    label: typeLabel,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .secondaryContainer,
                    foregroundColor: Theme.of(context)
                        .colorScheme
                        .onSecondaryContainer,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    publishedLabel,
                    style: AppTextStyles.meta.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (post.isPinned)
                    _NoticePinnedBadge(
                      label: l10n.noticePinnedBadge,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                post.title,
                style: AppTextStyles.titleMd.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                post.content,
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }
}

class _NoticeTypeChip extends StatelessWidget {
  const _NoticeTypeChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        label,
        style: AppTextStyles.meta.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _NoticePinnedBadge extends StatelessWidget {
  const _NoticePinnedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: AppRadius.small,
      ),
      child: Text(
        label,
        style: AppTextStyles.meta.copyWith(
          color: colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
