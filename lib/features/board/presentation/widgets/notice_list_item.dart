import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';

class NoticeListItem extends StatelessWidget {
  const NoticeListItem({
    super.key,
    required this.typeLabel,
    required this.dateLabel,
    required this.title,
    required this.preview,
    required this.isPinned,
    required this.pinnedLabel,
    required this.onTap,
  });

  final String typeLabel;
  final String dateLabel;
  final String title;
  final String preview;
  final bool isPinned;
  final String pinnedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      onTap: onTap,
      borderColor: colorScheme.outlineVariant,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _TypeChip(
                label: typeLabel,
                backgroundColor: colorScheme.secondaryContainer,
                foregroundColor: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                dateLabel,
                style: AppTextStyles.meta.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              if (isPinned)
                _PinnedBadge(
                  label: pinnedLabel,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.titleSm.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
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

class _PinnedBadge extends StatelessWidget {
  const _PinnedBadge({required this.label});

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
