import 'package:flutter/material.dart';

String laptopCategoryLabel(String category) => switch (category) {
  'gaming' => 'Gaming',
  'creator' => 'Creator',
  'ultrabook' => 'Ultrabook',
  'student' => 'Student',
  _ => 'Office',
};

/// Generic catalog illustration. Real product photos can use HTTPS image URLs.
class LaptopArtwork extends StatelessWidget {
  const LaptopArtwork({super.key, required this.category});
  final String category;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${laptopCategoryLabel(category)} laptop illustration',
    image: true,
    child: CustomPaint(painter: _LaptopPainter(category)),
  );
}

class _LaptopPainter extends CustomPainter {
  const _LaptopPainter(this.category);
  final String category;

  @override
  void paint(Canvas canvas, Size size) {
    // A shared coordinate system keeps the illustration responsive in each card.
    final scale = (size.width / 240).clamp(0.0, size.height / 160).toDouble();
    canvas.save();
    canvas.translate((size.width - 240 * scale) / 2, (size.height - 160 * scale) / 2);
    canvas.scale(scale);
    final accent = switch (category) {
      'gaming' => const Color(0xFF8C66E8),
      'creator' => const Color(0xFFC58BD6),
      'ultrabook' => const Color(0xFF84C5CB),
      'student' => const Color(0xFFA69BE3),
      _ => const Color(0xFF91A9CE),
    };
    final dark = category == 'gaming';
    canvas.drawOval(const Rect.fromLTWH(20, 140, 200, 12), Paint()..color = const Color(0x1F493C6E));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(29, 10, 182, 119), const Radius.circular(8)),
      Paint()..color = dark ? const Color(0xFF292238) : const Color(0xFFB9B9C8));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 15, 172, 108), const Radius.circular(4)),
      Paint()..color = const Color(0xFF211B32));
    final screen = const Rect.fromLTWH(38, 20, 164, 98);
    canvas.save();
    canvas.clipRect(screen);
    canvas.drawRect(screen, Paint()..shader = LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomRight,
      colors: [accent, const Color(0xFF372250)],
    ).createShader(screen));
    canvas.drawCircle(const Offset(171, 41), 65, Paint()..color = const Color(0x30FFFFFF));
    canvas.drawCircle(const Offset(87, 111), 61, Paint()..color = const Color(0x246A41B0));
    if (dark) {
      final bolt = Path()..moveTo(143, 26)..lineTo(103, 73)..lineTo(128, 73)
        ..lineTo(102, 113)..lineTo(157, 59)..lineTo(130, 59)..close();
      canvas.drawPath(bolt, Paint()..color = const Color(0xDDECE5FF));
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(58, 41, 79, 53), const Radius.circular(5)),
        Paint()..color = const Color(0xBAFFFFFF));
      for (var row = 0; row < 3; row++) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(67, 52.0 + row * 11, row == 2 ? 34.0 : 59.0, 4), const Radius.circular(2)),
          Paint()..color = accent);
      }
    }
    canvas.restore();
    final base = Path()..moveTo(29, 128)..lineTo(211, 128)..lineTo(231, 143)
      ..quadraticBezierTo(232, 149, 222, 149)..lineTo(18, 149)
      ..quadraticBezierTo(8, 149, 9, 143)..close();
    canvas.drawPath(base, Paint()..color = dark ? const Color(0xFF3C344B) : const Color(0xFFCDCCD8));
    canvas.drawLine(const Offset(15, 143), const Offset(225, 143), Paint()..color = const Color(0xFF9690A5)..strokeWidth = 1);
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 13; col++) {
        canvas.drawRect(Rect.fromLTWH(43.0 + col * 12, 130.0 + row * 3, 9, 1.5),
          Paint()..color = dark ? accent : const Color(0xFF8D879B));
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(101, 141, 38, 4), const Radius.circular(2)),
      Paint()..color = const Color(0xFFABA6BA));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LaptopPainter oldDelegate) => oldDelegate.category != category;
}
