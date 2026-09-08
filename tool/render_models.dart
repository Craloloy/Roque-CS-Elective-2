// Run explicitly with: flutter test tool/render_models.dart
// Renders the app's actual geometry to static catalog assets; no photo files are edited.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ecommerce_app/reference_model.dart';
import 'package:flutter_ecommerce_app/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('export photo-guided merchandise meshes', (tester) async {
    tester.view.physicalSize = const Size(1300, 1100);
    tester.view.devicePixelRatio = 1;
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await font.load();
    Future<void> render(CustomPainter painter, String file, Size size) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: CustomPaint(painter: painter),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(file).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    final seal = await tester.runAsync(() async {
      final data = await rootBundle.load('assets/branding/addu-seal.jpg');
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    });
    for (final p in catalog.where((p) => p.active)) {
      await render(
        MeshPainter(p, p.id == 'pin' ? -.08 : -.16, -.035, 1, seal: seal),
        p.image,
        const Size(700, 700),
      );
      await render(
        MeshPainter(p, math.pi + .12, -.035, 1, seal: seal),
        p.backImage,
        const Size(700, 700),
      );
    }
    await render(
      _HeroModels(seal),
      'assets/products/hero-reference.png',
      const Size(1200, 900),
    );
    await render(
      _BandChecks(),
      '.dart_tool/band-checks.png',
      const Size(1200, 900),
    );
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _HeroModels extends CustomPainter {
  final ui.Image? seal;
  _HeroModels(this.seal);
  @override
  void paint(Canvas canvas, Size size) {
    void model(String id, Offset position, Size area, double angle) {
      canvas.save();
      canvas.translate(position.dx, position.dy);
      MeshPainter(
        catalog.firstWhere((p) => p.id == id),
        angle,
        -.04,
        1,
        seal: seal,
      ).paint(canvas, area);
      canvas.restore();
    }

    model('uniform', const Offset(120, -15), const Size(700, 900), -.15);
    model('sling', const Offset(655, 160), const Size(490, 730), .16);
    model('pin', const Offset(-5, 375), const Size(465, 465), -.13);
  }

  @override
  bool shouldRepaint(covariant _HeroModels oldDelegate) => false;
}

class _BandChecks extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF5F6F9), BlendMode.src);
    for (var row = 0; row < 2; row++) {
      final p = catalog.firstWhere(
        (p) => p.id == (row == 0 ? 'sling' : 'ribbon'),
      );
      for (var col = 0; col < 4; col++) {
        canvas.save();
        canvas.translate(col * 300.0, row * 450.0);
        MeshPainter(
          p,
          [0.0, 1.35, 1.75, 3.14][col],
          -.04,
          1,
        ).paint(canvas, const Size(300, 450));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BandChecks oldDelegate) => false;
}
