import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const _logPrefix = '[ImageOptimizer]';

/// 아바타 이미지 최적화 결과
class AvatarImageResult {
  const AvatarImageResult({
    required this.bytes,
    required this.mimeType,
    required this.extension,
    required this.width,
    required this.height,
    required this.originalBytes,
    required this.optimizedBytes,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
  final int width;
  final int height;
  final int originalBytes;
  final int optimizedBytes;
}

/// 이미지 최적화 유틸
class ImageOptimizer {
  /// 최대 변 길이 (픽셀)
  static const int maxDimension = 1024;

  /// 최소 변 길이 (픽셀) - 너무 작은 이미지는 업스케일 금지
  static const int minDimension = 256;

  /// 기본 JPEG 품질
  static const int defaultQuality = 85;

  /// 최대 용량 (바이트)
  static const int maxBytes = 400 * 1024; // 400KB

  /// 최소 용량 (바이트) - 너무 작으면 재압축하지 않음
  static const int minBytes = 10 * 1024; // 10KB

  /// 품질 단계 (용량 초과 시 단계적으로 낮춤)
  static const List<int> qualitySteps = [85, 80, 75, 70];

  /// 최대 재시도 횟수 (용량 초과 시)
  static const int maxRetryAttempts = 4;

  /// 아바타 이미지 최적화
  /// 
  /// 파이프라인:
  /// 1. 이미지 디코드
  /// 2. EXIF 방향 보정
  /// 3. 리사이즈 (최대 변 길이 제한)
  /// 4. JPEG 압축 (품질 조정)
  /// 5. 용량 제한 확인 및 재압축
  static Future<AvatarImageResult> optimizeAvatar(
    Uint8List inputBytes,
  ) async {
    final originalBytes = inputBytes.length;

    try {
      // 1. 이미지 디코드
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) {
        throw const FormatException('이미지를 디코드할 수 없습니다');
      }

      // 2. EXIF 방향 보정 (자동 회전)
      image = img.bakeOrientation(image);

      // 3. 리사이즈 (최대 변 길이 제한)
      final originalWidth = image.width;
      final originalHeight = image.height;
      final maxSize = maxDimension;
      final minSize = minDimension;

      // 최소 크기 체크 (너무 작은 이미지는 업스케일 금지)
      if (originalWidth < minSize && originalHeight < minSize) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix 이미지가 너무 작음: $originalWidth'
            'x$originalHeight (최소: $minSize'
            'x$minSize)',
          );
        }
        // 최소 크기보다 작으면 그대로 사용 (업스케일하지 않음)
      } else if (originalWidth > maxSize || originalHeight > maxSize) {
        // 비율 유지하며 리사이즈
        if (originalWidth > originalHeight) {
          image = img.copyResize(
            image,
            width: maxSize,
            maintainAspect: true,
          );
        } else {
          image = img.copyResize(
            image,
            height: maxSize,
            maintainAspect: true,
          );
        }
      }

      // 정사각형으로 만들기 (원형 크롭이지만 저장은 정사각)
      final size = image.width > image.height ? image.width : image.height;
      if (image.width != size || image.height != size) {
        final square = img.Image(width: size, height: size);
        img.fill(square, color: img.ColorRgb8(255, 255, 255));
        final offsetX = (size - image.width) ~/ 2;
        final offsetY = (size - image.height) ~/ 2;
        img.compositeImage(
          square,
          image,
          dstX: offsetX,
          dstY: offsetY,
        );
        image = square;
      }

      // 4. JPEG 압축 (품질 조정)
      Uint8List? outputBytes;
      int quality = defaultQuality;
      int attempt = 0;

      while (attempt < qualitySteps.length && attempt < maxRetryAttempts) {
        quality = qualitySteps[attempt];
        outputBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: quality),
        );

        // 5. 용량 제한 확인
        if (outputBytes.length <= maxBytes) {
          break;
        }

        // 용량 초과 시 다음 품질 단계로 재압축
        attempt++;
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix 용량 초과 (${outputBytes.length} bytes), 품질 낮춤: $quality (시도 $attempt/$maxRetryAttempts)',
          );
        }
      }

      // 최종 용량 확인
      if (outputBytes == null || outputBytes.length > maxBytes) {
        throw ImageOptimizationException(
          ImageOptimizationError.fileTooLarge,
          message: '이미지 용량이 너무 큽니다',
        );
      }

      final optimizedBytes = outputBytes.length;

      if (kDebugMode) {
        debugPrint(
          '$_logPrefix 최적화 완료: $originalWidth'
          'x$originalHeight → ${image.width}x${image.height}, '
          '${(originalBytes / 1024).toStringAsFixed(1)}KB → ${(optimizedBytes / 1024).toStringAsFixed(1)}KB, '
          '품질: $quality',
        );
      }

      return AvatarImageResult(
        bytes: outputBytes,
        mimeType: 'image/jpeg',
        extension: 'jpg',
        width: image.width,
        height: image.height,
        originalBytes: originalBytes,
        optimizedBytes: optimizedBytes,
      );
    } catch (e) {
      if (e is ImageOptimizationException) {
        rethrow;
      }
      if (kDebugMode) {
        debugPrint('$_logPrefix 최적화 실패: $e');
      }
      throw ImageOptimizationException(
        ImageOptimizationError.unknown,
        message: '이미지 최적화 중 오류가 발생했습니다',
      );
    }
  }
}

/// 이미지 최적화 예외
class ImageOptimizationException implements Exception {
  const ImageOptimizationException(
    this.error, {
    this.message,
  });

  final ImageOptimizationError error;
  final String? message;

  @override
  String toString() => message ?? error.toString();
}

/// 이미지 최적화 에러 타입
enum ImageOptimizationError {
  fileTooLarge,
  invalidFormat,
  unknown,
}
