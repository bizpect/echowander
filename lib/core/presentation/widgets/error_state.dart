import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';

/// 에러 상태 표시 위젯
///
/// 에러 발생 시 사용자에게 명확한 피드백과 재시도 옵션을 제공합니다.
/// 등장 시 fade in 애니메이션이 적용됩니다.
///
/// 사용 예시:
/// ```dart
/// ErrorStateWidget(
///   icon: Icons.wifi_off,
///   title: '네트워크 연결을 확인해주세요',
///   description: '인터넷 연결이 불안정합니다',
///   actionLabel: '다시 시도',
///   onRetry: () => controller.retry(),
/// )
/// ```
class ErrorStateWidget extends StatefulWidget {
  const ErrorStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onRetry;

  @override
  State<ErrorStateWidget> createState() => _ErrorStateWidgetState();
}

class _ErrorStateWidgetState extends State<ErrorStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    // 위젯 등장 시 애니메이션 시작
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.spacing32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘 (에러 색상)
              Icon(widget.icon, size: 80, color: AppColors.error),
              const SizedBox(height: AppSpacing.spacing16),

              // 타이틀
              Text(
                widget.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),

              // 설명 (선택적)
              if (widget.description != null) ...[
                const SizedBox(height: AppSpacing.spacing8),
                Text(
                  widget.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // 재시도 버튼 (선택적)
              if (widget.actionLabel != null && widget.onRetry != null) ...[
                const SizedBox(height: AppSpacing.spacing24),
                FilledButton(
                  onPressed: widget.onRetry,
                  child: Text(widget.actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
