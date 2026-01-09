import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// CRT Scanlines overlay widget for retro terminal effect
class ScanlinesOverlay extends StatelessWidget {
  const ScanlinesOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScanlinesPainter(),
      size: Size.infinite,
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 1;

    // Draw horizontal scanlines every 2 pixels
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Add subtle RGB color shift effect (very subtle)
    final rgbPaint = Paint()
      ..color = AppColors.neonGreen.withValues(alpha: 0.02)
      ..blendMode = BlendMode.overlay;
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      rgbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
