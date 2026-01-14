import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/app_permission_service.dart';
import '../../../core/session/ensure_session_mode.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/validation/text_rules.dart';
import '../application/compose_image_pipeline.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/compose_picked_image.dart';
import '../domain/journey_repository.dart';
import '../domain/journey_storage_repository.dart';

const int journeyMaxLength = 500;
const int journeyMaxImages = 3;

enum JourneyComposeMessage {
  emptyContent,
  invalidContent,
  tooLong,
  forbidden,
  contentBlocked, // moderation BLOCK
  imageLimitExceeded,
  permissionDenied,
  missingSession,
  serverMisconfigured,
  missingRecipientCount,
  invalidRecipientCount,
  submitFailed,
  submitSuccess,
  imageReadFailed,
  imageOptimizationFailed,
}

class JourneyComposeState {
  const JourneyComposeState({
    required this.content,
    required this.images,
    required this.isSubmitting,
    required this.message,
    required this.recipientCount,
    this.sessionId,
  });

  final String content;
  final List<ComposePickedImage> images;
  final bool isSubmitting;
  final JourneyComposeMessage? message;
  final int? recipientCount;
  final String? sessionId; // 임시 파일 정리용

  factory JourneyComposeState.initial() => const JourneyComposeState(
    content: '',
    images: [],
    isSubmitting: false,
    message: null,
    recipientCount: 3, // 기본값 3명
    sessionId: null,
  );

