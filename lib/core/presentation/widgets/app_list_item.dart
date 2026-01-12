import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import 'app_card.dart';

/// 공통 리스트 아이템
class AppListItem extends StatelessWidget {
  const AppListItem({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.meta,
    this.status,
    this.trailing,
    this.onTap,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final String? meta;
  final Widget? status;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      borderColor: isHighlighted ? AppColors.primary : null,
      borderWidth: 1.5,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center, // ✅ 세로 중앙 정렬
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center, // ✅ 세로 중앙 정렬
            children: [
              if (meta != null)
                Text(
                  meta!,
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              if (status != null) ...[
                const SizedBox(height: AppSpacing.xs),
                status!,
              ],
              if (trailing != null) ...[
                if (status != null || meta != null)
                  const SizedBox(height: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
        ],
      ),
      ),
    );
  }
}
