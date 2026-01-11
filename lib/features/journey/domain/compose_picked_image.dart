/// 메시지 작성에서 선택된 이미지 모델
///
/// XFile.path 대신 안전한 임시 파일 경로를 사용합니다.
class ComposePickedImage {
  const ComposePickedImage({
    required this.id,
    required this.localPath,
    required this.mimeType,
    required this.byteSize,
    this.width,
    this.height,
  });

  /// 고유 ID (UUID)
  final String id;

  /// 안전한 임시 파일 경로 (getTemporaryDirectory 하위)
  final String localPath;

  /// MIME 타입 (예: image/jpeg, image/png)
  final String mimeType;

  /// 파일 크기 (바이트)
  final int byteSize;

  /// 이미지 너비 (픽셀, 선택적)
  final int? width;

  /// 이미지 높이 (픽셀, 선택적)
  final int? height;
}
