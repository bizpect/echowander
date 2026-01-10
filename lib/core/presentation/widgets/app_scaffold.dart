import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// 앱 전용 스캐폴드
/// 공통 배경/안전영역/스크롤 구조를 통일합니다.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.appBar,
    this.body,
    this.slivers,
    this.bodyPadding = AppSpacing.pagePadding,
    this.headerBodySpacing = AppSpacing.lg,
    this.safeAreaTop = false,
    this.safeAreaBottom = true,
    this.backgroundColor = AppColors.background,
    this.resizeToAvoidBottomInset = true,
  }) : assert(body != null || slivers != null);

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final List<Widget>? slivers;
  final EdgeInsetsGeometry bodyPadding;
  final double headerBodySpacing;
  final bool safeAreaTop;
  final bool safeAreaBottom;
  final Color backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final content = slivers != null
        ? CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(height: appBar != null ? headerBodySpacing : 0),
              ),
              ...slivers!,
            ],
          )
        : Padding(
            padding: bodyPadding.add(
              EdgeInsets.only(top: appBar != null ? headerBodySpacing : 0),
            ),
            child: body!,
          );

    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(top: safeAreaTop, bottom: safeAreaBottom, child: content),
    );
  }
}
