import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const String _logPrefix = '[OnboardingScreen]';

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix initState() - identityHashCode: ${identityHashCode(this)}',
      );
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix dispose() - identityHashCode: ${identityHashCode(this)}',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // stepIndex만 watch하여 체크 상태 변경 시 rebuild 방지
    final stepIndex = ref.watch(
      onboardingControllerProvider.select((state) => state.stepIndex),
    );

    if (kDebugMode) {
      debugPrint('$_logPrefix build() - stepIndex: $stepIndex');
    }

    const totalSteps = 5;

    // 시스템 뒤로가기 완전 차단: 물리키/제스처 모두 무반응
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // 시스템 back 완전 차단: 아무 동작도 하지 않음
        // 이전 단계 이동은 오직 하단 "이전" 버튼으로만 가능
      },
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: SafeArea(
          child: Column(
            children: [
              // 상단: 시각적 단계 네비게이터 (뒤로가기 아이콘 제거)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.screenPaddingTop,
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.spacing32,
                ),
                child: _VisualStepNavigator(
                  currentStep: stepIndex,
                  totalSteps: totalSteps,
                ),
              ),
              // 중앙: 아이콘 중심 카드 (애니메이션 래퍼로 분리)
              // 고정 key로 트리에서 절대 제거되지 않도록 보장
              Expanded(
                child: _AnimatedStepCard(
                  key: const ValueKey('step-card'),
                  stepIndex: stepIndex,
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context)!;
                      return _buildStepCard(
                        context: context,
                        l10n: l10n,
                        stepIndex: stepIndex,
                      );
                    },
                  ),
                ),
              ),
              // 하단: 단일 CTA (애니메이션 래퍼로 분리)
              // 고정 key로 트리에서 절대 제거되지 않도록 보장
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.spacing24,
                  AppSpacing.screenPaddingHorizontal,
                  AppSpacing.screenPaddingBottom,
                ),
                child: _AnimatedStepCard(
                  key: const ValueKey('step-actions'),
                  stepIndex: stepIndex,
                  child: _OnboardingActions(stepIndex: stepIndex),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required BuildContext context,
    required AppLocalizations l10n,
    required int stepIndex,
  }) {
    switch (stepIndex) {
      case 0:
        return _PermissionCard(
          icon: Icons.notifications_outlined,
          iconColor: AppColors.primary,
          title: l10n.onboardingNotificationTitle,
          description: l10n.onboardingNotificationDescription,
          note: l10n.onboardingNotificationNote,
        );
      case 1:
        return _PermissionCard(
          icon: Icons.photo_library_outlined,
          iconColor: AppColors.secondary,
          title: l10n.onboardingPhotoTitle,
          description: l10n.onboardingPhotoDescription,
          note: l10n.onboardingPhotoNote,
        );
      case 2:
        return _AgreementCard(
          icon: Icons.groups_outlined,
          iconColor: AppColors.primary,
          title: l10n.onboardingGuidelineTitle,
          description: l10n.onboardingGuidelineDescription,
          agreementText: l10n.onboardingAgreeGuidelines,
          agreementKey: 'guideline',
        );
      case 3:
        return _AgreementCard(
          icon: Icons.description_outlined,
          iconColor: AppColors.secondary,
          title: l10n.onboardingContentPolicyTitle,
          description: l10n.onboardingContentPolicyDescription,
          agreementText: l10n.onboardingAgreeContentPolicy,
          agreementKey: 'content',
        );
      case 4:
        return _AgreementCard(
          icon: Icons.shield_outlined,
          iconColor: AppColors.primary,
          title: l10n.onboardingSafetyTitle,
          description: l10n.onboardingSafetyDescription,
          agreementText: l10n.onboardingConfirmSafety,
          agreementKey: 'safety',
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 애니메이션 래퍼 위젯 - stepIndex 변경 시에만 애니메이션 실행
/// 체크 토글로 인한 rebuild에서는 애니메이션이 재시작되지 않도록 구조적으로 차단
class _AnimatedStepCard extends StatefulWidget {
  const _AnimatedStepCard({
    super.key,
    required this.stepIndex,
    required this.child,
  });

  final int stepIndex;
  final Widget child;

  @override
  State<_AnimatedStepCard> createState() => _AnimatedStepCardState();
}

class _AnimatedStepCardState extends State<_AnimatedStepCard>
    with SingleTickerProviderStateMixin {
  static const String _logPrefix = '[AnimatedStepCard]';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix initState() - stepIndex: ${widget.stepIndex}, '
        'key: ${widget.key}, identityHashCode: ${identityHashCode(this)}',
      );
    }

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // 초기 애니메이션 실행
    _animationController.forward();
    if (kDebugMode) {
      debugPrint('$_logPrefix AnimationController.forward() - initState');
    }
  }

  @override
  void didUpdateWidget(_AnimatedStepCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // stepIndex가 변경된 경우에만 애니메이션 재실행
    if (oldWidget.stepIndex != widget.stepIndex) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix didUpdateWidget() - stepIndex changed: '
          '${oldWidget.stepIndex} -> ${widget.stepIndex}',
        );
        debugPrint('$_logPrefix AnimationController.reset() + forward()');
      }
      _animationController.reset();
      _animationController.forward();
    } else {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix didUpdateWidget() - stepIndex unchanged: '
          '${widget.stepIndex} (애니메이션 재시작 안 함)',
        );
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix dispose() - stepIndex: ${widget.stepIndex}, '
        'key: ${widget.key}, identityHashCode: ${identityHashCode(this)}',
      );
    }
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix build() - stepIndex: ${widget.stepIndex}, '
        'key: ${widget.key}, identityHashCode: ${identityHashCode(this)}',
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPaddingHorizontal,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// 시각적 단계 네비게이터 - 텍스트 없이 도트로만 표현
class _VisualStepNavigator extends StatelessWidget {
  const _VisualStepNavigator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary
                  : isCompleted
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: AppRadius.full,
            ),
          ),
        );
      }),
    );
  }
}

