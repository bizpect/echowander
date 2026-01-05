import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permissions/app_permission_service.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/validation/text_rules.dart';
import '../data/supabase_journey_repository.dart';
import '../domain/journey_repository.dart';
import '../domain/journey_storage_repository.dart';

const int journeyMaxLength = 500;
const int journeyMaxImages = 3;

enum JourneyComposeMessage {
  emptyContent,
  invalidContent,
  tooLong,
  forbidden,
  imageLimitExceeded,
  permissionDenied,
  missingSession,
  serverMisconfigured,
  missingRecipientCount,
  invalidRecipientCount,
  submitFailed,
  submitSuccess,
}

class JourneyComposeState {
  const JourneyComposeState({
    required this.content,
    required this.images,
    required this.isSubmitting,
    required this.message,
    required this.recipientCount,
  });

  final String content;
  final List<XFile> images;
  final bool isSubmitting;
  final JourneyComposeMessage? message;
  final int? recipientCount;

  factory JourneyComposeState.initial() => const JourneyComposeState(
        content: '',
        images: [],
        isSubmitting: false,
        message: null,
        recipientCount: null,
      );

  JourneyComposeState copyWith({
    String? content,
    List<XFile>? images,
    bool? isSubmitting,
    JourneyComposeMessage? message,
    int? recipientCount,
    bool clearMessage = false,
  }) {
    return JourneyComposeState(
      content: content ?? this.content,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: clearMessage ? null : message ?? this.message,
      recipientCount: recipientCount ?? this.recipientCount,
    );
  }
}

final journeyComposeControllerProvider =
    NotifierProvider<JourneyComposeController, JourneyComposeState>(
  JourneyComposeController.new,
);

class JourneyComposeController extends Notifier<JourneyComposeState> {
  late final AppPermissionService _permissionService;
  late final JourneyRepository _journeyRepository;
  late final JourneyStorageRepository _storageRepository;

  @override
  JourneyComposeState build() {
    _permissionService = ref.read(appPermissionServiceProvider);
    _journeyRepository = ref.read(journeyRepositoryProvider);
    _storageRepository = ref.read(journeyStorageRepositoryProvider);
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
    final permission = await _permissionService.requestPhotoPermission();
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
    final merged = [...state.images, ...picked];
    if (merged.length > journeyMaxImages) {
      state = state.copyWith(
        images: merged.take(journeyMaxImages).toList(),
        message: JourneyComposeMessage.imageLimitExceeded,
      );
      if (kDebugMode) {
        debugPrint('compose: 이미지 개수 제한 초과');
      }
      return permission;
    }
    state = state.copyWith(images: merged);
    if (kDebugMode) {
      debugPrint('compose: 이미지 선택 완료 (${state.images.length}장)');
    }
    return permission;
  }

  Future<void> submit({required String languageTag}) async {
    if (kDebugMode) {
      debugPrint('compose: 전송 시작');
    }
    final content = state.content.trim();
    final recipientCount = state.recipientCount;
    if (recipientCount == null) {
      state = state.copyWith(message: JourneyComposeMessage.missingRecipientCount);
      if (kDebugMode) {
        debugPrint('compose: 릴레이 인원 미선택');
      }
      return;
    }
    if (content.isEmpty) {
      state = state.copyWith(message: JourneyComposeMessage.emptyContent);
      if (kDebugMode) {
        debugPrint('compose: 내용 비어있음');
      }
      return;
    }
    if (content.length > journeyMaxLength || containsForbiddenPattern(content)) {
      state = state.copyWith(message: JourneyComposeMessage.invalidContent);
      if (kDebugMode) {
        debugPrint('compose: 내용 검증 실패');
      }
      return;
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
    try {
      if (state.images.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 시작 (${state.images.length}장)');
        }
        uploadedPaths = await _storageRepository.uploadImages(
          filePaths: state.images.map((file) => file.path).toList(),
          accessToken: accessToken,
        );
        if (kDebugMode) {
          debugPrint('compose: 이미지 업로드 완료 (${uploadedPaths.length}건)');
        }
      }
      if (kDebugMode) {
        debugPrint('compose: RPC 호출 시작');
      }
      final result = await _journeyRepository.createJourney(
        content: content,
        languageTag: languageTag,
        imagePaths: uploadedPaths,
        recipientCount: recipientCount,
        accessToken: accessToken,
      );
      await _journeyRepository.dispatchJourneyMatch(
        journeyId: result.journeyId,
        accessToken: accessToken,
      );
      if (kDebugMode) {
        debugPrint('compose: RPC 호출 완료');
      }
      state = state.copyWith(
        content: '',
        images: [],
        isSubmitting: false,
        message: JourneyComposeMessage.submitSuccess,
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
      state = state.copyWith(
        isSubmitting: false,
        message: JourneyComposeMessage.submitFailed,
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('compose: 알 수 없는 오류 ($error)');
      }
      if (uploadedPaths.isNotEmpty) {
        await _storageRepository.deleteImages(
          paths: uploadedPaths,
          accessToken: accessToken,
        );
      }
      state = state.copyWith(
        isSubmitting: false,
        message: JourneyComposeMessage.submitFailed,
      );
    }
  }

  Future<void> _handleCreationFailure({
    required String accessToken,
    required List<String> uploadedPaths,
    required JourneyCreationException exception,
  }) async {
    if (uploadedPaths.isNotEmpty) {
      await _storageRepository.deleteImages(
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
}
