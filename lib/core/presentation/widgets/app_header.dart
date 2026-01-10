import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';

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
    this.topPadding = AppSpacing.spacing8,
    this.showDivider = false,
    this.alignTitleLeft = false,
  });

  static const double kHeaderHeight = 56;
  static const double kHeaderIconSize = 24;
  static const double kHeaderIconHitBox = AppSpacing.minTouchTarget;
  static const double kHeaderHorizontalPadding =
      AppSpacing.screenPaddingHorizontal;
  static const double kHeaderTitleGap = AppSpacing.spacing12;
  static TextStyle get kHeaderTitleTextStyle => AppTextStyles.titleLg;
  static const Duration kHeaderAnimationDuration = Duration(milliseconds: 180);

  final String title;
  final IconData? leadingIcon;
  final VoidCallback? onLeadingTap;
  final String? leadingSemanticLabel;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingTap;
  final String? trailingSemanticLabel;
  final double topPadding;
  final bool showDivider;
  final bool alignTitleLeft;

  @override
  Size get preferredSize => Size.fromHeight(kHeaderHeight + topPadding);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kHeaderHeight + topPadding,
          padding: EdgeInsets.fromLTRB(
            kHeaderHorizontalPadding,
            topPadding,
            kHeaderHorizontalPadding,
            0,
          ),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: AppColors.divider, width: 1))
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _HeaderIconSlot(
                icon: leadingIcon,
                onTap: onLeadingTap,
                semanticLabel: leadingSemanticLabel,
                reserveSpace: !alignTitleLeft,
              ),
              SizedBox(width: alignTitleLeft ? 0 : kHeaderTitleGap),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: kHeaderAnimationDuration,
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: Text(
                      title,
                      key: ValueKey(title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: kHeaderTitleTextStyle.copyWith(
                        color: AppColors.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: kHeaderTitleGap),
              _HeaderIconSlot(
                icon: trailingIcon,
                onTap: onTrailingTap,
                semanticLabel: trailingSemanticLabel,
                reserveSpace: true,
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
    required this.reserveSpace,
  });

  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool reserveSpace;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return SizedBox(
        width: reserveSpace ? AppHeader.kHeaderIconHitBox : 0,
        height: AppHeader.kHeaderIconHitBox,
      );
    }

    return _HeaderIconButton(
      icon: icon!,
      onTap: onTap,
      semanticLabel: semanticLabel,
    );
  }
}

class _HeaderIconButton extends StatefulWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<_HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<_HeaderIconButton> {
  bool _isPressed = false;

  void _handleHighlightChanged(bool isPressed) {
    if (_isPressed == isPressed) {
      return;
    }
    setState(() {
      _isPressed = isPressed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: AppHeader.kHeaderAnimationDuration,
        curve: Curves.easeOut,
        child: InkResponse(
          onTap: widget.onTap,
          onHighlightChanged: _handleHighlightChanged,
          radius: AppHeader.kHeaderIconHitBox / 2,
          child: SizedBox(
            width: AppHeader.kHeaderIconHitBox,
            height: AppHeader.kHeaderIconHitBox,
            child: Icon(
              widget.icon,
              size: AppHeader.kHeaderIconSize,
              color: AppColors.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}
