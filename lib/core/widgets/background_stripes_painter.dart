import 'package:flutter/material.dart';

// Background Stripes Custom Painter (Adds beautiful premium parallel diagonal gradient stripes with shadows)
class BackgroundStripesPainter extends CustomPainter {
  final bool isDark;
  BackgroundStripesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final double rectWidth = size.width * 0.12; // Responsive stripe width
    final double spacing = size.width * 0.04;   // Responsive spacing
    const double angle = -0.55;                 // Rotation angle (approx. 30 degrees)

    final paint = Paint()..style = PaintingStyle.fill;

    // Linear gradient matching the blue brand stripes
    final gradient = LinearGradient(
      colors: [
        const Color(0xFF64B5F6).withOpacity(isDark ? 0.25 : 0.10), // Light blue highlight
        const Color(0xFF00529B).withOpacity(isDark ? 0.35 : 0.15), // Deep corporate blue
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    // TOP RIGHT STRIPES group
    canvas.save();
    canvas.translate(size.width * 0.8, -100);
    canvas.rotate(angle);

    for (int i = 0; i < 3; i++) {
      final double xOffset = i * (rectWidth + spacing);
      final rect = Rect.fromLTWH(xOffset, 0, rectWidth, size.height * 0.8);
      
      paint.shader = gradient.createShader(rect);

      // Draw soft drop shadow for the stripe
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(const Offset(6, 6)), const Radius.circular(8)),
        Paint()
          ..color = Colors.black.withOpacity(isDark ? 0.12 : 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Draw the main gradient stripe
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
    canvas.restore();

    // BOTTOM LEFT STRIPES group
    canvas.save();
    canvas.translate(-size.width * 0.3, size.height * 0.6);
    canvas.rotate(angle);

    for (int i = 0; i < 3; i++) {
      final double xOffset = i * (rectWidth + spacing);
      final rect = Rect.fromLTWH(xOffset, 0, rectWidth, size.height * 0.8);
      
      paint.shader = gradient.createShader(rect);

      // Draw soft drop shadow
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.shift(const Offset(6, 6)), const Radius.circular(8)),
        Paint()
          ..color = Colors.black.withOpacity(isDark ? 0.12 : 0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Draw the main gradient stripe
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
