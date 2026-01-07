import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';

/// 수신자 선택 카드
///
/// 릴레이 인원 수를 선택하는 카드를 표시합니다.
/// 상태(선택됨/미선택)를 시각적으로 표시합니다.
class ComposeRecipientCard extends StatelessWidget {
  const ComposeRecipientCard({
    super.key,
    required this.recipientCount,
    required this.onChanged,
  });

  final int? recipientCount;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: recipientCount != null
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.outline,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 상태 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.composeRecipientCountLabel,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (recipientCount != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing8,
                    vertical: AppSpacing.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    l10n.composeRecipientCountOption(recipientCount!),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          // 드롭다운
          DropdownButtonFormField<int>(
            key: ValueKey(recipientCount),
            initialValue: recipientCount,
            decoration: InputDecoration(
              hintText: l10n.composeRecipientCountHint,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing12,
                vertical: AppSpacing.spacing12,
              ),
              border: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.small,
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: AppColors.surfaceVariant,
            ),
            dropdownColor: AppColors.surface,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurface,
            ),
            items: List.generate(
              5,
              (index) => DropdownMenuItem(
                value: index + 1,
                child: Text(
                  l10n.composeRecipientCountOption(index + 1),
                ),
              ),
            ),
            onChanged: onChanged,
            icon: Icon(
              Icons.arrow_drop_down,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

