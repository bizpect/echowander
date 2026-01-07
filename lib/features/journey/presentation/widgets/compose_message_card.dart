import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/validation/text_rules.dart';
import '../../application/journey_compose_controller.dart';

/// 메시지 입력 카드
///
/// 텍스트 입력 필드와 글자수 카운터, 유효성 검사 결과를 표시합니다.
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: validationError != null
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.outline,
          width: validationError != null ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 글자수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.composeLabel,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.composeCharacterCount(characterCount, journeyMaxLength),
                style: AppTypography.labelMedium.copyWith(
                  color: isOverLimit
                      ? AppColors.error
                      : characterCount > journeyMaxLength * 0.9
                          ? AppColors.warning
                          : AppColors.onSurfaceVariant,
                  fontWeight: isOverLimit ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing12),
          // 텍스트 입력 필드
          TextField(
            controller: controller,
            maxLength: journeyMaxLength,
            maxLines: 8,
            minLines: 6,
            textInputAction: TextInputAction.newline,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: l10n.composeHint,
              hintStyle: AppTypography.bodyLarge.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              counterText: '',
            ),
            onChanged: onChanged,
          ),
          // 유효성 검사 에러 메시지
          if (validationError != null) ...[
            const SizedBox(height: AppSpacing.spacing8),
            Row(
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
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
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

