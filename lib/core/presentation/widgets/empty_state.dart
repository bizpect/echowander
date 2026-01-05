import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// 빈 상태 표시 위젯
///
/// 데이터가 없을 때 사용자에게 명확한 피드백을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inbox_outlined,
///   title: '아직 받은 Journey가 없어요',
///   description: '다른 사용자가 보낸 Journey가 도착하면 여기에 표시됩니다',
///   actionLabel: '새로고침',
///   onAction: () => controller.refresh(),
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Icon(
              icon,
              size: 80,
              color: AppColors.onSurfaceVariant, // 가시성 개선 (기존: surfaceVariant)
            ),
            const SizedBox(height: AppSpacing.spacing16),

            // 타이틀
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),

            // 설명 (선택적)
            if (description != null) ...[
              const SizedBox(height: AppSpacing.spacing8),
              Text(
                description!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],

            // 액션 버튼 (선택적)
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.spacing24),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
