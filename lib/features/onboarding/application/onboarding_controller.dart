import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/app_permission_service.dart';
import '../data/onboarding_local_store.dart';

enum OnboardingStatus { unknown, required, completed }

class OnboardingState {
  final OnboardingStatus status;
  final int stepIndex;
  final PermissionStatus? notificationStatus;
  final PermissionStatus? photoStatus;
  final bool guidelineAgreed;
  final bool contentAgreed;
  final bool safetyAgreed;

  const OnboardingState({
    required this.status,
    required this.stepIndex,
    required this.notificationStatus,
    required this.photoStatus,
    required this.guidelineAgreed,
    required this.contentAgreed,
    required this.safetyAgreed,
  });

  factory OnboardingState.initial() => const OnboardingState(
    status: OnboardingStatus.unknown,
    stepIndex: 0,
    notificationStatus: null,
    photoStatus: null,
    guidelineAgreed: false,
    contentAgreed: false,
    safetyAgreed: false,
  );

  OnboardingState copyWith({
    OnboardingStatus? status,
    int? stepIndex,
    PermissionStatus? notificationStatus,
    PermissionStatus? photoStatus,
    bool? guidelineAgreed,
    bool? contentAgreed,
    bool? safetyAgreed,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      stepIndex: stepIndex ?? this.stepIndex,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      photoStatus: photoStatus ?? this.photoStatus,
      guidelineAgreed: guidelineAgreed ?? this.guidelineAgreed,
      contentAgreed: contentAgreed ?? this.contentAgreed,
      safetyAgreed: safetyAgreed ?? this.safetyAgreed,
    );
  }
}

final onboardingLocalStoreProvider = Provider<OnboardingLocalStore>(
  (ref) => OnboardingLocalStore(),
);

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<OnboardingState> {
  static const String _logPrefix = '[OnboardingController]';
  late final OnboardingLocalStore _store;
  late final AppPermissionService _permissionService;

  @override
  OnboardingState build() {
    _store = ref.read(onboardingLocalStoreProvider);
    _permissionService = ref.read(appPermissionServiceProvider);
    return OnboardingState.initial();
  }

  Future<void> load() async {
    final completed = await _store.readCompleted();
    if (completed) {
      state = state.copyWith(status: OnboardingStatus.completed);
      return;
    }

    // 진행 상태 복원
    final progress = await _store.readProgress();
    if (progress != null) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix load() - 복원된 진행 상태: stepIndex=${progress.stepIndex}, '
          'guideline=${progress.guidelineAgreed}, '
          'content=${progress.contentAgreed}, '
          'safety=${progress.safetyAgreed}',
        );
      }
      state = state.copyWith(
        status: OnboardingStatus.required,
        stepIndex: progress.stepIndex,
        guidelineAgreed: progress.guidelineAgreed,
        contentAgreed: progress.contentAgreed,
        safetyAgreed: progress.safetyAgreed,
      );
    } else {
      state = state.copyWith(status: OnboardingStatus.required);
    }
  }

  Future<void> _saveProgress() async {
    await _store.saveProgress(
      OnboardingProgress(
        stepIndex: state.stepIndex,
        guidelineAgreed: state.guidelineAgreed,
        contentAgreed: state.contentAgreed,
        safetyAgreed: state.safetyAgreed,
      ),
    );
  }

  Future<void> requestNotificationPermission() async {
    final status = await _permissionService.requestNotificationPermission();
    state = state.copyWith(notificationStatus: status);
    _nextStep();
  }

  void skipNotificationPermission() {
    _nextStep();
  }

  Future<void> requestPhotoPermission() async {
    final status = await _permissionService.requestPhotoPermission();
    state = state.copyWith(photoStatus: status);
    _nextStep();
  }

  void skipPhotoPermission() {
    _nextStep();
  }

  void updateGuidelineAgreement(bool value) {
    state = state.copyWith(guidelineAgreed: value);
    _saveProgress();
  }

  void updateContentAgreement(bool value) {
    state = state.copyWith(contentAgreed: value);
    _saveProgress();
  }

  void updateSafetyAgreement(bool value) {
    state = state.copyWith(safetyAgreed: value);
    _saveProgress();
  }

  void nextStep() {
    _nextStep();
  }

  void previousStep() {
    final nextIndex = state.stepIndex - 1;
    if (nextIndex < 0) {
      return;
    }
    state = state.copyWith(stepIndex: nextIndex);
    _saveProgress();
  }

  Future<void> complete() async {
    await _store.saveCompleted();
    await _store.clearProgress();
    state = state.copyWith(status: OnboardingStatus.completed);
  }

  void _nextStep() {
    final nextIndex = state.stepIndex + 1;
    if (nextIndex > 4) {
      return;
    }
    state = state.copyWith(stepIndex: nextIndex);
    _saveProgress();
  }
}
