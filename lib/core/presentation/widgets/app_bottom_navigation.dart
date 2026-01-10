import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// 하단 네비게이션 탭 인덱스
enum AppTab {
  home,
  sent,
  create,
  inbox,
  profile;

  int get tabIndex {
    switch (this) {
      case AppTab.home:
        return 0;
      case AppTab.sent:
        return 1;
      case AppTab.create:
        return 2;
      case AppTab.inbox:
        return 3;
      case AppTab.profile:
        return 4;
    }
  }

  static AppTab fromIndex(int index) {
    switch (index) {
      case 0:
        return AppTab.home;
      case 1:
        return AppTab.sent;
      case 2:
        return AppTab.create;
      case 3:
        return AppTab.inbox;
      case 4:
        return AppTab.profile;
      default:
        return AppTab.home;
    }
  }
}

/// 5탭 하단 네비게이션 바
///
/// 특징:
/// - Home / Sent / Create(중앙) / Inbox / Profile
/// - 아이콘만 표시, 텍스트 라벨 없음
/// - Create는 중앙에 Floating 느낌으로 강조
/// - 탭 전환 시 subtle scale & opacity 애니메이션
class AppBottomNavigation extends StatefulWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<AppBottomNavigation> createState() => _AppBottomNavigationState();
}

class _AppBottomNavigationState extends State<AppBottomNavigation>
    with TickerProviderStateMixin {
  late Map<int, AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    // 각 탭마다 독립적인 AnimationController 생성
    _controllers = {
      for (var i = 0; i < 5; i++)
        i: AnimationController(
          duration: const Duration(milliseconds: 150),
          vsync: this,
        ),
    };
    // 현재 선택된 탭은 애니메이션 완료 상태로 시작
    _controllers[widget.currentIndex]?.value = 1.0;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AppBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 탭이 변경되었을 때 애니메이션 실행
    if (oldWidget.currentIndex != widget.currentIndex) {
      // 이전 탭은 축소 (reverse)
      _controllers[oldWidget.currentIndex]?.reverse();
      // 새 탭은 확대 (forward)
      _controllers[widget.currentIndex]?.forward();
    }
  }

  int get currentIndex => widget.currentIndex;
  ValueChanged<int> get onTap => widget.onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.overlaySubtle,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppSpacing.spacing64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home 탭
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                isSelected: currentIndex == AppTab.home.tabIndex,
                onTap: () => onTap(AppTab.home.tabIndex),
                semanticLabel: l10n.tabHomeLabel,
                tabIndex: AppTab.home.tabIndex,
              ),

              // Sent 탭
              _buildNavItem(
                context: context,
                icon: Icons.send_outlined,
                selectedIcon: Icons.send,
                isSelected: currentIndex == AppTab.sent.tabIndex,
                onTap: () => onTap(AppTab.sent.tabIndex),
                semanticLabel: l10n.tabSentLabel,
                tabIndex: AppTab.sent.tabIndex,
              ),

              // Create 탭 (중앙, 강조)
              _buildCreateButton(
                context: context,
                isSelected: currentIndex == AppTab.create.tabIndex,
                onTap: () => onTap(AppTab.create.tabIndex),
                semanticLabel: l10n.tabCreateLabel,
              ),

              // Inbox 탭
              _buildNavItem(
                context: context,
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox,
                isSelected: currentIndex == AppTab.inbox.tabIndex,
                onTap: () => onTap(AppTab.inbox.tabIndex),
                semanticLabel: l10n.tabInboxLabel,
                tabIndex: AppTab.inbox.tabIndex,
              ),

              // Profile 탭
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                isSelected: currentIndex == AppTab.profile.tabIndex,
                onTap: () => onTap(AppTab.profile.tabIndex),
                semanticLabel: l10n.tabProfileLabel,
                tabIndex: AppTab.profile.tabIndex,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 일반 네비게이션 아이템
  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required bool isSelected,
    required VoidCallback onTap,
    required String semanticLabel,
    int? tabIndex,
  }) {
    // 해당 탭의 AnimationController 가져오기
    final controller = tabIndex != null ? _controllers[tabIndex] : null;

    return Expanded(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 애니메이션 래퍼: scale 0.95 → 1.0, opacity 0.6 → 1.0
                if (controller != null)
                  AnimatedBuilder(
                    animation: controller,
                    builder: (context, child) {
                      final scale = 0.95 + (0.05 * controller.value);
                      final opacity = 0.6 + (0.4 * controller.value);
                      return Transform.scale(
                        scale: scale,
                        child: Opacity(opacity: opacity, child: child),
                      );
                    },
                    child: Icon(
                      isSelected ? selectedIcon : icon,
                      size: 28,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.onSurfaceVariant,
                    ),
                  )
                else
                  Icon(
                    isSelected ? selectedIcon : icon,
                    size: 28,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 중앙 Create 버튼 (Floating 강조)
  Widget _buildCreateButton({
    required BuildContext context,
    required bool isSelected,
    required VoidCallback onTap,
    required String semanticLabel,
  }) {
    // Create 탭의 AnimationController 가져오기 (index = 2)
    final controller = _controllers[AppTab.create.tabIndex];

    return Expanded(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        child: Center(
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            customBorder: const CircleBorder(),
            child: AnimatedBuilder(
              animation: controller!,
              builder: (context, child) {
                final scale = 0.95 + (0.05 * controller.value);
                final opacity = 0.6 + (0.4 * controller.value);
                return Transform.scale(
                  scale: scale,
                  child: Opacity(opacity: opacity, child: child),
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer
                      : AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isSelected ? Icons.edit : Icons.add,
                  size: 28,
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
