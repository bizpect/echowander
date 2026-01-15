import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';

/// 채팅 UI 날짜 그룹 구분선 (카카오톡 스타일)
///
/// 사용법:
/// ```dart
/// ChatDateDivider(
///   dateText: '2026년 01월 15일',
///   semanticLabel: '2026년 1월 15일',
/// )
/// ```
class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({
    super.key,
    required this.dateText,
    this.semanticLabel,
  });

  /// 날짜 문자열 (이미 포맷된 상태)
  final String dateText;

  /// 접근성 레이블 (TTS용, null이면 dateText 사용)
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: semanticLabel ?? dateText,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.spacing12,
          horizontal: AppSpacing.spacing16,
        ),
        child: Row(
          children: [
            // 왼쪽 라인
            Expanded(
              child: Divider(
                color: colorScheme.outlineVariant,
                thickness: 1,
                height: 1,
              ),
            ),
            // 가운데 날짜 텍스트
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing12),
              child: Text(
                dateText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // 오른쪽 라인
            Expanded(
              child: Divider(
                color: colorScheme.outlineVariant,
                thickness: 1,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
