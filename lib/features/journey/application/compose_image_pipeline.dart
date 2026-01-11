import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../domain/compose_picked_image.dart';

const _logPrefix = '[ComposeImage]';
const _uuid = Uuid();

/// 메시지 작성 이미지 파이프라인
///
/// 이미지 선택 즉시 안전한 임시 폴더로 복사하고 최적화합니다.
class ComposeImagePipeline {
  /// 최대 변 길이 (픽셀)
  static const int maxDimension = 2048;

  /// JPEG 품질
  static const int jpegQuality = 85;

  /// 최대 이미지 개수
  static const int maxImageCount = 3;

  /// 선택된 이미지들을 준비합니다.
  ///
  /// 파이프라인:
  /// 1. 최대 개수 제한 적용
  /// 2. 각 XFile을 readAsBytes()로 읽기
  /// 3. 임시 폴더에 복사
  /// 4. 최적화 (리사이즈/압축)
  /// 5. 검증 및 모델 반환
  static Future<List<ComposePickedImage>> preparePickedImages(
    List<XFile> picked, {
    required int maxCount,
  }) async {
    if (kDebugMode) {
      debugPrint('$_logPrefix prepare 시작 (${picked.length}장, 최대 $maxCount장)');
    }

    // 최대 개수 제한
    final limited = picked.take(maxCount).toList();
    if (picked.length > maxCount) {
      if (kDebugMode) {
        debugPrint(
          '$_logPrefix 이미지 개수 제한: ${picked.length}장 → $maxCount장',
        );
      }
    }

    // 임시 폴더 생성
    final tempDir = await _getComposeUploadsDirectory();
    final sessionId = _uuid.v4();
    final sessionDir = Directory('${tempDir.path}/$sessionId');
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }

    final results = <ComposePickedImage>[];

