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
    final current = recipientCount;

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
                    color: AppColors.secondaryContainer,
                    borderRadius: AppRadius.small,
                  ),
                  child: Text(
                    l10n.composeRecipientCountOption(recipientCount!),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          // Playful Picker: 칩 + 미니 슬라이더
          Wrap(
            spacing: AppSpacing.spacing8,
            runSpacing: AppSpacing.spacing8,
            children: [
              for (var i = 1; i <= 5; i += 1)
                _RecipientChip(
                  label: l10n.composeRecipientCountOption(i),
                  isSelected: current == i,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.secondary,
                    inactiveTrackColor:
                        AppColors.outlineVariant.withValues(alpha: 0.9),
                    thumbColor: AppColors.secondary,
                    overlayColor: AppColors.secondary.withValues(alpha: 0.16),
                  ),
                  child: Slider(
                    min: 1,
                    max: 5,
                    divisions: 4,
                    value: (current ?? 3).toDouble(),
                    onChanged: (value) => onChanged(value.round()),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing8,
                  vertical: AppSpacing.spacing4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.small,
                  border: Border.all(color: AppColors.outlineVariant),
                ),
                child: Text(
                  l10n.composeRecipientCountOption(current ?? 3),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            l10n.composeRecipientCountHint,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipientChip extends StatelessWidget {
  const _RecipientChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: isSelected ? 1.04 : 1.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.full,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing12,
              vertical: AppSpacing.spacing8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: AppRadius.full,
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary.withValues(alpha: 0.55)
                    : AppColors.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.onSecondaryContainer
                      : AppColors.onSurface,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

