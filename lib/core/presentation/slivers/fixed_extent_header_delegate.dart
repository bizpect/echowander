import 'package:flutter/widgets.dart';

/// 고정 높이를 가진 SliverPersistentHeaderDelegate
/// minExtent와 maxExtent가 동일하여 레이아웃 크래시를 방지합니다.
class FixedExtentPersistentHeaderDelegate
    extends SliverPersistentHeaderDelegate {
  const FixedExtentPersistentHeaderDelegate({
    required this.extent,
    required this.child,
  });

  /// 고정 높이 (minExtent와 maxExtent 모두 이 값 사용)
  final double extent;

  /// 표시할 위젯
  final Widget child;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // child를 정확히 extent 높이로 고정하여 paintExtent가 layoutExtent와 일치하도록 함
    return SizedBox.expand(
      child: child,
    );
  }

  @override
  bool shouldRebuild(
    covariant FixedExtentPersistentHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.extent != extent || oldDelegate.child != child;
  }
}