/// 권한 단계 카드 (Step 0, 1)
class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.spacing32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.spacing32),
            // 제목
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            // 설명
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing24),
            // 보조 노트
            Text(
              note,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 동의 단계 카드 (Step 2, 3, 4)
/// 체크 상태는 내부 Consumer로만 watch하여 상위 애니메이션에 영향 없음
class _AgreementCard extends StatelessWidget {
  const _AgreementCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.agreementText,
    required this.agreementKey,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String agreementText;
  final String agreementKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(AppSpacing.spacing32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.large,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.spacing24),
            // 제목
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing12),
            // 설명
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.spacing32),
            // 체크박스 (Consumer로 분리하여 체크 상태만 watch)
            _AgreementCheckbox(
              agreementText: agreementText,
              agreementKey: agreementKey,
              iconColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// 하단 CTA 버튼 영역 - 체크 상태만 watch하여 최소 범위 rebuild
class _OnboardingActions extends ConsumerWidget {
  const _OnboardingActions({required this.stepIndex});

  final int stepIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final controller = ref.read(onboardingControllerProvider.notifier);

    switch (stepIndex) {
      case 0:
        // 1단계: 버튼 1개 full-width
        return SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              // 권한 요청 시도 (거부 시 자동으로 _nextStep 호출됨)
              await controller.requestNotificationPermission();
            },
            child: Text(
              l10n.ctaPermissionChoice,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case 1:
        // 2단계: 버튼 2개 5:5 비율
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text(
                    l10n.onboardingPrevious,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () async {
                    await controller.requestPhotoPermission();
                  },
                  child: Text(
                    l10n.ctaPermissionChoice,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      case 2:
        // 체크 상태만 watch
        final isAgreed = ref.watch(
          onboardingControllerProvider.select((state) => state.guidelineAgreed),
        );
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text(
                    l10n.onboardingPrevious,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isAgreed ? controller.nextStep : null,
                  child: Text(
                    l10n.onboardingNext,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      case 3:
        // 체크 상태만 watch
        final isAgreed = ref.watch(
          onboardingControllerProvider.select((state) => state.contentAgreed),
        );
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text(
                    l10n.onboardingPrevious,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isAgreed ? controller.nextStep : null,
                  child: Text(
                    l10n.onboardingNext,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      case 4:
        // 체크 상태만 watch
        final isAgreed = ref.watch(
          onboardingControllerProvider.select((state) => state.safetyAgreed),
        );
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: controller.previousStep,
                  child: Text(
                    l10n.onboardingPrevious,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.spacing16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: isAgreed ? controller.complete : null,
                  child: Text(
                    l10n.onboardingStart,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

/// 체크박스 영역만 독립적으로 rebuild되는 위젯
class _AgreementCheckbox extends ConsumerWidget {
  const _AgreementCheckbox({
    required this.agreementText,
    required this.agreementKey,
    required this.iconColor,
  });

  final String agreementText;
  final String agreementKey;
  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final isAgreed = _getAgreementValue(state, agreementKey);
    final onChanged = _getAgreementHandler(controller, agreementKey);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing16),
      decoration: BoxDecoration(
        color: isAgreed
            ? iconColor.withValues(alpha: 0.1)
            : AppColors.surfaceVariant,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: isAgreed ? iconColor : AppColors.outline,
          width: isAgreed ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: AppSpacing.minTouchTarget,
            height: AppSpacing.minTouchTarget,
            child: Checkbox(
              value: isAgreed,
              onChanged: (value) => onChanged(value ?? false),
              activeColor: iconColor,
              checkColor: AppColors.onPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing12),
          Expanded(
            child: Text(
              agreementText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.onSurface,
                fontWeight: isAgreed ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _getAgreementValue(OnboardingState state, String key) {
    switch (key) {
      case 'guideline':
        return state.guidelineAgreed;
      case 'content':
        return state.contentAgreed;
      case 'safety':
        return state.safetyAgreed;
      default:
        return false;
    }
  }

  ValueChanged<bool> _getAgreementHandler(
    OnboardingController controller,
    String key,
  ) {
    switch (key) {
      case 'guideline':
        return controller.updateGuidelineAgreement;
      case 'content':
        return controller.updateContentAgreement;
      case 'safety':
        return controller.updateSafetyAgreement;
      default:
        return (_) {};
    }
  }
}
