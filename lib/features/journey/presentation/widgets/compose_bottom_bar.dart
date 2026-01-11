import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/app_button.dart';

/// 하단 액션 바 (토스 스타일)
///
/// 3-step wizard의 Back/Next/Send CTA를 표시하는 고정 하단 바입니다.
/// 토스 스타일: 키보드 올라와도 버튼 보이게, SafeArea 적용, 부드러운 그림자
class ComposeBottomBar extends StatelessWidget {
  const ComposeBottomBar({
    super.key,
    required this.stepIndex,
    required this.canGoNext,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  final int stepIndex;
  final bool canGoNext;
  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLastStep = stepIndex >= 2;
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: AppColors.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlaySubtle,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.spacing12,
            AppSpacing.screenPaddingHorizontal,
            AppSpacing.spacing12 + viewInsets.bottom,
          ),
          child: Row(
            children: [
              if (stepIndex > 0) ...[
                Expanded(
                  flex: 1,
                  child: Semantics(
                    label: l10n.composeWizardBack,
                    button: true,
                    enabled: !isSubmitting,
                    child: AppOutlinedButton(
                      onPressed: !isSubmitting ? onBack : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.medium,
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: Text(
                          l10n.composeWizardBack,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyStrong,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing12),
              ],
              Expanded(
                flex: 1,
                child: Semantics(
                  label: isLastStep ? l10n.composeSubmit : l10n.composeWizardNext,
                  button: true,
                  enabled: !isSubmitting && (isLastStep ? canSubmit : canGoNext),
                  child: AppFilledButton(
                    onPressed:
                        (!isSubmitting && (isLastStep ? canSubmit : canGoNext))
                            ? (isLastStep ? onSubmit : onNext)
                            : null,
                    isLoading: isLastStep ? isSubmitting : false,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.medium,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        isLastStep ? l10n.composeSubmit : l10n.composeWizardNext,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color:
                              (!isSubmitting &&
                                      (isLastStep ? canSubmit : canGoNext))
                                  ? AppColors.onPrimary
                                  : AppColors.onSurfaceDim,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