    for (var i = 0; i < limited.length; i += 1) {
      final xFile = limited[i];
      try {
        if (kDebugMode) {
          debugPrint('$_logPrefix 처리 중: ${xFile.path}');
        }

        // 1. readAsBytes()로 안전하게 읽기
        final originalBytes = await xFile.readAsBytes();
        if (originalBytes.isEmpty) {
          if (kDebugMode) {
            debugPrint('$_logPrefix 빈 파일: ${xFile.path}');
          }
          continue;
        }

        // 2. 최적화
        final optimized = await _optimizeImage(originalBytes);

        // 3. 임시 파일로 저장
        final imageId = _uuid.v4();
        final extension = _getExtensionFromMime(optimized.mimeType);
        final localPath = '${sessionDir.path}/img_$imageId.$extension';
        final file = File(localPath);
        await file.writeAsBytes(optimized.bytes);

        // 4. 검증
        if (!await file.exists()) {
          if (kDebugMode) {
            debugPrint('$_logPrefix 파일 생성 실패: $localPath');
          }
          continue;
        }
        final fileSize = await file.length();
        if (fileSize == 0) {
          if (kDebugMode) {
            debugPrint('$_logPrefix 파일 크기 0: $localPath');
          }
          await file.delete();
          continue;
        }

        // 5. 모델 생성
        final model = ComposePickedImage(
          id: imageId,
          localPath: localPath,
          mimeType: optimized.mimeType,
          byteSize: fileSize,
          width: optimized.width,
          height: optimized.height,
        );

        results.add(model);

        if (kDebugMode) {
          debugPrint(
            '$_logPrefix prepared ok id=$imageId path=$localPath '
            'size=${(fileSize / 1024).toStringAsFixed(1)}KB '
            'mime=${optimized.mimeType}',
          );
        }
      } on FileSystemException catch (e) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix prepared fail step=readBytes path=${xFile.path} '
            'osError=${e.osError?.errorCode} message=${e.osError?.message}',
          );
        }
        // 개별 실패는 건너뛰고 계속 진행
        continue;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint(
            '$_logPrefix prepared fail step=unknown path=${xFile.path} '
            'error=$e\n$stackTrace',
          );
        }
        continue;
      }
    }

    if (kDebugMode) {
      debugPrint('$_logPrefix prepare 완료: ${results.length}장 성공');
    }

    return results;
  }

  /// 업로드 직전 파일 검증
  static Future<void> validateBeforeUpload(String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw FileSystemException(
        '파일이 존재하지 않습니다',
        localPath,
      );
    }
    final size = await file.length();
    if (size == 0) {
      throw FileSystemException(
        '파일 크기가 0입니다',
        localPath,
      );
    }
    if (kDebugMode) {
      debugPrint(
        '$_logPrefix beforeUpload exists=true size=$size path=$localPath',
      );
    }
  }

  /// 세션 폴더 삭제 (임시 파일 정리)
  static Future<void> cleanupSession(String sessionId) async {
    try {
      final tempDir = await _getComposeUploadsDirectory();
      final sessionDir = Directory('${tempDir.path}/$sessionId');
      if (await sessionDir.exists()) {
        await sessionDir.delete(recursive: true);
        if (kDebugMode) {
          debugPrint('$_logPrefix cleanup 완료: $sessionId');
        }
      }
    } catch (e) {
      // 정리 실패해도 앱이 죽지 않게
      if (kDebugMode) {
        debugPrint('$_logPrefix cleanup 실패: $sessionId, error=$e');
      }
    }
  }

  /// 이미지 최적화
  static Future<_OptimizedImage> _optimizeImage(Uint8List inputBytes) async {
    try {
      // 1. 이미지 디코드
      img.Image? image = img.decodeImage(inputBytes);
      if (image == null) {
        throw const FormatException('이미지를 디코드할 수 없습니다');
      }

      // 2. EXIF 방향 보정
      image = img.bakeOrientation(image);

      // 3. 리사이즈 (최대 변 2048px)
      final originalWidth = image.width;
      final originalHeight = image.height;
      final hasAlpha = image.hasAlpha;

      if (originalWidth > maxDimension || originalHeight > maxDimension) {
        if (originalWidth > originalHeight) {
          image = img.copyResize(
            image,
            width: maxDimension,
            maintainAspect: true,
          );
        } else {
          image = img.copyResize(
            image,
            height: maxDimension,
            maintainAspect: true,
          );
        }
      }

      // 4. 인코딩 (PNG 투명 유지, 그 외는 JPEG)
      Uint8List outputBytes;
      String mimeType;
      String extension;

      if (hasAlpha) {
        // 투명 알파가 있으면 PNG 유지
        outputBytes = Uint8List.fromList(img.encodePng(image));
        mimeType = 'image/png';
        extension = 'png';
      } else {
        // JPEG로 변환
        outputBytes = Uint8List.fromList(
          img.encodeJpg(image, quality: jpegQuality),
        );
        mimeType = 'image/jpeg';
        extension = 'jpg';
      }

      if (outputBytes.isEmpty) {
        throw const FormatException('압축 결과가 비어있습니다');
      }

      return _OptimizedImage(
        bytes: outputBytes,
        mimeType: mimeType,
        extension: extension,
        width: image.width,
        height: image.height,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix 최적화 실패: $e');
      }
      rethrow;
    }
  }

  /// compose_uploads 디렉토리 가져오기
  static Future<Directory> _getComposeUploadsDirectory() async {
    final tempDir = await getTemporaryDirectory();
    final uploadsDir = Directory('${tempDir.path}/compose_uploads');
    if (!await uploadsDir.exists()) {
      await uploadsDir.create(recursive: true);
    }
    return uploadsDir;
  }

  /// MIME 타입에서 확장자 추출
  static String _getExtensionFromMime(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/jpeg':
      case 'image/jpg':
        return 'jpg';
      case 'image/webp':
        return 'webp';
      case 'image/gif':
        return 'gif';
      default:
        return 'jpg';
    }
  }
}

/// 최적화된 이미지 결과
class _OptimizedImage {
  const _OptimizedImage({
    required this.bytes,
    required this.mimeType,
    required this.extension,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String mimeType;
  final String extension;
  final int width;
  final int height;
}
