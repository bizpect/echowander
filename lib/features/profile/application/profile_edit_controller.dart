import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_manager.dart';
import '../../../core/validation/nickname_validator.dart';
import '../application/avatar_signed_url_provider.dart';
import '../application/profile_provider.dart';
import '../data/supabase_profile_repository.dart';
import '../domain/profile_repository.dart';

const _logPrefix = '[ProfileEdit]';

/// 닉네임 가용 여부 상태
enum NicknameAvailabilityStatus {
  idle, // 초기 상태
  checking, // 확인 중
  available, // 사용 가능
  taken, // 사용 중
  error, // 에러
}

/// 프로필 편집 상태
class ProfileEditState {
  // 센티넬 패턴: null을 명시적으로 세팅하기 위한 마커
  static const Object _unset = Object();

  const ProfileEditState({
    required this.nickname,
    required this.originalNickname,
    required this.avatarBytes,
    required this.originalAvatarPath,
    required this.nicknameValidation,
    required this.nicknameAvailability,
    required this.availabilityNorm,
    required this.isSaving,
    // hasChanges는 getter로 계산되므로 생성자에서 제거
  });

  final String nickname;
  final String? originalNickname;
  final Uint8List? avatarBytes;
  final String? originalAvatarPath;
  final NicknameValidationResult nicknameValidation;
  final NicknameAvailabilityStatus nicknameAvailability;
  final String? availabilityNorm; // available/taken 결과가 어떤 norm에 대한 결과인지
  final bool isSaving;
  // hasChanges는 필드 제거하고 계산 getter로 대체 (회귀/누락 방지)

  factory ProfileEditState.initial({
    String? initialNickname,
    String? initialAvatarPath,
  }) {
    return ProfileEditState(
      nickname: initialNickname ?? '',
      originalNickname: initialNickname,
      avatarBytes: null,
      originalAvatarPath: initialAvatarPath,
      nicknameValidation: const NicknameValidationResult(isValid: true),
      nicknameAvailability: NicknameAvailabilityStatus.idle,
      availabilityNorm: null,
      isSaving: false,
    );
  }

  /// 현재 입력값의 정규화된 닉네임 (단일 계산 지점)
  String get currentNorm {
    return NicknameValidator.normalize(nickname.trim());
  }

  /// 원본 닉네임의 정규화된 값
  String get originalNorm {
    return NicknameValidator.normalize((originalNickname ?? '').trim());
  }

  /// 닉네임 변경 여부 (norm 기준)
  bool get nicknameChanged {
    return currentNorm != originalNorm;
  }

  /// 아바타 변경 여부
  bool get avatarChanged {
    return avatarBytes != null;
  }

  /// 변경 사항 존재 여부 (계산 getter로 항상 정확한 값 반환)
  bool get hasChanges {
    return nicknameChanged || avatarChanged;
  }

  ProfileEditState copyWith({
    String? nickname,
    String? originalNickname,
    Uint8List? avatarBytes,
    String? originalAvatarPath,
    NicknameValidationResult? nicknameValidation,
    NicknameAvailabilityStatus? nicknameAvailability,
    Object? availabilityNorm = _unset, // 센티넬 패턴: null을 명시적으로 세팅 가능
    bool? isSaving,
    // hasChanges는 getter로 계산되므로 copyWith에서 제거
  }) {
    return ProfileEditState(
      nickname: nickname ?? this.nickname,
      originalNickname: originalNickname ?? this.originalNickname,
      avatarBytes: avatarBytes ?? this.avatarBytes,
      originalAvatarPath: originalAvatarPath ?? this.originalAvatarPath,
      nicknameValidation: nicknameValidation ?? this.nicknameValidation,
      nicknameAvailability: nicknameAvailability ?? this.nicknameAvailability,
      // 센티넬 패턴: _unset이면 기존 값 유지, 아니면 전달된 값 사용 (null 포함)
      availabilityNorm: identical(availabilityNorm, _unset)
          ? this.availabilityNorm
          : availabilityNorm as String?,
      isSaving: isSaving ?? this.isSaving,
      // hasChanges는 getter로 자동 계산됨
    );
  }

