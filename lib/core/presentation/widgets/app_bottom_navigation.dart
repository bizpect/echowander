import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// 하단 네비게이션 탭 인덱스
enum AppTab {
  home,
  inbox,
  create,
  alerts,
  profile;

  int get tabIndex {
    switch (this) {
      case AppTab.home:
        return 0;
      case AppTab.inbox:
        return 1;
      case AppTab.create:
        return 2;
      case AppTab.alerts:
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
        return AppTab.inbox;
      case 2:
        return AppTab.create;
      case 3:
        return AppTab.alerts;
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
/// - Home / Inbox / Create(중앙) / Alerts(뱃지) / Profile
/// - 아이콘만 표시, 텍스트 라벨 없음
/// - Create는 중앙에 Floating 느낌으로 강조
/// - Alerts에는 읽지 않은 알림 카운트 뱃지 표시
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.unreadAlertsCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int unreadAlertsCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              ),

              // Inbox 탭
              _buildNavItem(
                context: context,
                icon: Icons.inbox_outlined,
                selectedIcon: Icons.inbox,
                isSelected: currentIndex == AppTab.inbox.tabIndex,
                onTap: () => onTap(AppTab.inbox.tabIndex),
                semanticLabel: l10n.tabInboxLabel,
              ),

              // Create 탭 (중앙, 강조)
              _buildCreateButton(
                context: context,
                isSelected: currentIndex == AppTab.create.tabIndex,
                onTap: () => onTap(AppTab.create.tabIndex),
                semanticLabel: l10n.tabCreateLabel,
              ),

              // Alerts 탭 (뱃지 포함)
              _buildNavItem(
                context: context,
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                isSelected: currentIndex == AppTab.alerts.tabIndex,
                onTap: () => onTap(AppTab.alerts.tabIndex),
                semanticLabel: l10n.tabAlertsLabel,
                badgeCount: unreadAlertsCount,
              ),

              // Profile 탭
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                isSelected: currentIndex == AppTab.profile.tabIndex,
                onTap: () => onTap(AppTab.profile.tabIndex),
                semanticLabel: l10n.tabProfileLabel,
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
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Semantics(
        label: semanticLabel,
        button: true,
        selected: isSelected,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.spacing8,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: 28,
                  color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
                // 뱃지 (Alerts 탭 전용)
                if (badgeCount > 0)
                  Positioned(
                    top: AppSpacing.spacing4,
                    right: AppSpacing.spacing12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: AppColors.onError,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
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
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryContainer : AppColors.primary,
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
                color: isSelected ? AppColors.onPrimaryContainer : AppColors.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
