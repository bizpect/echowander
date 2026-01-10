import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

/// 앱 전용 FilledButton
///
/// 로딩 상태를 지원하는 주요 액션 버튼입니다.
/// press 시 subtle scale 애니메이션이 적용됩니다.
///
/// 사용 예시:
/// ```dart
/// AppFilledButton(
///   onPressed: () => controller.submit(),
///   isLoading: controller.isLoading,
///   child: Text('전송하기'),
/// )
/// ```
class AppFilledButton extends StatefulWidget {
  const AppFilledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;

  @override
  State<AppFilledButton> createState() => _AppFilledButtonState();
}

class _AppFilledButtonState extends State<AppFilledButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FilledButton(
          onPressed: widget.isLoading ? null : widget.onPressed,
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.onPrimary,
                    ),
                  ),
                )
              : widget.child,
        ),
      ),
    );
  }
}

/// 앱 전용 OutlinedButton
///
/// 보조 액션 버튼입니다.
/// press 시 subtle scale 애니메이션이 적용됩니다.
///
/// 사용 예시:
/// ```dart
/// AppOutlinedButton(
///   onPressed: () => Navigator.pop(context),
///   child: Text('취소'),
/// )
/// ```
class AppOutlinedButton extends StatefulWidget {
  const AppOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Widget child;

  @override
  State<AppOutlinedButton> createState() => _AppOutlinedButtonState();
}

class _AppOutlinedButtonState extends State<AppOutlinedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: OutlinedButton(onPressed: widget.onPressed, child: widget.child),
      ),
    );
  }
}
