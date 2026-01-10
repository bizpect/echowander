import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
import '../../../../core/presentation/widgets/app_pill.dart';
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: recipientCount != null
          ? AppColors.primary
          : AppColors.borderSubtle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 상태 배지
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.composeRecipientCountLabel,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              if (recipientCount != null)
                AppPill(
                  label: l10n.composeRecipientCountOption(recipientCount!),
                  tone: AppPillTone.neutral,
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
                    inactiveTrackColor: AppColors.outlineVariant,
                    thumbColor: AppColors.secondary,
                    overlayColor: AppColors.secondaryContainer,
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
                  style: AppTextStyles.meta.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing8),
          Text(
            l10n.composeRecipientCountHint,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        scale: isSelected ? 1.02 : 1.0,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.full,
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.secondaryContainer
                  : AppColors.surfaceVariant,
              borderRadius: AppRadius.full,
              border: Border.all(
                color: isSelected
                    ? AppColors.secondary
                    : AppColors.outlineVariant,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.meta.copyWith(
                  color: isSelected
                      ? AppColors.onSecondaryContainer
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
