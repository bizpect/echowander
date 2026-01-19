import 'package:flutter/material.dart';

/// 카카오톡 스타일 말풍선 꼬리를 그리는 CustomPainter
///
/// - 왼쪽 꼬리: 상대방 메시지 (왼쪽 상단에 꼬리)
/// - 오른쪽 꼬리: 내 메시지 (오른쪽 상단에 꼬리)
class ChatBubblePainter extends CustomPainter {
  ChatBubblePainter({
    required this.color,
    required this.isMe,
    required this.radius,
  });

  final Color color;
  final bool isMe;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 말풍선 배경
    canvas.drawRRect(rrect, paint);

    // 꼬리 그리기 (삼각형)
    final tailPath = Path();
    const tailWidth = 8.0;
    const tailHeight = 8.0;

    if (isMe) {
      // 오른쪽 꼬리 (오른쪽 상단 모서리 바깥쪽으로)
      final tailStartX = size.width;
      final tailStartY = 10.0;
      tailPath.moveTo(tailStartX, tailStartY);
      tailPath.lineTo(tailStartX + tailWidth, tailStartY - tailHeight / 2);
      tailPath.lineTo(tailStartX, tailStartY + tailHeight);
      tailPath.close();
    } else {
      // 왼쪽 꼬리 (왼쪽 상단 모서리 바깥쪽으로)
      const tailStartX = 0.0;
      const tailStartY = 10.0;
      tailPath.moveTo(tailStartX, tailStartY);
      tailPath.lineTo(tailStartX - tailWidth, tailStartY - tailHeight / 2);
      tailPath.lineTo(tailStartX, tailStartY + tailHeight);
      tailPath.close();
    }

    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(covariant ChatBubblePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isMe != isMe ||
        oldDelegate.radius != radius;
  }
}
