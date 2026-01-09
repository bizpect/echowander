import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

/// 앱 공통 헤더(AppBar) UI 규격을 고정하는 위젯
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.leadingIcon,
    this.onLeadingTap,
    this.leadingSemanticLabel,
    this.trailingIcon,
    this.onTrailingTap,
    this.trailingSemanticLabel,
    this.alignLeft = false,
    this.showDivider = false,
  });

  static const double kHeaderHeight = 56;
  static const double kHeaderIconSize = 24;
  static const double kHeaderIconHitBox = AppSpacing.minTouchTarget;
  static const double kHeaderHorizontalPadding = AppSpacing.screenPaddingHorizontal;
  static const double kHeaderTitleGap = AppSpacing.spacing12;
  static const TextStyle kHeaderTitleTextStyle = AppTypography.headlineLarge;

  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final String? leadingSemanticLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final String? trailingSemanticLabel;
  final bool alignLeft;
  final bool showDivider;

  @override
  Size get preferredSize => const Size.fromHeight(kHeaderHeight);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kHeaderHeight,
          padding: const EdgeInsets.symmetric(horizontal: kHeaderHorizontalPadding),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  )
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderIconSlot(
                icon: leadingIcon,
                onTap: onLeadingTap,
                semanticLabel: leadingSemanticLabel,
                keepSpace: !alignLeft,
              ),
              SizedBox(width: alignLeft ? 0 : kHeaderTitleGap),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: kHeaderTitleTextStyle.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: kHeaderTitleGap),
              _HeaderIconSlot(
                icon: trailingIcon,
                onTap: onTrailingTap,
                semanticLabel: trailingSemanticLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconSlot extends StatelessWidget {
  const _HeaderIconSlot({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.keepSpace = true,
  });

  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool keepSpace;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      if (!keepSpace) {
        return const SizedBox.shrink();
      }
      return const SizedBox(
        width: AppHeader.kHeaderIconHitBox,
        height: AppHeader.kHeaderIconHitBox,
      );
    }

    return Semantics(
      label: semanticLabel,
      button: true,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: AppHeader.kHeaderIconSize,
          color: AppColors.onBackground,
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: AppHeader.kHeaderIconHitBox,
          height: AppHeader.kHeaderIconHitBox,
        ),
        splashRadius: AppHeader.kHeaderIconHitBox / 2,
      ),
    );
  }
}
