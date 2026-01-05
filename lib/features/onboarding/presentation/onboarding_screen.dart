import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

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
              Text(
                l10n.onboardingStepCounter(stepIndex + 1, totalSteps),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 16),
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
              _buildActions(
                l10n: l10n,
                state: state,
                controller: controller,
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
    switch (state.stepIndex) {
      case 0:
        return Text(
          l10n.onboardingNotificationNote,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case 1:
        return Text(
          l10n.onboardingPhotoNote,
          style: Theme.of(context).textTheme.bodyMedium,
        );
      case 2:
        return CheckboxListTile(
          value: state.guidelineAgreed,
          onChanged: (value) => controller.updateGuidelineAgreement(value ?? false),
          title: Text(l10n.onboardingAgreeGuidelines),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      case 3:
        return CheckboxListTile(
          value: state.contentAgreed,
          onChanged: (value) => controller.updateContentAgreement(value ?? false),
          title: Text(l10n.onboardingAgreeContentPolicy),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        );
      case 4:
        return CheckboxListTile(
          value: state.safetyAgreed,
          onChanged: (value) => controller.updateSafetyAgreement(value ?? false),
          title: Text(l10n.onboardingConfirmSafety),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
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
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
