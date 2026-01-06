import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';

/// 전체 화면 로딩 오버레이
///
/// 로딩 중일 때 화면 전체를 덮는 오버레이를 표시하고
/// 모든 사용자 입력(터치, 뒤로가기)을 차단합니다.
/// 오버레이 등장/퇴장 시 fade 애니메이션이 적용됩니다.
///
/// 사용 예시:
/// ```dart
/// LoadingOverlay(
///   isLoading: controller.isLoading,
///   child: Scaffold(...),
/// )
/// ```
class LoadingOverlay extends StatefulWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  final bool isLoading;
  final Widget child;
  final String? message;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    // 초기 상태가 로딩 중이면 즉시 표시
    if (widget.isLoading) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(LoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 로딩 상태가 변경되면 애니메이션 실행
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // 로딩 중에는 뒤로가기 완전 차단
      canPop: !widget.isLoading,
      child: Stack(
        children: [
          widget.child,
          if (widget.isLoading)
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 커스텀 로딩 인디케이터
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      if (widget.message != null) ...[
                        const SizedBox(height: AppSpacing.spacing16),
                        Text(
                          widget.message!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.onBackground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
