import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/logging/server_error_logger.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/network_guard.dart';
import '../../../core/session/auth_executor.dart';
import '../../../core/utils/image_optimizer.dart';
import '../domain/profile_repository.dart';

const _logPrefix = '[ProfileRepo]';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return SupabaseProfileRepository(config: AppConfigStore.current);
});

class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository({required AppConfig config})
    : _config = config,
      _errorLogger = ServerErrorLogger(config: config),
      _networkGuard = NetworkGuard(
        errorLogger: ServerErrorLogger(config: config),
      ),
      _client = HttpClient();

  final AppConfig _config;
  final ServerErrorLogger _errorLogger;
  final NetworkGuard _networkGuard;
  final HttpClient _client;

  @override
  Future<bool> checkNicknameAvailable({
    required String nickname,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix checkNicknameAvailable: 설정 누락');
      }
      throw ProfileException(ProfileError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix checkNicknameAvailable: accessToken 없음');
      }
      throw ProfileException(ProfileError.unauthorized);
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/check_nickname_available',
    );

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<bool>(
        operation: () => _executeCheckNicknameAvailable(
          uri: uri,
          nickname: nickname,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'check_nickname_available',
        uri: uri,
        method: 'POST',
        meta: {'nickname_length': nickname.length},
        accessToken: accessToken,
      );

      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix checkNicknameAvailable NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw ProfileException(ProfileError.network);
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
          throw ProfileException(ProfileError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw ProfileException(ProfileError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw ProfileException(ProfileError.serverRejected);
      }
    }
  }

  @override
  Future<ProfileData> updateProfile({
    String? nickname,
    String? avatarPath,
    required String accessToken,
  }) async {
    final normalizedNickname =
        (nickname != null && nickname.trim().isNotEmpty) ? nickname : null;
    final normalizedAvatarPath =
        (avatarPath != null && avatarPath.trim().isNotEmpty)
            ? avatarPath
            : null;
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix updateProfile: 설정 누락');
      }
      throw ProfileException(ProfileError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix updateProfile: accessToken 없음');
      }
      throw ProfileException(ProfileError.unauthorized);
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/update_my_profile',
    );

    try {
      // NetworkGuard를 통한 요청 실행 (재시도 없음: 커밋 액션)
      final result = await _networkGuard.execute<ProfileData>(
        operation: () => _executeUpdateProfile(
          uri: uri,
          nickname: normalizedNickname,
          avatarPath: normalizedAvatarPath,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'update_my_profile',
        uri: uri,
        method: 'POST',
        meta: {
          'has_nickname': normalizedNickname != null,
          'has_avatar_path': normalizedAvatarPath != null,
        },
        accessToken: accessToken,
      );

      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix updateProfile NetworkRequestException: $error');
      }

      // 서버 에러 바디에서 에러 코드 확인
      final errorCode = _extractErrorCode(error.originalError?.toString() ?? '');
      if (errorCode == 'nickname_taken') {
        throw ProfileException(ProfileError.nicknameTaken);
      }
      if (errorCode == 'nickname_forbidden') {
        throw ProfileException(ProfileError.nicknameForbidden);
      }
      if (errorCode == 'nickname_invalid_format') {
        throw ProfileException(ProfileError.nicknameInvalidFormat);
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw ProfileException(ProfileError.network);
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
          throw ProfileException(ProfileError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw ProfileException(ProfileError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw ProfileException(ProfileError.serverRejected);
      }
    }
  }

  @override
  Future<ProfileData?> getMyProfile({
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getMyProfile: 설정 누락');
      }
      throw ProfileException(ProfileError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getMyProfile: accessToken 없음');
      }
      throw ProfileException(ProfileError.unauthorized);
    }

    final uri = Uri.parse(
      '${_config.supabaseUrl}/rest/v1/rpc/get_my_profile',
    );

    try {
      // NetworkGuard를 통한 요청 실행 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<ProfileData?>(
        operation: () => _executeGetMyProfile(
          uri: uri,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        meta: const {},
        accessToken: accessToken,
      );

      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getMyProfile NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw ProfileException(ProfileError.network);
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
          throw ProfileException(ProfileError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw ProfileException(ProfileError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw ProfileException(ProfileError.serverRejected);
      }
    }
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String accessToken,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar: 설정 누락');
      }
      throw ProfileException(ProfileError.missingConfig);
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar: accessToken 없음');
      }
      throw ProfileException(ProfileError.unauthorized);
    }

    // 이미지 최적화 (리사이즈/압축/용량 제한)
    Uint8List optimizedBytes;
    try {
      final result = await ImageOptimizer.optimizeAvatar(imageBytes);
      optimizedBytes = result.bytes;
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix uploadAvatar: 최적화 완료 '
          '${(imageBytes.length / 1024).toStringAsFixed(1)}KB → '
          '${(optimizedBytes.length / 1024).toStringAsFixed(1)}KB',
        );
      }
    } on ImageOptimizationException catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar: 이미지 최적화 실패: $e');
      }
      if (e.error == ImageOptimizationError.fileTooLarge) {
        throw ProfileException(ProfileError.imageTooLarge);
      }
      throw ProfileException(ProfileError.imageOptimizationFailed);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar: 이미지 최적화 예외: $e');
      }
      throw ProfileException(ProfileError.imageOptimizationFailed);
    }

    // JWT에서 user_id 추출
    final userId = JwtUtils.getUserId(accessToken);
    if (userId == null || userId.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar: JWT에서 user_id 추출 실패');
      }
      throw ProfileException(ProfileError.unauthorized);
    }

    // 버킷 ID와 경로 설정
    const bucketId = 'profile-avatars';
    final objectPath = '$userId/avatar.jpg';

    if (kDebugMode) {
      debugPrint(
        '$_logPrefix uploadAvatar bucket=$bucketId path=$objectPath',
      );
    }

    final uploadUri = _storageUri(bucketId, objectPath);

    try {
      // NetworkGuard를 통한 업로드 (재시도 없음: 커밋 액션)
      await _networkGuard.execute<void>(
        operation: () => _executeUploadAvatar(
          uri: uploadUri,
          storagePath: objectPath,
          bytes: optimizedBytes,
          accessToken: accessToken,
        ),
        retryPolicy: RetryPolicy.none,
        context: 'avatar_upload',
        uri: uploadUri,
        method: 'POST',
        meta: {
          'storage_path': objectPath,
          'bytes_length': optimizedBytes.length,
        },
        accessToken: accessToken,
      );

      // 업로드 성공 시 path 반환 (DB에 저장할 값)
      // signed URL은 표시 시점에 별도로 발급
      return objectPath;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix uploadAvatar NetworkRequestException: $error');
      }

      switch (error.type) {
        case NetworkErrorType.network:
        case NetworkErrorType.timeout:
          throw ProfileException(ProfileError.network);
        case NetworkErrorType.unauthorized:
        case NetworkErrorType.forbidden:
          throw ProfileException(ProfileError.unauthorized);
        case NetworkErrorType.invalidPayload:
          throw ProfileException(ProfileError.invalidPayload);
        case NetworkErrorType.serverUnavailable:
        case NetworkErrorType.serverRejected:
        case NetworkErrorType.missingConfig:
        case NetworkErrorType.unknown:
          throw ProfileException(ProfileError.serverRejected);
      }
    }
  }

  /// 아바타 업로드 실제 실행 (NetworkGuard가 호출)
  Future<void> _executeUploadAvatar({
    required Uri uri,
    required String storagePath,
    required Uint8List bytes,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.headers.set(HttpHeaders.contentTypeHeader, 'image/jpeg');
    request.headers.set('x-upsert', 'true');
    request.add(bytes);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok &&
        response.statusCode != HttpStatus.created) {
      await _errorLogger.logHttpFailure(
        context: 'avatar_upload',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'storage_path': storagePath},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'avatar_upload',
      );
    }
  }

  @override
  /// 아바타 signed URL 발급 (NetworkGuard 경유)
  Future<String?> getAvatarSignedUrl({
    required String objectPath,
    required String accessToken,
    int expiresInSeconds = 3600,
  }) async {
    if (_config.supabaseUrl.isEmpty || _config.supabaseAnonKey.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getAvatarSignedUrl: 설정 누락');
      }
      return null;
    }
    if (accessToken.isEmpty) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getAvatarSignedUrl: accessToken 없음');
      }
      return null;
    }

    const bucketId = 'profile-avatars';
    final uri = Uri.parse(
      '${_config.supabaseUrl}/storage/v1/object/sign/$bucketId/$objectPath',
    );

    try {
      // NetworkGuard를 통한 signed URL 발급 (조회용 짧은 재시도)
      final result = await _networkGuard.execute<String?>(
        operation: () => _executeGetSignedUrl(
          uri: uri,
          objectPath: objectPath,
          expiresInSeconds: expiresInSeconds,
          accessToken: accessToken,
          bucketId: bucketId,
        ),
        retryPolicy: RetryPolicy.short,
        context: 'avatar_signed_url',
        uri: uri,
        method: 'POST',
        meta: {
          'object_path': objectPath,
          'expires_in': expiresInSeconds,
        },
        accessToken: accessToken,
      );

      return result;
    } on NetworkRequestException catch (error) {
      if (kDebugMode) {
        debugPrint('$_logPrefix getAvatarSignedUrl NetworkRequestException: $error');
      }
      return null;
    }
  }

  /// signed URL 발급 실제 실행 (NetworkGuard가 호출)
  Future<String?> _executeGetSignedUrl({
    required Uri uri,
    required String objectPath,
    required int expiresInSeconds,
    required String accessToken,
    required String bucketId,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(jsonEncode({'expiresIn': expiresInSeconds})),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      // 404 발생 시 진단 로그 추가
      if (response.statusCode == HttpStatus.notFound && kDebugMode) {
        debugPrint(
          '$_logPrefix signed URL 발급 404: '
          'bucket=profile-avatars '
          'objectPath=$objectPath '
          'requestUri=$uri '
          'responseBody=$body',
        );
        debugPrint(
          '$_logPrefix 진단 SQL: '
          'select bucket_id, name, created_at '
          'from storage.objects '
          'where bucket_id=\'profile-avatars\' '
          'and name=\'$objectPath\';',
        );
      }

      await _errorLogger.logHttpFailure(
        context: 'avatar_signed_url',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'object_path': objectPath,
          'expires_in': expiresInSeconds,
          'bucket_id': 'profile-avatars',
        },
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'avatar_signed_url',
      );
    }

    final payload = jsonDecode(body);
    if (payload is Map<String, dynamic>) {
      final signed = payload['signedURL'] as String?;
      if (signed != null && signed.isNotEmpty) {
        // Supabase signedURL은 상대 경로로 반환됨
        // full URL인지 확인
        if (signed.startsWith('http://') || signed.startsWith('https://')) {
          // 이미 full URL이면 그대로 사용
          if (kDebugMode) {
            debugPrint(
              '$_logPrefix signed URL (full): $signed',
            );
          }
          return signed;
        }

        // 상대 경로인 경우: /storage/v1 포함 여부 확인
        final normalizedSigned = signed.startsWith('/')
            ? signed
            : '/$signed';

        // /storage/v1가 없으면 추가
        String finalPath;
        if (normalizedSigned.startsWith('/storage/v1/')) {
          finalPath = normalizedSigned;
        } else if (normalizedSigned.startsWith('/object/sign/')) {
          // /object/sign/... → /storage/v1/object/sign/...
          finalPath = '/storage/v1$normalizedSigned';
        } else {
          // 기타 경우: 그대로 사용 (이론상 발생하지 않아야 함)
          finalPath = normalizedSigned;
        }

        final finalUrl = '${_config.supabaseUrl}$finalPath';

        if (kDebugMode) {
          final hasStorageV1 = finalUrl.contains('/storage/v1/');
          debugPrint(
            '$_logPrefix signed URL 조합: '
            'bucket=$bucketId '
            'path=$objectPath '
            'hasStorageV1=$hasStorageV1 '
            'finalUrl=$finalUrl',
          );
        }

        return finalUrl;
      }
    }

    return null;
  }

  Uri _storageUri(String bucketId, String objectPath) {
    return Uri.parse(
      '${_config.supabaseUrl}/storage/v1/object/$bucketId/$objectPath',
    );
  }

  /// checkNicknameAvailable RPC 실제 실행 (NetworkGuard가 호출)
  Future<bool> _executeCheckNicknameAvailable({
    required Uri uri,
    required String nickname,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(
      utf8.encode(
        jsonEncode({'nickname': nickname}),
      ),
    );

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'check_nickname_available',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {'nickname_length': nickname.length},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'check_nickname_available',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! bool) {
      throw const FormatException('Invalid payload format');
    }

    return payload;
  }

  /// updateProfile RPC 실제 실행 (NetworkGuard가 호출)
  Future<ProfileData> _executeUpdateProfile({
    required Uri uri,
    String? nickname,
    String? avatarPath,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    
    // 부분 업데이트: null이 아닌 필드만 JSON에 포함
    final requestPayload = <String, dynamic>{};
    if (nickname != null) {
      requestPayload['nickname'] = nickname;
    }
    if (avatarPath != null) {
      requestPayload['avatar_url'] = avatarPath; // DB 컬럼명은 avatar_url이지만 값은 path
    }
    // bio는 현재 미사용이므로 항상 null로 전달 (변경 없음)
    requestPayload['bio'] = null;
    
    request.add(utf8.encode(jsonEncode(requestPayload)));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'update_my_profile',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: {
          'has_nickname': nickname != null,
          'has_avatar_path': avatarPath != null,
        },
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'update_my_profile',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List || payload.isEmpty) {
      throw const FormatException('Invalid payload format');
    }

    final row = payload.first as Map<String, dynamic>;
    return ProfileData(
      userId: row['user_id'] as String,
      nickname: row['nickname'] as String?,
      avatarPath: row['avatar_url'] as String?, // DB 컬럼명은 avatar_url이지만 값은 path
      bio: row['bio'] as String?,
    );
  }

  /// getMyProfile RPC 실제 실행 (NetworkGuard가 호출)
  Future<ProfileData?> _executeGetMyProfile({
    required Uri uri,
    required String accessToken,
  }) async {
    final request = await _client.postUrl(uri);
    request.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.headers.set('apikey', _config.supabaseAnonKey);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $accessToken');
    request.add(utf8.encode(jsonEncode({})));

    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode != HttpStatus.ok) {
      await _errorLogger.logHttpFailure(
        context: 'get_my_profile',
        uri: uri,
        method: 'POST',
        statusCode: response.statusCode,
        errorMessage: body,
        meta: const {},
        accessToken: accessToken,
      );

      throw _networkGuard.statusCodeToException(
        statusCode: response.statusCode,
        responseBody: body,
        context: 'get_my_profile',
      );
    }

    final payload = jsonDecode(body);
    if (payload is! List) {
      throw const FormatException('Invalid payload format');
    }

    if (payload.isEmpty) {
      return null;
    }

    final row = payload.first as Map<String, dynamic>;
    return ProfileData(
      userId: row['user_id'] as String,
      nickname: row['nickname'] as String?,
      avatarPath: row['avatar_url'] as String?, // DB 컬럼명은 avatar_url이지만 값은 path
      bio: row['bio'] as String?,
    );
  }

  String? _extractErrorCode(String body) {
    try {
      final payload = jsonDecode(body);
      if (payload is Map<String, dynamic>) {
        final message = payload['message'] as String?;
        if (message != null && message.contains('nickname_taken')) {
          return 'nickname_taken';
        }
        final code = payload['code'] as String?;
        if (code != null && code.contains('nickname_taken')) {
          return 'nickname_taken';
        }
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

/// 프로필 에러 타입
enum ProfileError {
  missingConfig,
  unauthorized,
  network,
  timeout,
  invalidPayload,
  serverRejected,
  nicknameTaken,
  nicknameForbidden,
  nicknameInvalidFormat,
  imageTooLarge,
  imageOptimizationFailed,
}

/// 프로필 예외
class ProfileException implements Exception {
  const ProfileException(this.error);

  final ProfileError error;
}
