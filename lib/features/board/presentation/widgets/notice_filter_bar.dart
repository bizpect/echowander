import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';

class NoticeFilterBar extends StatelessWidget {
  const NoticeFilterBar({
    super.key,
    required this.label,
    required this.selectedLabel,
    required this.onTap,
  });

  final String label;
  final String selectedLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: AppSpacing.pagePadding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
              foregroundColor: colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: const StadiumBorder(),
              textStyle: AppTextStyles.pill,
            ),
            icon: const Icon(Icons.expand_more, size: 18),
            label: Text(selectedLabel),
          ),
        ],
      ),
    );
  }
}