  /// 저장 가능 여부 (norm 기준으로 변경 판정 및 상태 매칭)
  bool get canSave {
    // ✅ hasChanges는 getter로 항상 정확한 값 계산
    if (!hasChanges || isSaving) {
      if (kDebugMode && nicknameAvailability == NicknameAvailabilityStatus.available) {
        debugPrint(
          '$_logPrefix canSave=false (available but blocked): '
          'hasChanges=$hasChanges '
          'isSaving=$isSaving',
        );
      }
      return false;
    }

    final nicknameTrimmed = nickname.trim();

    // ✅ 빈 값 방어 (최우선)
    if (nicknameTrimmed.isEmpty) {
      return false;
    }

    // norm 기준으로 변경 판정 (DB와 동일 기준)
    final currentNorm = this.currentNorm;
    final originalNorm = this.originalNorm;

    // 닉네임이 변경되지 않았으면 validation 스킵 (사진만 변경한 경우)
    if (currentNorm == originalNorm) {
      return true;
    }

    // 닉네임이 변경되었으면 validation 통과 필요
    if (!nicknameValidation.isValid) {
      return false;
    }

    // ✅ "현재 닉네임에 대한 available 결과"일 때만 저장 활성화
    // availabilityNorm이 현재 norm과 일치해야 함 (스테일 응답 방지)
    final result = nicknameAvailability == NicknameAvailabilityStatus.available &&
        availabilityNorm == currentNorm;

    // 디버그 로그: available인데 canSave=false인 경우 원인 추적
    if (kDebugMode && nicknameAvailability == NicknameAvailabilityStatus.available && !result) {
      debugPrint(
        '$_logPrefix canSave=false (available) '
        'nickname=$nickname '
        'currentNorm=$currentNorm '
        'originalNorm=$originalNorm '
        'nicknameChanged=$nicknameChanged '
        'avatarChanged=$avatarChanged '
        'hasChanges=$hasChanges '
        'availabilityNorm=$availabilityNorm '
        'nicknameAvailability=$nicknameAvailability',
      );
    }

    return result;
  }
}

final profileEditControllerProvider =
    NotifierProvider.autoDispose<ProfileEditController, ProfileEditState>(
  ProfileEditController.new,
);

class ProfileEditController extends Notifier<ProfileEditState> {
  ProfileRepository get _profileRepository =>
      ref.read(profileRepositoryProvider);

  Timer? _debounceTimer;
  String? _lastCheckedNickname;
  String? _requestedNicknameNorm; // 요청 시점의 정규화된 닉네임 (스테일 응답 가드)
  int _checkSeq = 0; // 스테일 응답 가드를 위한 시퀀스
  ProfileError? lastError; // 마지막 에러 저장

  /// 현재 입력값의 정규화된 닉네임 (단일 계산 지점)
  String get _currentNorm {
    return state.currentNorm;
  }

  @override
  ProfileEditState build() {
    // 초기 프로필 로드
    Future.microtask(() => _loadInitialProfile());
    // dispose 등록
    ref.onDispose(_dispose);
    return ProfileEditState.initial();
  }

