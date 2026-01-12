import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/logging/log_sanitizer.dart';
import '../../../../core/media/image_url_probe.dart';
import '../../../../l10n/app_localizations.dart';

const _logPrefix = '[JourneyImagesSection]';

/// 받은 메시지 상세 화면용 이미지 섹션
/// - 1장: 화면 너비만큼 단일 이미지
/// - 2장 이상: peek 캐러셀 (좌우에 다음/이전 이미지가 살짝 보임)
class JourneyImagesSection extends StatelessWidget {
  const JourneyImagesSection({
    super.key,
    required this.imageUrls,
    required this.onImageTap,
    this.onImageLoadFailed,
    this.traceIdPrefix,
    this.journeyId,
  });

  final List<String> imageUrls;
  final ValueChanged<int> onImageTap;
  final ValueChanged<int>? onImageLoadFailed;
  final String? traceIdPrefix;
  final String? journeyId;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context)!;

    // 1장일 때: 단일 이미지
    if (imageUrls.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: AppRadius.medium,
          child: Semantics(
            label: '${l10n.inboxImagesLabel} 1',
            button: true,
            child: InkWell(
              onTap: () => onImageTap(0),
              child: Image.network(
                imageUrls[0],
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: '${l10n.inboxImagesLabel} 1',
                errorBuilder: (context, error, stackTrace) {
                  final traceId = _buildTraceId(0);
                  // retried는 상세 화면에서 관리하므로 여기서는 false로 설정
                  // 실제 retried 상태는 상세 화면의 _handleImageLoadFailed에서 로그로 출력됨
                  _logImageError(0, imageUrls[0], error, stackTrace, traceId, false);
                  _probeImageUrl(imageUrls[0], traceId);
                  onImageLoadFailed?.call(0);
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: AppColors.surfaceVariant,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.iconMuted,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    // 2장 이상: peek 캐러셀
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: SizedBox(
        height: 300,
        child: PageView.builder(
          itemCount: imageUrls.length,
          controller: PageController(viewportFraction: 0.9),
          padEnds: false,
          itemBuilder: (context, index) {
            return Padding(
              padding: EdgeInsets.only(
                right: index < imageUrls.length - 1 ? AppSpacing.md : 0,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.medium,
                child: Semantics(
                  label: '${l10n.inboxImagesLabel} ${index + 1}',
                  button: true,
                  child: InkWell(
                    onTap: () => onImageTap(index),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      semanticLabel: '${l10n.inboxImagesLabel} ${index + 1}',
                      errorBuilder: (context, error, stackTrace) {
                        final traceId = _buildTraceId(index);
                        // retried는 상세 화면에서 관리하므로 여기서는 false로 설정
                        // 실제 retried 상태는 상세 화면의 _handleImageLoadFailed에서 로그로 출력됨
                        _logImageError(index, imageUrls[index], error, stackTrace, traceId, false);
                        _probeImageUrl(imageUrls[index], traceId);
                        onImageLoadFailed?.call(index);
                        return Container(
                          width: double.infinity,
                          height: 300,
                          color: AppColors.surfaceVariant,
                          child: Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                              color: AppColors.iconMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// traceId 생성
  String _buildTraceId(int index) {
    if (traceIdPrefix != null) {
      return '$traceIdPrefix-$index';
    }
    return 'imgtrace-${journeyId ?? "unknown"}-$index-${DateTime.now().microsecondsSinceEpoch}';
  }

  /// 이미지 로딩 에러 로깅 (디버그 한정)
  void _logImageError(
    int index,
    String url,
    Object error,
    StackTrace? stackTrace,
    String traceId,
    bool retried,
  ) {
    if (!kDebugMode) {
      return;
    }

    final urlSanitized = LogSanitizer.sanitizeUrlForLog(url);
    final errorType = error.runtimeType.toString();
    final stackTop = stackTrace != null
        ? stackTrace.toString().split('\n').take(2).join(' | ')
        : 'N/A';

    debugPrint(
      '$_logPrefix [FAIL] trace=$traceId index=$index retried=$retried url=$urlSanitized errorType=$errorType error=$error',
    );
    if (stackTrace != null) {
      debugPrint('$_logPrefix [3] 스택 트레이스 (상위 2줄): $stackTop');
    }
  }

  /// 이미지 URL 프로브 실행 (NetworkGuard 경유)
  Future<void> _probeImageUrl(String url, String traceId) async {
    if (!kDebugMode) {
      return;
    }

    try {
      final probe = ImageUrlProbe(
        config: AppConfigStore.current,
        errorLogger: null, // 순환 의존성 방지
      );
      final result = await probe.probe(url, traceId);
      if (result != null) {
        debugPrint(
          '[ImageProbe] trace=$traceId status=${result.statusCode} method=${result.methodUsed} type=${result.contentType ?? "N/A"} len=${result.contentLength ?? "N/A"} cache=${result.cacheControl ?? "N/A"}',
        );
        if (result.requestId != null) {
          debugPrint('[ImageProbe] trace=$traceId requestId=${result.requestId}');
        }
      } else {
        debugPrint('[ImageProbe] trace=$traceId probe failed');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('$_logPrefix [3] probe 예외: traceId=$traceId, error=$e');
      }
    }
  }
}
