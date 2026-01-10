import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/presentation/widgets/app_card.dart';
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

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: validationError != null
          ? AppColors.error
          : AppColors.borderSubtle,
      borderWidth: validationError != null ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 글자수
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.composeLabel,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                l10n.composeCharacterCount(characterCount, journeyMaxLength),
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
          const SizedBox(height: AppSpacing.spacing12),
          // 텍스트 입력 필드
          TextField(
            controller: controller,
            maxLength: journeyMaxLength,
            maxLines: 8,
            minLines: 6,
            textInputAction: TextInputAction.newline,
            style: AppTextStyles.bodyLg.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.composeHint,
              hintStyle: AppTextStyles.bodyLg.copyWith(
                color: AppColors.textSecondary,
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
                Icon(Icons.error_outline, size: 16, color: AppColors.error),
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
