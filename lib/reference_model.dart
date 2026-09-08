import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'store.dart';

/// Product-material colors, independent from the application's UI theme.
abstract final class ModelMaterial {
  static const navy = Color(0xFF191E3B);
  static const blue = Color(0xFF253A82);
  static const gold = Color(0xFFDBBA65);
  static const goldLight = Color(0xFFF4DE9C);
  static const silver = Color(0xFFC4CCD1);
  static const white = Color(0xFFF7F6F2);
  static const seam = Color(0xFFD8DCE1);
}

class _V {
  final double x, y, z;
  const _V(this.x, this.y, this.z);
  _V operator +(_V b) => _V(x + b.x, y + b.y, z + b.z);
  _V operator -(_V b) => _V(x - b.x, y - b.y, z - b.z);
  _V operator *(double s) => _V(x * s, y * s, z * s);
  _V cross(_V b) => _V(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  double get length => math.sqrt(x * x + y * y + z * z);
  _V get unit => this * (1 / (length == 0 ? 1 : length));
}

class _Face {
  final List<_V> points;
  final Color color;
  _Face(this.points, this.color);
}

/// Real extruded/tubular geometry, reconstructed from the supplied photographs.
/// All visible surfaces use clean geometry and vector artwork; no photo textures.
/// Unseen dimensions are approximations; this is not a photogrammetric scan.
class MeshPainter extends CustomPainter {
  final Product p;
  final double angle, tilt, zoom;
  final ui.Image? seal;
  MeshPainter(this.p, this.angle, this.tilt, this.zoom, {this.seal});
  _V _rotate(_V v) {
    final x = v.x * math.cos(angle) + v.z * math.sin(angle);
    final z = -v.x * math.sin(angle) + v.z * math.cos(angle);
    return _V(
      x,
      v.y * math.cos(tilt) - z * math.sin(tilt),
      v.y * math.sin(tilt) + z * math.cos(tilt),
    );
  }

  List<Offset> _rect(double x, double y, double w, double h) => [
    Offset(x, y),
    Offset(x + w, y),
    Offset(x + w, y + h),
    Offset(x, y + h),
  ];
  List<Offset> _circle(double x, double y, double r, {int count = 48}) =>
      List.generate(
        count,
        (i) => Offset(
          x + math.cos(i * math.pi * 2 / count) * r,
          y + math.sin(i * math.pi * 2 / count) * r,
        ),
      );
  List<Offset> _rounded(double x, double y, double w, double h, double r) {
    final result = <Offset>[];
    for (var corner = 0; corner < 4; corner++) {
      final cx = corner == 0 || corner == 3 ? x + w - r : x + r;
      final cy = corner < 2 ? y + h - r : y + r;
      for (var i = 0; i <= 8; i++) {
        final a = (corner * 90 + i * 90 / 8) * math.pi / 180;
        result.add(Offset(cx + math.cos(a) * r, cy + math.sin(a) * r));
      }
    }
    return result;
  }

  void _extrude(
    List<_Face> out,
    List<Offset> poly,
    double depth,
    Color color, {
    double z = 0,
    bool rounded = false,
  }) {
    final f = poly.map((v) => _V(v.dx, v.dy, z + depth / 2)).toList();
    final b = poly.map((v) => _V(v.dx, v.dy, z - depth / 2)).toList();
    if (!rounded) {
      out.addAll([_Face(f, color), _Face(b.reversed.toList(), color)]);
    } else {
      const center = Offset(0, -.52);
      for (final sign in [-1.0, 1.0]) {
        for (var ring = 0; ring < 4; ring++) {
          final r0 = 1 - ring / 4, r1 = 1 - (ring + 1) / 4;
          _V vertex(Offset v, double r) => _V(
            center.dx + (v.dx - center.dx) * r,
            center.dy + (v.dy - center.dy) * r,
            z + sign * (depth / 2 + .07 * (1 - r * r)),
          );
          for (var i = 0; i < poly.length; i++) {
            final n = (i + 1) % poly.length;
            out.add(
              _Face([
                vertex(poly[i], r0),
                vertex(poly[n], r0),
                vertex(poly[n], r1),
                vertex(poly[i], r1),
              ], color),
            );
          }
        }
      }
    }
    for (var i = 0; i < poly.length; i++) {
      final n = (i + 1) % poly.length;
      out.add(_Face([f[i], b[i], b[n], f[n]], color));
    }
  }

