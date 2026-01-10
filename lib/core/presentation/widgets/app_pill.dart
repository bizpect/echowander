import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

enum AppPillTone { neutral, success, warning, danger }

/// 상태 배지 공통 컴포넌트
class AppPill extends StatelessWidget {
  const AppPill({
    super.key,
    required this.label,
    this.tone = AppPillTone.neutral,
  });

  final String label;
  final AppPillTone tone;

  Color _backgroundColor() {
    switch (tone) {
      case AppPillTone.success:
        return AppColors.pillSuccessBackground;
      case AppPillTone.warning:
        return AppColors.pillWarningBackground;
      case AppPillTone.danger:
        return AppColors.pillDangerBackground;
      case AppPillTone.neutral:
        return AppColors.pillNeutralBackground;
    }
  }

  Color _foregroundColor() {
    switch (tone) {
      case AppPillTone.success:
        return AppColors.pillSuccessForeground;
      case AppPillTone.warning:
        return AppColors.pillWarningForeground;
      case AppPillTone.danger:
        return AppColors.pillDangerForeground;
      case AppPillTone.neutral:
        return AppColors.pillNeutralForeground;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: AppTextStyles.pill.copyWith(color: _foregroundColor()),
      ),
    );
  }
}
