import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/app_permission_service.dart';
import '../data/onboarding_local_store.dart';

enum OnboardingStatus {
  unknown,
  required,
  completed,
}

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
    state = state.copyWith(
      status: completed ? OnboardingStatus.completed : OnboardingStatus.required,
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
  }

  void updateContentAgreement(bool value) {
    state = state.copyWith(contentAgreed: value);
  }

  void updateSafetyAgreement(bool value) {
    state = state.copyWith(safetyAgreed: value);
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
  }

  Future<void> complete() async {
    await _store.saveCompleted();
    state = state.copyWith(status: OnboardingStatus.completed);
  }

  void _nextStep() {
    final nextIndex = state.stepIndex + 1;
    if (nextIndex > 4) {
      return;
    }
    state = state.copyWith(stepIndex: nextIndex);
  }
}