  JourneyComposeState copyWith({
    String? content,
    List<ComposePickedImage>? images,
    bool? isSubmitting,
    JourneyComposeMessage? message,
    int? recipientCount,
    String? sessionId,
    bool clearMessage = false,
  }) {
    return JourneyComposeState(
      content: content ?? this.content,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: clearMessage ? null : message ?? this.message,
      recipientCount: recipientCount ?? this.recipientCount,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

final journeyComposeControllerProvider =
    NotifierProvider.autoDispose<JourneyComposeController, JourneyComposeState>(
      JourneyComposeController.new,
    );

class JourneyComposeController extends Notifier<JourneyComposeState> {
  @override
  JourneyComposeState build() {
    return JourneyComposeState.initial();
  }

  void updateContent(String value) {
    state = state.copyWith(content: value);
  }

  void updateRecipientCount(int? count) {
    state = state.copyWith(recipientCount: count);
  }

  void removeImageAt(int index) {
    final updated = [...state.images]..removeAt(index);
    state = state.copyWith(images: updated);
  }

  Future<PermissionStatus> pickImages() async {
    if (kDebugMode) {
      debugPrint('compose: 이미지 선택 시작');
    }
    final permissionService = ref.read(appPermissionServiceProvider);
    final permission = await permissionService.requestPhotoPermission();
    if (!permission.isGranted && !permission.isLimited) {
      if (!permission.isPermanentlyDenied) {
        state = state.copyWith(message: JourneyComposeMessage.permissionDenied);
      }
      if (kDebugMode) {
        debugPrint('compose: 이미지 권한 거부 ($permission)');
      }
      return permission;
    }
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isEmpty) {
      if (kDebugMode) {
        debugPrint('compose: 이미지 선택 없음');
      }
      return permission;
    }

    // 기존 이미지와 합쳐서 최대 개수 계산
    final currentCount = state.images.length;
    final remainingSlots = journeyMaxImages - currentCount;
    if (remainingSlots <= 0) {
      state = state.copyWith(
        message: JourneyComposeMessage.imageLimitExceeded,
      );
      if (kDebugMode) {
        debugPrint('compose: 이미지 개수 제한 초과 (이미 $currentCount장)');
      }
      return permission;
    }

    // 이미지 파이프라인으로 준비 (안전한 복사 + 최적화)
    try {
      final prepared = await ComposeImagePipeline.preparePickedImages(
        picked,
        maxCount: remainingSlots,
      );

      if (prepared.isEmpty) {
        state = state.copyWith(
          message: JourneyComposeMessage.imageReadFailed,
        );
        if (kDebugMode) {
          debugPrint('compose: 이미지 준비 실패 (모든 파일 처리 실패)');
        }
        return permission;
      }

      // 세션 ID 추출 (첫 번째 이미지의 경로에서)
      String? sessionId;
      if (prepared.isNotEmpty) {
        final firstPath = prepared.first.localPath;
        final pathParts = firstPath.split('/');
        final composeUploadsIndex = pathParts.indexWhere(
          (part) => part == 'compose_uploads',
        );
        if (composeUploadsIndex >= 0 &&
            composeUploadsIndex + 1 < pathParts.length) {
          sessionId = pathParts[composeUploadsIndex + 1];
        }
      }

      final merged = [...state.images, ...prepared];
      if (merged.length > journeyMaxImages) {
        // 초과분은 임시 파일 정리
        final excess = merged.sublist(journeyMaxImages);
        for (final img in excess) {
          try {
            final file = File(img.localPath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (e) {
            // 정리 실패는 무시
          }
        }
        state = state.copyWith(
          images: merged.take(journeyMaxImages).toList(),
          message: JourneyComposeMessage.imageLimitExceeded,
          sessionId: sessionId ?? state.sessionId,
        );
        if (kDebugMode) {
          debugPrint(
            'compose: 이미지 개수 제한 초과 (${merged.length}장 → $journeyMaxImages장)',
          );
        }
        return permission;
      }

      state = state.copyWith(
        images: merged,
        sessionId: sessionId ?? state.sessionId,
      );
      if (kDebugMode) {
        debugPrint('compose: 이미지 선택 완료 (${state.images.length}장)');
      }
      return permission;
    } on FileSystemException catch (e) {
      if (kDebugMode) {
        debugPrint(
          'compose: 이미지 읽기 실패 (FileSystemException: ${e.osError?.errorCode}, ${e.osError?.message}, path=${e.path})',
        );
      }
      state = state.copyWith(message: JourneyComposeMessage.imageReadFailed);
      return permission;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('compose: 이미지 최적화 실패: $e\n$stackTrace');
      }
      state = state.copyWith(
        message: JourneyComposeMessage.imageOptimizationFailed,
      );
      return permission;
    }
  }

  Future<void> submit({required String languageTag}) async {
    if (kDebugMode) {
      debugPrint('compose: 전송 시작');
    }
    final content = state.content.trim();
    // recipientCount 보정: null이면 3, 범위 밖이면 clamp
    var recipientCount = state.recipientCount;
    if (recipientCount == null) {
      recipientCount = 3;
    } else if (recipientCount < 1) {
      recipientCount = 1;
    } else if (recipientCount > 5) {
      recipientCount = 5;
    }
    if (content.isEmpty) {
      state = state.copyWith(message: JourneyComposeMessage.emptyContent);
      if (kDebugMode) {
        debugPrint('compose: 내용 비어있음');
      }
      return;
    }
    if (content.length > journeyMaxLength ||
        containsForbiddenPattern(content)) {
      state = state.copyWith(message: JourneyComposeMessage.invalidContent);
      if (kDebugMode) {
        debugPrint('compose: 내용 검증 실패');
      }
      return;
    }

    // ✅ 전송 직전 세션 선검증/갱신 강제 (이미지 유무와 상관없이)
    if (kDebugMode) {
      debugPrint('compose: ensureSessionReady 시작');
    }
    final sessionManager = ref.read(sessionManagerProvider.notifier);
    final sessionReady = await sessionManager.ensureSessionReady(
      mode: EnsureSessionMode.silent,
    );
    if (!sessionReady) {
      if (kDebugMode) {
        debugPrint('compose: ensureSessionReady 실패 → 세션 만료');
      }
      state = state.copyWith(message: JourneyComposeMessage.missingSession);
      return;
    }
    if (kDebugMode) {
      debugPrint('compose: ensureSessionReady 성공');
    }

    final accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      state = state.copyWith(message: JourneyComposeMessage.missingSession);
      if (kDebugMode) {
        debugPrint('compose: 세션 없음');
      }
      return;
    }
    state = state.copyWith(isSubmitting: true);
    List<String> uploadedPaths = [];
    final sessionId = state.sessionId;
    try {
      if (state.images.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 시작 (${state.images.length}장)');
        }

        // 업로드 직전 검증
        for (final img in state.images) {
          await ComposeImagePipeline.validateBeforeUpload(img.localPath);
        }

        final storageRepository = ref.read(journeyStorageRepositoryProvider);
        uploadedPaths = await storageRepository.uploadImages(
          filePaths: state.images.map((img) => img.localPath).toList(),
          accessToken: accessToken,
        );
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 완료 (${uploadedPaths.length}건)');
        }
      }
      if (kDebugMode) {
        debugPrint(
          'compose: create_journey 요청 (recipientCount=$recipientCount, '
          'images=${uploadedPaths.length}, lang=$languageTag)',
        );
      }
      await _createJourneyWithRetry(
        content: content,
        languageTag: languageTag,
        imagePaths: uploadedPaths,
        recipientCount: recipientCount,
      );
      // ✅ dispatch는 백엔드 워커가 자동 처리 (GitHub Actions cron)
      // 클라이언트에서 별도 호출 불필요
      if (kDebugMode) {
        debugPrint('compose: RPC 호출 완료 (dispatch는 백엔드 워커가 처리)');
      }
      // 성공 시 임시 파일 정리
      if (sessionId != null) {
        await ComposeImagePipeline.cleanupSession(sessionId);
      }

      state = state.copyWith(
        content: '',
        images: [],
        isSubmitting: false,
        message: JourneyComposeMessage.submitSuccess,
        sessionId: null,
      );
    } on JourneyCreationException catch (exception) {
      if (kDebugMode) {
        debugPrint('compose: 전송 실패 (${exception.error})');
      }
      await _handleCreationFailure(
        accessToken: accessToken,
        uploadedPaths: uploadedPaths,
        exception: exception,
      );
    } on JourneyStorageException {
      if (kDebugMode) {
        debugPrint('compose: 이미지 업로드 실패');
      }
      // 실패 시 임시 파일 정리
      if (sessionId != null) {
        await ComposeImagePipeline.cleanupSession(sessionId);
      }
      state = state.copyWith(
        isSubmitting: false,
        message: JourneyComposeMessage.submitFailed,
        sessionId: null,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('compose: 알 수 없는 오류 ($error)');
      }
      if (uploadedPaths.isNotEmpty) {
        final storageRepository = ref.read(journeyStorageRepositoryProvider);
        await storageRepository.deleteImages(
          paths: uploadedPaths,
          accessToken: accessToken,
        );
      }
      // 실패 시 임시 파일 정리
      if (sessionId != null) {
        await ComposeImagePipeline.cleanupSession(sessionId);
      }
      state = state.copyWith(
        isSubmitting: false,
        message: JourneyComposeMessage.submitFailed,
        sessionId: null,
      );
    }
  }

