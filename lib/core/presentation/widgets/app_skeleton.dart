import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

/// 공통 스켈레톤 컴포넌트
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = 12,
    this.radius = const Radius.circular(AppRadius.radiusMedium),
  });

  final double? width;
  final double height;
  final Radius radius;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final color = Color.lerp(
          AppColors.skeletonBase,
          AppColors.skeletonHighlight,
          value,
        );
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.all(radius),
          ),
        );
      },
    );
  }
}

/// 리스트용 스켈레톤 프리셋
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: AppRadius.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeleton(width: 140, height: 14),
                SizedBox(height: AppSpacing.sm),
                AppSkeleton(width: double.infinity, height: 12),
                SizedBox(height: AppSpacing.xs),
                AppSkeleton(width: 180, height: 12),
              ],
            ),
          ),
        );
      }),
    );
  }
}