  void _tube(
    List<_Face> out,
    List<_V> points,
    double radius,
    Color color, {
    int sides = 8,
    double taper = 1,
    bool capEnd = false,
  }) {
    for (var j = 0; j < points.length - 1; j++) {
      final axis = (points[j + 1] - points[j]).unit;
      final ref = axis.y.abs() < .9 ? const _V(0, 1, 0) : const _V(1, 0, 0);
      final a = axis.cross(ref).unit, b = axis.cross(a).unit;
      final r0 = radius * (1 - (1 - taper) * j / (points.length - 1)),
          r1 = radius * (1 - (1 - taper) * (j + 1) / (points.length - 1));
      for (var k = 0; k < sides; k++) {
        final t = k * math.pi * 2 / sides, u = (k + 1) * math.pi * 2 / sides;
        final n0 = a * math.cos(t) + b * math.sin(t),
            n1 = a * math.cos(u) + b * math.sin(u);
        out.add(
          _Face([
            points[j] + n0 * r0,
            points[j] + n1 * r0,
            points[j + 1] + n1 * r1,
            points[j + 1] + n0 * r1,
          ], color),
        );
      }
    }
    if (capEnd && points.length >= 2) {
      final last = points.last;
      final axis = (points.last - points[points.length - 2]).unit;
      final ref = axis.y.abs() < .9 ? const _V(0, 1, 0) : const _V(1, 0, 0);
      final a = axis.cross(ref).unit, b = axis.cross(a).unit;
      final rLast = radius * taper;
      final cap = List.generate(sides, (k) {
        final t = k * math.pi * 2 / sides;
        return last + (a * math.cos(t) + b * math.sin(t)) * rLast;
      });
      out.add(_Face(cap, color));
    }
  }

  // Adjacent sections share their exact edge vertices, including depth.
  // This keeps the curved neck and both tails welded during a full rotation.
  void _band(
    List<_Face> out,
    List<List<_V>> sections,
    double thickness,
    Color color,
  ) {
    final dz = _V(0, 0, thickness / 2);
    for (var i = 0; i < sections.length - 1; i++) {
      final a = sections[i][0], b = sections[i][1];
      final c = sections[i + 1][0], d = sections[i + 1][1];
      out.addAll([
        _Face([a + dz, c + dz, d + dz, b + dz], color),
        _Face([b - dz, d - dz, c - dz, a - dz], color),
        _Face([a - dz, c - dz, c + dz, a + dz], color),
        _Face([b + dz, d + dz, d - dz, b - dz], color),
      ]);
    }
    for (final edge in [sections.first, sections.last]) {
      out.add(
        _Face([edge[0] - dz, edge[1] - dz, edge[1] + dz, edge[0] + dz], color),
      );
    }
  }

  void _neckBand(List<_Face> out, {required bool ribbon}) {
    final outer = ribbon ? .53 : .44;
    final inner = ribbon ? .36 : .29;
    final y = ribbon ? -.69 : -.91;
    final rise = ribbon ? .27 : .23;
    final leftZ = ribbon ? .025 : .02;
    final rightZ = ribbon ? .055 : .035;
    final sections = <List<_V>>[
      if (ribbon)
        [const _V(.31, 1.02, .025), const _V(.49, .95, .025)]
      else
        [const _V(-.075, .67, .02), const _V(.075, .63, .02)],
      ...List.generate(49, (i) {
        final t = i / 48;
        final a = math.pi + t * math.pi;
        final z = leftZ * (1 - t) + rightZ * t - .08 * math.sin(t * math.pi);
        return [
          _V(outer * math.cos(a), y + rise * math.sin(a), z),
          _V(inner * math.cos(a), y + .05 + rise * math.sin(a), z),
        ];
      }),
      if (ribbon)
        [const _V(-.31, 1.02, .055), const _V(-.49, .95, .055)]
      else
        [const _V(.075, .67, .035), const _V(-.075, .63, .035)],
    ];
    _band(
      out,
      sections,
      ribbon ? .018 : .025,
      ribbon ? ModelMaterial.blue : ModelMaterial.navy,
    );
  }

