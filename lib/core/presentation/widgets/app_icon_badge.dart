import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';

/// 아이콘 배지 공통 컴포넌트
class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.icon,
    this.backgroundColor = AppColors.surfaceElevated,
    this.iconColor = AppColors.iconPrimary,
    this.size = 36,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.medium,
      ),
      child: Icon(icon, size: AppSpacing.lg, color: iconColor),
    );
  }
}
