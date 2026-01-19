import 'package:flutter/material.dart';

/// 풀스크린 이미지 뷰어 (공통 위젯)
///
/// 사용법:
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     fullscreenDialog: true,
///     builder: (_) => FullscreenImageViewer(imageUrl: 'https://...'),
///   ),
/// );
/// ```
class FullscreenImageViewer extends StatelessWidget {
  const FullscreenImageViewer({
    super.key,
    required this.imageUrl,
    this.initialIndex = 0,
    this.imageUrls,
  });

  /// 단일 이미지 URL
  final String imageUrl;

  /// 초기 인덱스 (여러 이미지일 때)
  final int initialIndex;

  /// 여러 이미지 URL (PageView용, null이면 단일 이미지)
  final List<String>? imageUrls;

  @override
  Widget build(BuildContext context) {
    // 여러 이미지인 경우 PageView, 단일 이미지는 InteractiveViewer
    final hasMultipleImages =
        imageUrls != null && imageUrls!.length > 1;

    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.scrim,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: hasMultipleImages
          ? _buildPageView(context)
          : _buildSingleImage(context),
    );
  }

  /// 단일 이미지 (InteractiveViewer로 확대/축소 가능)
  Widget _buildSingleImage(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4.0,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            final colorScheme = Theme.of(context).colorScheme;
            return Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 64,
                color: colorScheme.onSurface,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 여러 이미지 (PageView로 스와이프 가능)
  Widget _buildPageView(BuildContext context) {
    return PageView.builder(
      controller: PageController(initialPage: initialIndex),
      itemCount: imageUrls!.length,
      itemBuilder: (context, index) {
        return Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.network(
              imageUrls![index],
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                final colorScheme = Theme.of(context).colorScheme;
                return Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 64,
                    color: colorScheme.onSurface,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