  Future<void> _handleCreationFailure({
    required String accessToken,
    required List<String> uploadedPaths,
    required JourneyCreationException exception,
  }) async {
    if (uploadedPaths.isNotEmpty) {
      final storageRepository = ref.read(journeyStorageRepositoryProvider);
      await storageRepository.deleteImages(
        paths: uploadedPaths,
        accessToken: accessToken,
      );
    }
    state = state.copyWith(
      isSubmitting: false,
      message: _mapCreationError(exception),
    );
  }

  JourneyComposeMessage _mapCreationError(JourneyCreationException? exception) {
    final error = exception?.error;
    switch (error) {
      case JourneyCreationError.emptyContent:
        return JourneyComposeMessage.emptyContent;
      case JourneyCreationError.contentTooLong:
        return JourneyComposeMessage.tooLong;
      case JourneyCreationError.tooManyImages:
        return JourneyComposeMessage.imageLimitExceeded;
      case JourneyCreationError.containsForbidden:
        return JourneyComposeMessage.forbidden;
      case JourneyCreationError.contentBlocked:
        return JourneyComposeMessage.contentBlocked;
      case JourneyCreationError.missingCodeValue:
        return JourneyComposeMessage.serverMisconfigured;
      case JourneyCreationError.invalidRecipientCount:
        return JourneyComposeMessage.invalidRecipientCount;
      case JourneyCreationError.unauthorized:
        return JourneyComposeMessage.missingSession;
      case JourneyCreationError.missingLanguage:
      case JourneyCreationError.invalidPayload:
      case JourneyCreationError.serverRejected:
      case JourneyCreationError.network:
      case JourneyCreationError.unknown:
      case JourneyCreationError.missingConfig:
      default:
        return JourneyComposeMessage.submitFailed;
    }
  }

  void clearMessage() {
    state = state.copyWith(clearMessage: true);
  }

  /// 작성 상태를 초기화합니다.
  /// 화면 이탈 시 또는 계정 전환 시 호출됩니다.
  void reset() {
    // 임시 파일 정리
    final sessionId = state.sessionId;
    if (sessionId != null) {
      ComposeImagePipeline.cleanupSession(sessionId).catchError((e) {
        // 정리 실패는 무시
        if (kDebugMode) {
          debugPrint('compose: reset 시 임시 파일 정리 실패: $e');
        }
      });
    }
    state = JourneyComposeState.initial();
  }

  // Commit 작업: 자동 재시도 금지, 401이면 missingSession 처리
  Future<JourneyCreationResult> _createJourneyWithRetry({
    required String content,
    required String languageTag,
    required List<String> imagePaths,
    required int recipientCount,
  }) async {
    var accessToken = ref.read(sessionManagerProvider).accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw JourneyCreationException(JourneyCreationError.unauthorized);
    }

    // Commit 작업은 자동 재시도 금지 정책 준수
    // 401 발생 시 예외를 그대로 전달하여 상위에서 missingSession 처리
    final journeyRepository = ref.read(journeyRepositoryProvider);
    return await journeyRepository.createJourney(
      content: content,
      languageTag: languageTag,
      imagePaths: imagePaths,
      recipientCount: recipientCount,
      accessToken: accessToken,
    );
  }
}