  void _clasp(
    List<_Face> out, {
    double y = 0,
    double scale = 1,
    double z = -.13,
  }) {
    _extrude(
      out,
      _circle(0, y, .21 * scale),
      .09 * scale,
      ModelMaterial.gold,
      z: z,
    );
    for (final s in [-1.0, 1.0]) {
      _extrude(
        out,
        [
          Offset(s * .015 * scale, y - .13 * scale),
          Offset(s * .16 * scale, y - .1 * scale),
          Offset(s * .12 * scale, y + .1 * scale),
          Offset(s * .03 * scale, y + .15 * scale),
        ],
        .085 * scale,
        ModelMaterial.goldLight,
        z: z - .07 * scale,
      );
    }
    _tube(
      out,
      [_V(-.1 * scale, y, z - .12 * scale), _V(.1 * scale, y, z - .12 * scale)],
      .035 * scale,
      ModelMaterial.gold,
    );
  }

  void _garment(List<_Face> out, bool polo) {
    // White, gently tapered torso; fitted on an invisible mannequin.
    _extrude(
      out,
      [
        const Offset(-.25, -1.08),
        Offset(-.48, -.98),
        Offset(-.65, -.61),
        Offset(-.43, -.52),
        Offset(-.32, -.72),
        Offset(-.33, -.06),
        Offset(-.2, .0),
        Offset(.2, .0),
        Offset(.33, -.06),
        Offset(.32, -.72),
        Offset(.43, -.52),
        Offset(.65, -.61),
        Offset(.48, -.98),
        Offset(.25, -1.08),
        ...List.generate(19, (i) {
          final a = i * math.pi / 18;
          return Offset(.19 * math.cos(a), -1.06 + .085 * math.sin(a));
        }),
      ],
      .23,
      ModelMaterial.white,
      rounded: true,
    );
    // Trousers: rounded tubular legs and a waistband, instead of the former shorts.
    _extrude(
      out,
      _rounded(-.30, .035, .60, .23, .025),
      .20,
      ModelMaterial.navy,
    );
    for (final s in [-1.0, 1.0]) {
      final leg = List.generate(
        12,
        (i) => _V(s * (.15 + i * .006), .14 + i * .095, 0),
      );
      _tube(out, leg, .148, ModelMaterial.navy, sides: 14, taper: .70, capEnd: true);
    }
    if (polo) {
      _extrude(
        out,
        const [
          Offset(-.18, -1.07),
          Offset(-.03, -.99),
          Offset(-.075, -.86),
          Offset(-.21, -.99),
        ],
        .035,
        ModelMaterial.blue,
        z: .135,
      );
      _extrude(
        out,
        const [
          Offset(.18, -1.07),
          Offset(.03, -.99),
          Offset(.075, -.86),
          Offset(.21, -.99),
        ],
        .035,
        ModelMaterial.blue,
        z: .135,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final garment =
        p.kind == 'pe_round' || p.kind == 'pe_polo' || p.kind == 'shirt';
    final scale =
        math.min(size.width * .36, size.height * (garment ? .285 : .35)) * zoom;
    final center = Offset(
      size.width / 2,
      size.height / 2 + (garment ? -14.0 : 4.0),
    );
    Offset project(_V v) {
      final f = 5 / (5 - v.z);
      return Offset(center.dx + v.x * scale * f, center.dy + v.y * scale * f);
    }

    final shadow = Paint()
      ..color = const Color(0xFF142534).withValues(alpha: .14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          center.dx,
          center.dy +
              scale *
                  (garment
                      ? 1.25
                      : p.kind == 'sling'
                      ? 1.35
                      : p.kind == 'case'
                      ? .65
                      : p.kind == 'pin'
                      ? .83
                      : 1.08),
        ),
        width: scale * 1.4,
        height: 12,
      ),
      shadow,
    );
    final faces = <_Face>[];
    switch (p.kind) {
      case 'pin':
        final edge = List.generate(160, (i) {
          final a = i * math.pi * 2 / 160;
          final r = .74 + .025 * math.cos(a * 16);
          return Offset(math.cos(a) * r, math.sin(a) * r);
        });
        _extrude(faces, edge, .095, ModelMaterial.gold);
        _extrude(
          faces,
          _circle(0, 0, .697),
          .012,
          ModelMaterial.goldLight,
          z: .053,
        );
        _extrude(faces, _circle(0, 0, .654), .009, ModelMaterial.navy, z: .066);
        _extrude(faces, _circle(0, 0, .475), .008, ModelMaterial.gold, z: .075);
        _clasp(faces, z: -.10);
      case 'sling':
        _neckBand(faces, ribbon: false);
        _extrude(
          faces,
          _rounded(-.115, .60, .23, .22, .03),
          .10,
          const Color(0xFF212A2E),
        );
        _extrude(faces, _rect(-.067, .79, .134, .29), .022, ModelMaterial.navy);
        _tube(
          faces,
          List.generate(25, (i) {
            final a = i * math.pi * 2 / 24;
            return _V(math.cos(a) * .065, 1.12 + math.sin(a) * .065, .01);
          }),
          .013,
          ModelMaterial.silver,
        );
        _tube(
          faces,
          const [
            _V(0, 1.18, 0),
            _V(.065, 1.23, 0),
            _V(.052, 1.30, 0),
            _V(-.04, 1.29, 0),
            _V(-.05, 1.23, 0),
          ],
          .023,
          ModelMaterial.silver,
        );
      case 'case':
        _extrude(
          faces,
          _rounded(-.82, -.57, 1.64, 1.14, .06),
          .055,
          const Color(0xFFDCE5E8).withValues(alpha: .72),
        );
        for (final side in [-1.0, 1.0]) {
          _tube(
            faces,
            [_V(side * .79, -.51, .035), _V(side * .79, .52, .035)],
            .016,
            ModelMaterial.silver,
          );
          _tube(
            faces,
            [_V(-.76, side * .54, .035), _V(.76, side * .54, .035)],
            .016,
            ModelMaterial.silver,
          );
        }
        _extrude(
          faces,
          _rounded(-.15, -.63, .30, .065, .028),
          .035,
          ModelMaterial.silver,
        );
        for (final point in const [
          Offset(-.59, -.4),
          Offset(.59, -.4),
          Offset(-.59, .38),
          Offset(.59, .38),
          Offset(0, -.4),
        ]) {
          _extrude(
            faces,
            _circle(point.dx, point.dy, .027, count: 12),
            .025,
            ModelMaterial.silver,
            z: .042,
          );
        }
      case 'caduceus':
        _tube(
          faces,
          const [_V(0, -.71, 0), _V(0, .91, 0)],
          .042,
          ModelMaterial.gold,
          taper: .55,
          sides: 12,
        );
        _extrude(faces, _circle(0, -.76, .095), .10, ModelMaterial.gold);
        for (final s in [-1.0, 1.0]) {
          _extrude(
            faces,
            [
              Offset(s * .04, -.50),
              Offset(s * .14, -.66),
              Offset(s * .25, -.61),
              Offset(s * .38, -.58),
              Offset(s * .82, -.72),
              Offset(s * .70, -.49),
              Offset(s * .54, -.36),
              Offset(s * .32, -.29),
              Offset(s * .13, -.34),
            ],
            .045,
            ModelMaterial.gold,
            z: .015,
          );
          for (var i = 0; i < 8; i++) {
            final tipX = s * (.31 + i * .07), tipY = -.42 - i * .032;
            _extrude(
              faces,
              [
                Offset(s * (.055 + i * .037), -.31 - i * .018),
                Offset(tipX, tipY - .05),
                Offset(tipX + s * .045, tipY - .075),
                Offset(s * (.085 + i * .037), -.28 - i * .018),
              ],
              .035,
              ModelMaterial.gold,
              z: .006 * i,
            );
            _tube(
              faces,
              [
                _V(s * (.07 + i * .037), -.3 - i * .018, .06),
                _V(tipX, tipY - .055, .075),
              ],
              .009,
              ModelMaterial.goldLight,
            );
          }
          final snake = List.generate(65, (i) {
            final t = i / 64;
            return _V(
              s * math.sin(t * math.pi * 5) * (.22 - .16 * t),
              -.25 + t * 1.0,
              .058 + math.cos(t * math.pi * 5) * .057,
            );
          });
          _tube(
            faces,
            snake,
            .026,
            ModelMaterial.goldLight,
            sides: 8,
            taper: .55,
          );
        }
        _clasp(faces, y: -.12, scale: .65, z: -.14);
      case 'pe_round':
      case 'pe_polo':
      case 'shirt':
        _garment(faces, p.kind == 'pe_polo');
      case 'ribbon':
        _neckBand(faces, ribbon: true);
      default:
        _extrude(
          faces,
          const [
            Offset(-.2, -.6),
            Offset(-.5, .8),
            Offset(-.2, .64),
            Offset(0, .9),
            Offset(.3, -.3),
          ],
          .04,
          ModelMaterial.navy,
        );
        _extrude(faces, _circle(0, -.4, .30), .065, ModelMaterial.navy, z: .05);
    }
    final transformed =
        faces
            .map((f) => _Face(f.points.map(_rotate).toList(), f.color))
            .toList()
          ..sort(
            (a, b) => (a.points.fold(0.0, (s, p) => s + p.z) / a.points.length)
                .compareTo(
                  b.points.fold(0.0, (s, p) => s + p.z) / b.points.length,
                ),
          );
    for (final face in transformed) {
      final n = (face.points[1] - face.points[0])
          .cross(face.points[2] - face.points[0])
          .unit;
      final light = (.63 + .37 * (n.x * -.35 + n.y * -.4 + n.z * .84).abs())
          .clamp(.4, 1.0);
      final c = face.color;
      final isNavyGarment = garment && c == ModelMaterial.navy;
      final isWhiteGarment = garment && c.r > .8 && c.g > .8 && c.b > .8;
      final lit = isNavyGarment
          ? Color.from(
              alpha: 1.0,
              red: (.08 + .10 * light + .05 * n.z.abs()).clamp(0.0, 1.0),
              green: (.16 + .17 * light + .08 * n.z.abs()).clamp(0.0, 1.0),
              blue: (.28 + .28 * light + .14 * n.z.abs()).clamp(0.0, 1.0),
            )
          : Color.from(
              alpha: c.a,
              red: c.r * (isWhiteGarment ? .95 + .035 * n.z.abs() : light),
              green: c.g * (isWhiteGarment ? .95 + .035 * n.z.abs() : light),
              blue: c.b * (isWhiteGarment ? .95 + .035 * n.z.abs() : light),
            );
      final path = Path()..addPolygon(face.points.map(project).toList(), true);
      canvas.drawPath(path, Paint()..color = lit);
      if (c.a == 1) {
        canvas.drawPath(
          path,
          Paint()
            ..color = lit
            ..style = PaintingStyle.stroke
            ..strokeWidth = .4,
        );
      }
    }
    final front = math.cos(angle) > 0;
    // Decal projection follows the garment surface instead of screen coordinates.
    void decal(List<Offset> polygon, Color color, {double depth = .126}) {
      canvas.drawPath(
        Path()..addPolygon(
          polygon.map((v) => project(_rotate(_V(v.dx, v.dy, depth)))).toList(),
          true,
        ),
        Paint()..color = color,
      );
    }

    void surface(double x, double y, double z, VoidCallback draw) {
      final o = project(_rotate(_V(x, y, z)));
      final vx = (project(_rotate(_V(x + 1, y, z))) - o) / 100,
          vy = (project(_rotate(_V(x, y + 1, z))) - o) / 100;
      canvas.save();
      canvas.transform(
        Float64List.fromList([
          vx.dx,
          vx.dy,
          0,
          0,
          vy.dx,
          vy.dy,
          0,
          0,
          0,
          0,
          1,
          0,
          o.dx,
          o.dy,
          0,
          1,
        ]),
      );
      draw();
      canvas.restore();
    }

    void text(
      String value,
      double x,
      double y,
      double font,
      Color color, {
      double rotation = 0,
      double depth = .135,
    }) {
      surface(x, y, depth, () {
        canvas.rotate(rotation);
        final tp = TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: font,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      });
    }

    void crest(double x, double y, double radius, {double depth = .126}) {
      decal(_circle(x, y, radius), ModelMaterial.blue, depth: depth);
      decal(
        _circle(x, y, radius * .82),
        ModelMaterial.white,
        depth: depth + .001,
      );
      decal(
        _circle(x, y, radius * .59),
        ModelMaterial.gold,
        depth: depth + .002,
      );
      decal(
        [
          Offset(x - radius * .35, y - radius * .4),
          Offset(x + radius * .35, y - radius * .4),
          Offset(x + radius * .25, y + radius * .25),
          Offset(x, y + radius * .43),
          Offset(x - radius * .25, y + radius * .25),
        ],
        ModelMaterial.blue,
        depth: depth + .003,
      );
    }

    if (garment && front) {
      decal(const [
        Offset(-.65, -.61),
        Offset(-.43, -.52),
        Offset(-.418, -.55),
        Offset(-.636, -.646),
      ], ModelMaterial.blue);
      decal(const [
        Offset(.65, -.61),
        Offset(.43, -.52),
        Offset(.418, -.55),
        Offset(.636, -.646),
      ], ModelMaterial.blue);
      if (p.kind != 'pe_polo') {
        decal(const [
          Offset(-.21, -1.064),
          Offset(-.13, -.99),
          Offset(.13, -.99),
          Offset(.21, -1.064),
          Offset(.19, -1.042),
          Offset(.115, -1.013),
          Offset(-.115, -1.013),
          Offset(-.19, -1.042),
        ], ModelMaterial.blue);
        decal(const [
          Offset(-.24, -1.07),
          Offset(-.48, -.97),
          Offset(-.465, -.95),
          Offset(-.23, -1.05),
        ], ModelMaterial.blue);
        decal(const [
          Offset(.24, -1.07),
          Offset(.48, -.97),
          Offset(.465, -.95),
          Offset(.23, -1.05),
        ], ModelMaterial.blue);
      } else {
        decal(
          const [
            Offset(-.18, -1.07),
            Offset(-.03, -.99),
            Offset(-.075, -.86),
            Offset(-.21, -.99),
          ],
          ModelMaterial.blue,
          depth: .16,
        );
        decal(
          const [
            Offset(.18, -1.07),
            Offset(.03, -.99),
            Offset(.075, -.86),
            Offset(.21, -.99),
          ],
          ModelMaterial.blue,
          depth: .16,
        );
        decal(_rect(-.012, -.94, .024, .23), ModelMaterial.seam, depth: .14);
        for (var i = 0; i < 2; i++) {
          decal(
            _circle(0, -.86 + i * .07, .008),
            ModelMaterial.white,
            depth: .16,
          );
        }
      }
      crest(.185, -.80, .064);
      text('P.E.', .185, -.69, 4, ModelMaterial.blue);

      decal(_circle(.215, .325, .036), ModelMaterial.white, depth: .156);
      decal(_circle(.215, .325, .026), ModelMaterial.blue, depth: .157);
      decal(const [
        Offset(.203, .315),
        Offset(.227, .315),
        Offset(.223, .335),
        Offset(.215, .341),
        Offset(.207, .335),
      ], ModelMaterial.gold, depth: .158);

      for (var i = 0; i < 6; i++) {
        text(
          'ATENEO'[i],
          .215,
          .41 + i * .063,
          5.5,
          ModelMaterial.white,
          depth: .156,
        );
      }
      for (final s in [-1.0, 1.0]) {
        decal([
          Offset(s * .295, .15),
          Offset(s * .28, 1.15),
          Offset(s * .265, 1.15),
          Offset(s * .28, .15),
        ], ModelMaterial.blue.withValues(alpha: .7), depth: .148);
      }
      decal(_rect(-.28, -.034, .56, .008), ModelMaterial.seam);
      decal(const [
        Offset(-.25, -.53),
        Offset(-.27, -.13),
        Offset(-.255, -.12),
        Offset(-.237, -.49),
      ], ModelMaterial.seam.withValues(alpha: .4));
    }
    final back = math.cos(angle) < 0;
    if (garment && back) {
      decal(const [
        Offset(-.65, -.61),
        Offset(-.43, -.52),
        Offset(-.418, -.55),
        Offset(-.636, -.646),
      ], ModelMaterial.blue, depth: -.126);
      decal(const [
        Offset(.65, -.61),
        Offset(.43, -.52),
        Offset(.418, -.55),
        Offset(.636, -.646),
      ], ModelMaterial.blue, depth: -.126);
      decal(const [
        Offset(-.21, -1.064),
        Offset(-.13, -.99),
        Offset(.13, -.99),
        Offset(.21, -1.064),
        Offset(.19, -1.042),
        Offset(.115, -1.013),
        Offset(-.115, -1.013),
        Offset(-.19, -1.042),
      ], ModelMaterial.blue, depth: -.126);
    }
    if (p.kind == 'sling' && front) {
      text(
        'ATENEO DE DAVAO UNIVERSITY',
        -.205,
        -.2,
        4.7,
        ModelMaterial.white,
        rotation: 1.34,
        depth: .065,
      );
      text(
        'ATENEO DE DAVAO UNIVERSITY',
        .205,
        -.2,
        4.7,
        ModelMaterial.white,
        rotation: -1.34,
        depth: .065,
      );
      for (var i = 0; i < 42; i++) {
        final y = -.85 + i * .034;
        for (final s in [-1.0, 1.0]) {
          final x = s * (.355 - (y + .85) * .242);
          decal(
            _rect(x - .056, y, .112, .0025),
            ModelMaterial.silver.withValues(alpha: .12),
            depth: s < 0 ? .0335 : .0485,
          );
        }
      }
      crest(0, .94, .042, depth: .012);
    }
    if (p.kind == 'pin' && front) {
      if (seal != null) {
        surface(0, 0, .086, () {
          const bounds = Rect.fromLTWH(-65, -65, 130, 130);
          canvas.save();
          canvas.clipPath(Path()..addOval(bounds));
          canvas.drawImageRect(
            seal!,
            Rect.fromLTWH(
              0,
              0,
              seal!.width.toDouble(),
              seal!.height.toDouble(),
            ),
            bounds,
            Paint()..filterQuality = FilterQuality.high,
          );
          canvas.restore();
        });
      } else {
        crest(0, 0, .47, depth: .086);
      }
    }
    if (p.kind == 'case' && front) {
      decal(
        const [
          Offset(-.7, -.45),
          Offset(-.60, -.45),
          Offset(.67, .45),
          Offset(.55, .45),
        ],
        Colors.white.withValues(alpha: .35),
        depth: .05,
      );
      decal(
        const [
          Offset(-.35, -.46),
          Offset(-.31, -.46),
          Offset(.73, .37),
          Offset(.73, .42),
        ],
        Colors.white.withValues(alpha: .55),
        depth: .05,
      );
    }
    if (p.kind == 'ribbon' && front) {
      for (var i = 0; i < 48; i++) {
        final y = -.6 + i * .032;
        for (final s in [-1.0, 1.0]) {
          final x = s * (.405 - (y + .6) * .51);
          decal(
            _rect(x - .055, y, .11, .0025),
            ModelMaterial.silver.withValues(alpha: .22),
            depth: s < 0 ? .065 : .035,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MeshPainter old) =>
      old.seal != seal ||
      old.p != p ||
      old.angle != angle ||
      old.tilt != tilt ||
      old.zoom != zoom;
}
