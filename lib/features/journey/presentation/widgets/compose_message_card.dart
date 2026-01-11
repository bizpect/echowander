import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/validation/text_rules.dart';
import '../../application/journey_compose_controller.dart';

/// 메시지 입력 카드 (토스 스타일)
///
/// 텍스트 입력 필드와 글자수 카운터, 유효성 검사 결과를 표시합니다.
/// 토스 스타일: 큰 라운드, filled 스타일, 부드러운 경계, helper 텍스트
class ComposeMessageCard extends StatelessWidget {
  const ComposeMessageCard({
    super.key,
    required this.controller,
    required this.content,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String content;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final validationError = _validationError(l10n, content);
    final isOverLimit = content.length > journeyMaxLength;
    final characterCount = content.length;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: AppRadius.large,
        border: validationError != null
            ? Border.all(
                color: AppColors.error,
                width: 1.5,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 서브 가이드
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.spacing12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.composeLabel,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Text(
                  l10n.composeHint,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // 텍스트 입력 필드 (filled 스타일)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: controller,
              maxLength: journeyMaxLength,
              maxLines: 8,
              minLines: 6,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodyLg.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: colorScheme.surface,
                hintText: l10n.composeHint,
                hintStyle: AppTextStyles.bodyLg.copyWith(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: AppRadius.medium,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
                counterText: '',
              ),
              onChanged: onChanged,
            ),
          ),
          // 하단: 글자수 카운터 + 에러 메시지
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.spacing12,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 글자수 카운터
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      l10n.composeCharacterCount(
                        characterCount,
                        journeyMaxLength,
                      ),
                      style: AppTextStyles.meta.copyWith(
                        color: isOverLimit
                            ? AppColors.error
                            : characterCount > journeyMaxLength * 0.9
                                ? AppColors.warning
                                : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                // 유효성 검사 에러 메시지
                if (validationError != null) ...[
                  const SizedBox(height: AppSpacing.spacing8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSpacing.spacing4),
                      Expanded(
                        child: Text(
                          validationError,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _validationError(AppLocalizations l10n, String content) {
    if (content.isEmpty) {
      return null;
    }
    if (content.length > journeyMaxLength) {
      return l10n.composeTooLong;
    }
    if (containsForbiddenPattern(content)) {
      return l10n.composeForbidden;
    }
    return null;
  }
}
