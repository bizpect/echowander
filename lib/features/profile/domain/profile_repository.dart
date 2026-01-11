import 'dart:typed_data';

/// 프로필 Repository 인터페이스
abstract class ProfileRepository {
  /// 닉네임 가용 여부 체크
  Future<bool> checkNicknameAvailable({
    required String nickname,
    required String accessToken,
  });

  /// 프로필 업데이트 (닉네임, 아바타 경로)
  /// null/빈값은 변경 없음으로 처리합니다.
  Future<ProfileData> updateProfile({
    String? nickname,
    String? avatarPath,
    required String accessToken,
  });

  /// 현재 사용자 프로필 조회
  Future<ProfileData?> getMyProfile({
    required String accessToken,
  });

  /// 아바타 이미지 업로드 (path 반환)
  Future<String> uploadAvatar({
    required Uint8List imageBytes,
    required String accessToken,
  });

  /// 아바타 signed URL 발급
  Future<String?> getAvatarSignedUrl({
    required String objectPath,
    required String accessToken,
    int expiresInSeconds = 3600,
  });
}

/// 프로필 데이터 모델
class ProfileData {
  const ProfileData({
    required this.userId,
    this.nickname,
    this.avatarPath,
    this.bio,
  });

  final String userId;
  final String? nickname;
  /// 아바타 경로 (예: {uid}/avatar.jpg)
  /// signed URL은 표시 시점에 별도로 발급
  final String? avatarPath;
  final String? bio;
}
