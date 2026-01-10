import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OnboardingProgress {
  final int stepIndex;
  final bool guidelineAgreed;
  final bool contentAgreed;
  final bool safetyAgreed;

  const OnboardingProgress({
    required this.stepIndex,
    required this.guidelineAgreed,
    required this.contentAgreed,
    required this.safetyAgreed,
  });

  Map<String, dynamic> toJson() => {
    'stepIndex': stepIndex,
    'guidelineAgreed': guidelineAgreed,
    'contentAgreed': contentAgreed,
    'safetyAgreed': safetyAgreed,
  };

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) =>
      OnboardingProgress(
        stepIndex: json['stepIndex'] as int? ?? 0,
        guidelineAgreed: json['guidelineAgreed'] as bool? ?? false,
        contentAgreed: json['contentAgreed'] as bool? ?? false,
        safetyAgreed: json['safetyAgreed'] as bool? ?? false,
      );
}

class OnboardingLocalStore {
  static const String _logPrefix = '[OnboardingLocalStore]';
  static const _completedKey = 'onboarding_completed';
  static const _progressKey = 'onboarding_progress';
  final FlutterSecureStorage _storage;

  OnboardingLocalStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> readCompleted() async {
    final value = await _storage.read(key: _completedKey);
    return value == 'true';
  }

  Future<void> saveCompleted() async {
    await _storage.write(key: _completedKey, value: 'true');
    // 완료 시 진행 상태도 삭제
    await _storage.delete(key: _progressKey);
  }

  Future<OnboardingProgress?> readProgress() async {
    try {
      final value = await _storage.read(key: _progressKey);
      if (value == null) {
        return null;
      }
      final json = jsonDecode(value) as Map<String, dynamic>;
      return OnboardingProgress.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix readProgress error: $e');
      }
      return null;
    }
  }

  Future<void> saveProgress(OnboardingProgress progress) async {
    try {
      final json = jsonEncode(progress.toJson());
      await _storage.write(key: _progressKey, value: json);
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix saveProgress - stepIndex: ${progress.stepIndex}, '
          'guideline: ${progress.guidelineAgreed}, '
          'content: ${progress.contentAgreed}, '
          'safety: ${progress.safetyAgreed}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix saveProgress error: $e');
      }
    }
  }

  Future<void> clearProgress() async {
    await _storage.delete(key: _progressKey);
  }
}
