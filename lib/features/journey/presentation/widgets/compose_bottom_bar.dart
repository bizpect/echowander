import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/app_button.dart';

/// 하단 액션 바
///
/// 3-step wizard의 Back/Next/Send CTA를 표시하는 고정 하단 바입니다.
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

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.spacing12,
        AppSpacing.screenPaddingHorizontal,
        AppSpacing.spacing12 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (stepIndex > 0) ...[
              Expanded(
                child: AppOutlinedButton(
                  onPressed: !isSubmitting ? onBack : null,
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      l10n.composeWizardBack,
                      textAlign: TextAlign.center,
                      style: AppTypography.labelLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing12),
            ],
            Expanded(
              flex: stepIndex > 0 ? 2 : 1,
              child: AppFilledButton(
                onPressed: (!isSubmitting &&
                        (isLastStep ? canSubmit : canGoNext))
                    ? (isLastStep ? onSubmit : onNext)
                    : null,
                isLoading: isLastStep ? isSubmitting : false,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    isLastStep ? l10n.composeSubmit : l10n.composeWizardNext,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelLarge.copyWith(
                      color: (!isSubmitting &&
                              (isLastStep ? canSubmit : canGoNext))
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceDim,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