  /// 초기 프로필 로드
  Future<void> _loadInitialProfile() async {
    final sessionState = ref.read(sessionManagerProvider);
    final accessToken = sessionState.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix _loadInitialProfile: accessToken 없음');
      }
      return;
    }

    try {
      final profile = await _profileRepository.getMyProfile(
        accessToken: accessToken,
      );
      if (profile != null) {
        state = ProfileEditState.initial(
          initialNickname: profile.nickname,
          initialAvatarPath: profile.avatarPath,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix _loadInitialProfile 실패: $e');
      }
    }
  }

  /// 닉네임 업데이트 (디바운스 처리, norm 기준으로 변경 판정)
  void updateNickname(String value) {
    // 즉시 검증
    final validation = NicknameValidator.validate(value);
    final valueTrimmed = value.trim();
    final originalNicknameTrimmed = (state.originalNickname ?? '').trim();

    // norm 기준으로 변경 판정 (DB와 동일 기준)
    final currentNorm = NicknameValidator.normalize(valueTrimmed);
    final originalNorm = NicknameValidator.normalize(originalNicknameTrimmed);

    // 닉네임이 변경되지 않았으면(원본으로 되돌림) idle로 설정하고 이전 결과 무효화
    if (currentNorm == originalNorm) {
      state = state.copyWith(
        nickname: value,
        nicknameValidation: validation,
        nicknameAvailability: NicknameAvailabilityStatus.idle,
        availabilityNorm: null, // 이전 결과 무효화
      );
      _debounceTimer?.cancel();
      return;
    }

    // 닉네임이 변경되었으면 즉시 상태 설정 (이전 결과 무효화)
    // validation.isValid가 true면 checking으로 설정하여 서버 체크 대기
    // validation.isValid가 false면 idle로 설정하여 저장 버튼 비활성화
    final availability = validation.isValid
        ? NicknameAvailabilityStatus.checking
        : NicknameAvailabilityStatus.idle;

    state = state.copyWith(
      nickname: value,
      nicknameValidation: validation,
      nicknameAvailability: availability,
      availabilityNorm: null, // 입력 변경 시 이전 결과 무효화
    );

    // 디바운스 타이머 취소
    _debounceTimer?.cancel();

    // 규칙 통과 시에만 서버 체크
    if (validation.isValid && valueTrimmed != _lastCheckedNickname) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _checkNicknameAvailability(valueTrimmed);
      });
    }
    // validation 실패 시에는 이미 idle로 설정했으므로 추가 작업 없음
  }

  /// 닉네임 가용 여부 체크 (norm 기준으로 변경 판정 및 상태 매칭)
  Future<void> _checkNicknameAvailability(String nickname) async {
    // norm 기준으로 변경 판정
    final nicknameTrimmed = nickname.trim();
    final originalNicknameTrimmed = (state.originalNickname ?? '').trim();
    final currentNorm = NicknameValidator.normalize(nicknameTrimmed);
    final originalNorm = NicknameValidator.normalize(originalNicknameTrimmed);

    // 자신의 원본 닉네임과 동일하면(norm 기준) 체크 스킵
    if (currentNorm == originalNorm) {
      state = state.copyWith(
        nicknameAvailability: NicknameAvailabilityStatus.available,
        availabilityNorm: currentNorm,
      );
      _lastCheckedNickname = nickname;
      _requestedNicknameNorm = currentNorm;
      return;
    }

    // 시퀀스 증가 및 요청 시점 닉네임 정규화 저장 (스테일 응답 가드)
    final currentSeq = ++_checkSeq;
    final requestedNorm = currentNorm;
    _lastCheckedNickname = nickname;
    _requestedNicknameNorm = requestedNorm;

    // checking 상태는 이미 updateNickname에서 설정됨

    final sessionState = ref.read(sessionManagerProvider);
    final accessToken = sessionState.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      // 스테일 응답 가드
      if (currentSeq != _checkSeq || requestedNorm != _requestedNicknameNorm) {
        return;
      }
      state = state.copyWith(
        nicknameAvailability: NicknameAvailabilityStatus.error,
        availabilityNorm: null,
      );
      return;
    }

    try {
      final available = await _profileRepository.checkNicknameAvailable(
        nickname: nickname,
        accessToken: accessToken,
      );

      // 스테일 응답 가드: 시퀀스 + 정규화된 닉네임 모두 일치해야만 적용 (3중 체크)
      final currentNicknameNorm = _currentNorm;
      if (currentSeq != _checkSeq || 
          requestedNorm != currentNicknameNorm || 
          requestedNorm != _requestedNicknameNorm) {
        if (kDebugMode) {
          debugPrint('$_logPrefix _checkNicknameAvailability: 스테일 응답 무시 (seq: $currentSeq vs $_checkSeq, norm: $requestedNorm vs $currentNicknameNorm)');
        }
        return;
      }

      // ✅ 성공 응답 반영: available/taken 모두 availabilityNorm 설정
      final newAvailability = available
          ? NicknameAvailabilityStatus.available
          : NicknameAvailabilityStatus.taken;
      
      state = state.copyWith(
        nicknameAvailability: newAvailability,
        availabilityNorm: requestedNorm, // 결과가 어떤 norm에 대한 것인지 저장
      );

      // 디버그 로그: 응답 반영 시 상태 확인
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix _checkNicknameAvailability 응답 반영: '
          'available=$available '
          'currentNorm=$currentNicknameNorm '
          'requestedNorm=$requestedNorm '
          'availabilityNorm=${state.availabilityNorm} '
          'hasChanges=${state.hasChanges} '
          'canSave=${state.canSave}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix _checkNicknameAvailability 실패: $e');
      }
      // 스테일 응답 가드
      final currentNicknameNorm = _currentNorm;
      if (currentSeq != _checkSeq || 
          requestedNorm != currentNicknameNorm || 
          requestedNorm != _requestedNicknameNorm) {
        return;
      }
      // ✅ 실패 응답 반영: availabilityNorm은 null 유지 (실패가 "사용 가능"처럼 보이면 안 됨)
      state = state.copyWith(
        nicknameAvailability: NicknameAvailabilityStatus.error,
        availabilityNorm: null, // 실패 시 availabilityNorm 업데이트하지 않음
      );
    }
  }

  /// 아바타 업데이트
  void updateAvatar(Uint8List bytes) {
    state = state.copyWith(avatarBytes: bytes);
  }

  /// 저장
  Future<bool> save() async {
    if (!state.canSave) {
      return false;
    }

    state = state.copyWith(isSaving: true);

    final sessionState = ref.read(sessionManagerProvider);
    final accessToken = sessionState.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(isSaving: false);
      return false;
    }

    try {
      final previousAvatarPath = state.originalAvatarPath;
      final avatarChanged = state.avatarBytes != null;

      // 아바타 업로드 (변경된 경우)
      String? avatarUrl;
      if (state.avatarBytes != null) {
        avatarUrl = await _profileRepository.uploadAvatar(
          imageBytes: state.avatarBytes!,
          accessToken: accessToken,
        );
      }

      // 부분 업데이트: 변경된 필드만 전달
      final nicknameToSend = state.nicknameChanged
          ? (state.nickname.trim().isEmpty ? null : state.nickname.trim())
          : null;
      final avatarPathToSend = avatarChanged ? avatarUrl : null;
      
      if (kDebugMode) {
        final patchKeys = <String>[];
        if (nicknameToSend != null) patchKeys.add('nickname');
        if (avatarPathToSend != null) patchKeys.add('avatarPath');
        debugPrint(
          '$_logPrefix save: '
          'nicknameChanged=${state.nicknameChanged} '
          'avatarChanged=$avatarChanged '
          'patchKeys=[${patchKeys.join(", ")}] '
          'nickname=${nicknameToSend ?? "<omitted>"} '
          'avatarPath=${avatarPathToSend ?? "<omitted>"}',
        );
      }

      // 프로필 업데이트
      final updatedProfile = await _profileRepository.updateProfile(
        nickname: nicknameToSend,
        avatarPath: avatarPathToSend, // uploadAvatar가 path를 반환
        accessToken: accessToken,
      );

      state = state.copyWith(
        isSaving: false,
        originalNickname: updatedProfile.nickname,
        originalAvatarPath: updatedProfile.avatarPath,
        avatarBytes: null, // 저장 후 초기화 (hasChanges는 getter로 자동 계산됨)
      );

      ref.invalidate(profileProvider);
      if (avatarChanged) {
        final updatedAvatarPath = updatedProfile.avatarPath;
        if (updatedAvatarPath != null && updatedAvatarPath.isNotEmpty) {
          ref.invalidate(avatarSignedUrlProvider(updatedAvatarPath));
        }
        if (previousAvatarPath != null &&
            previousAvatarPath.isNotEmpty &&
            previousAvatarPath != updatedAvatarPath) {
          ref.invalidate(avatarSignedUrlProvider(previousAvatarPath));
        }
      }

      return true;
    } on ProfileException catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix save 실패: $e');
      }

      lastError = e.error; // 에러 저장

      // 닉네임 관련 에러 처리
      if (e.error == ProfileError.nicknameTaken) {
        state = state.copyWith(
          isSaving: false,
          nicknameAvailability: NicknameAvailabilityStatus.taken,
        );
      } else if (e.error == ProfileError.nicknameForbidden) {
        state = state.copyWith(
          isSaving: false,
          nicknameAvailability: NicknameAvailabilityStatus.taken, // UI에서는 taken으로 표시
        );
      } else if (e.error == ProfileError.nicknameInvalidFormat) {
        state = state.copyWith(
          isSaving: false,
          nicknameAvailability: NicknameAvailabilityStatus.error,
        );
      } else if (e.error == ProfileError.imageTooLarge ||
          e.error == ProfileError.imageOptimizationFailed) {
        // 이미지 에러는 UI에서 별도 처리
        state = state.copyWith(isSaving: false);
      } else {
        state = state.copyWith(isSaving: false);
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix save 예외: $e');
      }
      lastError = null;
      state = state.copyWith(isSaving: false);
      return false;
    }
  }

  void _dispose() {
    _debounceTimer?.cancel();
  }
}
