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

    // SizedBox.expand로 감싸서 외부에서 지정한 높이를 정확히 유지
    // 내부 padding으로 인해 높이가 줄어드는 것을 방지
    return SizedBox.expand(
      child: Container(
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
                // 텍스트가 2줄로 wrap되지 않도록 처리
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
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
              label: Text(
                selectedLabel,
                // 선택된 라벨도 2줄로 wrap되지 않도록 처리
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
