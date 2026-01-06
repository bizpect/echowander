import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _playTransitionAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // 단계 변경 시 애니메이션 재생
    ref.listen(onboardingControllerProvider, (previous, next) {
      if (previous?.stepIndex != next.stepIndex) {
        _playTransitionAnimation();
      }
    });

    const totalSteps = 5;
    final stepIndex = state.stepIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        leading: stepIndex > 0
            ? IconButton(
                onPressed: controller.previousStep,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  l10n.onboardingStepCounter(stepIndex + 1, totalSteps),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _StepContent(
                            title: _titleForStep(l10n, stepIndex),
                            description: _descriptionForStep(l10n, stepIndex),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildStepBody(
                              context: context,
                              l10n: l10n,
                              state: state,
                              controller: controller,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildActions(
                  l10n: l10n,
                  state: state,
                  controller: controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepBody({
    required BuildContext context,
    required AppLocalizations l10n,
    required OnboardingState state,
    required OnboardingController controller,
  }) {
    final stepIndex = state.stepIndex;

    // 권한 단계(0,1)는 심플한 텍스트
    // 동의 단계(2,3,4)는 체크박스만
    switch (stepIndex) {
      case 0:
        return _PermissionStep(
          icon: Icons.notifications_outlined,
          iconColor: Theme.of(context).colorScheme.primary,
          note: l10n.onboardingNotificationNote,
        );
      case 1:
        return _PermissionStep(
          icon: Icons.photo_library_outlined,
          iconColor: Theme.of(context).colorScheme.secondary,
          note: l10n.onboardingPhotoNote,
        );
      case 2:
        return _AgreementStep(
          agreementText: l10n.onboardingAgreeGuidelines,
          isAgreed: state.guidelineAgreed,
          onChanged: controller.updateGuidelineAgreement,
        );
      case 3:
        return _AgreementStep(
          agreementText: l10n.onboardingAgreeContentPolicy,
          isAgreed: state.contentAgreed,
          onChanged: controller.updateContentAgreement,
        );
      case 4:
        return _AgreementStep(
          agreementText: l10n.onboardingConfirmSafety,
          isAgreed: state.safetyAgreed,
          onChanged: controller.updateSafetyAgreement,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildActions({
    required AppLocalizations l10n,
    required OnboardingState state,
    required OnboardingController controller,
  }) {
    switch (state.stepIndex) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: controller.requestNotificationPermission,
              child: Text(l10n.onboardingAllowNotifications),
            ),
            TextButton(
              onPressed: controller.skipNotificationPermission,
              child: Text(l10n.onboardingSkip),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: controller.requestPhotoPermission,
              child: Text(l10n.onboardingAllowPhotos),
            ),
            TextButton(
              onPressed: controller.skipPhotoPermission,
              child: Text(l10n.onboardingSkip),
            ),
          ],
        );
      case 2:
        return FilledButton(
          onPressed: state.guidelineAgreed ? controller.nextStep : null,
          child: Text(l10n.onboardingNext),
        );
      case 3:
        return FilledButton(
          onPressed: state.contentAgreed ? controller.nextStep : null,
          child: Text(l10n.onboardingNext),
        );
      case 4:
        return FilledButton(
          onPressed: state.safetyAgreed ? controller.complete : null,
          child: Text(l10n.onboardingStart),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _titleForStep(AppLocalizations l10n, int stepIndex) {
    switch (stepIndex) {
      case 0:
        return l10n.onboardingNotificationTitle;
      case 1:
        return l10n.onboardingPhotoTitle;
      case 2:
        return l10n.onboardingGuidelineTitle;
      case 3:
        return l10n.onboardingContentPolicyTitle;
      case 4:
        return l10n.onboardingSafetyTitle;
      default:
        return '';
    }
  }

  String _descriptionForStep(AppLocalizations l10n, int stepIndex) {
    switch (stepIndex) {
      case 0:
        return l10n.onboardingNotificationDescription;
      case 1:
        return l10n.onboardingPhotoDescription;
      case 2:
        return l10n.onboardingGuidelineDescription;
      case 3:
        return l10n.onboardingContentPolicyDescription;
      case 4:
        return l10n.onboardingSafetyDescription;
      default:
        return '';
    }
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
        ),
      ],
    );
  }
}

// 권한 단계 전용 위젯 (Step 0, 1)
class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.icon,
    required this.iconColor,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 80,
          color: iconColor.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 32),
        Text(
          note,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.5,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// 동의 단계 전용 위젯 (Step 2, 3, 4)
class _AgreementStep extends StatelessWidget {
  const _AgreementStep({
    required this.agreementText,
    required this.isAgreed,
    required this.onChanged,
  });

  final String agreementText;
  final bool isAgreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: CheckboxListTile(
        value: isAgreed,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(agreementText),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
