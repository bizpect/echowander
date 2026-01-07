import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/presentation/widgets/app_button.dart';

/// 하단 액션 바
///
/// 전송 버튼과 상태 정보를 표시하는 고정 하단 바입니다.
class ComposeBottomBar extends StatelessWidget {
  const ComposeBottomBar({
    super.key,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
        child: AppFilledButton(
          onPressed: canSubmit && !isSubmitting ? onSubmit : null,
          isLoading: isSubmitting,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              l10n.composeSubmit,
              textAlign: TextAlign.center,
              style: AppTypography.labelLarge.copyWith(
                color: canSubmit && !isSubmitting
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceDim,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

