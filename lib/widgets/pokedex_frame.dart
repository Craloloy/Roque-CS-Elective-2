import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

const _ink = Color(0xFF202020);
const _displayStyle = TextStyle(
  fontFamily: 'VT323', fontWeight: FontWeight.w400,
  color: _ink, fontSize: 20, letterSpacing: 0.3,
);

class PokedexFrame extends StatelessWidget {
  const PokedexFrame({
    super.key, required this.grid, required this.selectedPokemon,
    required this.onToggleDark,
    required this.onRefresh, required this.isLoading,
    required this.onNavigate, required this.navigationEnabled,
  });
  final Widget grid;
  final Pokemon? selectedPokemon;
  final VoidCallback onToggleDark;
  final VoidCallback onRefresh;
  final bool isLoading;
  final ValueChanged<int> onNavigate;
  final bool navigationEnabled;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF9E2835) : const Color(0xFFFF363B),
        border: Border.all(color: _ink, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxHeight < 540;
        return Column(children: [
          SizedBox(
            height: compact ? 64 : 88,
            child: CustomPaint(
              painter: _HeaderPainter(isDark: isDark),
              child: Stack(children: [
                Align(
                  alignment: const Alignment(0.35, 0.05),
                  child: Text('POKÉDEX OF\nANOMALIES',
                    textAlign: TextAlign.center,
                    style: _displayStyle.copyWith(
                      color: isDark ? Colors.white : _ink, fontSize: 18)),
                ),
                Positioned(
                  right: 8, bottom: 0,
                  child: IconButton(
                    tooltip: 'Refresh Pokémon',
                    onPressed: isLoading ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 20),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.15 - 24,
                  top: (compact ? 64 : 88) * 0.43 - 24,
                  width: 48, height: 48,
                  child: IconButton(
                    tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
                    onPressed: onToggleDark,
                    style: IconButton.styleFrom(
                      foregroundColor: _ink, padding: EdgeInsets.zero),
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
                  ),
                ),
              ]),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF191E25) : Colors.white,
                border: Border.all(color: _ink, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF777777), offset: Offset(3, 3)),
                ],
              ),
              child: grid,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              decoration: BoxDecoration(
                color: const Color(0xFF34383D),
                border: Border.all(color: _ink, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9ACD3F),
                    border: Border.all(color: _ink, width: 2),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(children: [
                    Expanded(child: Text(
                      selectedPokemon?.name.toUpperCase() ?? 'SELECT A POKÉMON',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: _displayStyle.copyWith(fontSize: 19),
                    )),
                    const SizedBox(width: 8),
                    Text(selectedPokemon == null
                        ? '' : selectedPokemon!.types.isEmpty
                            ? 'POKÉMON'
                            : selectedPokemon!.types.join(' / ').toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: _displayStyle.copyWith(fontSize: 16)),
                  ]),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  SizedBox(width: 72, height: 72,
                    child: _NavigationPad(onNavigate: onNavigate,
                      enabled: navigationEnabled)),
                  const SizedBox(width: 10),
                  Expanded(child: Container(
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9ACD3F),
                      border: Border.all(color: _ink, width: 2),
                    ),
                    child: Text(selectedPokemon == null ? '' :
                      'ID: #${selectedPokemon!.id.toString().padLeft(3, '0')}',
                      style: _displayStyle.copyWith(fontSize: 20)),
                  )),
                ]),
              ]),
            ),
          ),
        ]);
      }),
    );
  }
}

class _HeaderPainter extends CustomPainter {
  const _HeaderPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()..color = _ink..style = PaintingStyle.stroke..strokeWidth = 3;
    final line = Path()
      ..moveTo(0, size.height - 5)
      ..lineTo(size.width * 0.25, size.height - 5)
      ..cubicTo(size.width * 0.46, size.height - 5,
        size.width * 0.39, 18, size.width * 0.6, 18)
      ..lineTo(size.width, 18);
    canvas.drawPath(line, stroke);
    final light = Offset(size.width * 0.15, size.height * 0.43);
    final radius = size.height * 0.29;
    canvas.drawCircle(light, radius + 4, Paint()..color = const Color(0xFFAE2528));
    canvas.drawCircle(light, radius + 4, stroke);
    canvas.drawCircle(light, radius, Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF9DFFFF), Color(0xFF00E4ED)],
        center: Alignment(-0.3, -0.3),
      ).createShader(Rect.fromCircle(center: light, radius: radius)));
    canvas.drawCircle(light, radius, stroke);
    final ball = Offset(size.width * 0.88, size.height * 0.55);
    final ballRadius = size.height * 0.22;
    final bounds = Rect.fromCircle(center: ball, radius: ballRadius);
    canvas.drawCircle(ball, ballRadius, Paint()..color = Colors.white);
    canvas.drawArc(bounds, math.pi, math.pi, true,
      Paint()..color = isDark ? const Color(0xFF9E2835) : const Color(0xFFFF363B));
    canvas.drawLine(Offset(ball.dx - ballRadius, ball.dy),
      Offset(ball.dx + ballRadius, ball.dy), stroke);
    canvas.drawCircle(ball, ballRadius, stroke);
    canvas.drawCircle(ball, ballRadius * 0.3, Paint()..color = Colors.white);
    canvas.drawCircle(ball, ballRadius * 0.3, stroke);
  }

  @override
  bool shouldRepaint(covariant _HeaderPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _NavigationPad extends StatelessWidget {
  const _NavigationPad({required this.onNavigate, required this.enabled});
  final ValueChanged<int> onNavigate;
  final bool enabled;

  Widget _key(IconData icon, String label, int delta) => Semantics(
    button: true, label: label, enabled: enabled,
    child: Material(
      color: const Color(0xFF393939),
      child: InkWell(
        onTap: enabled ? () => onNavigate(delta) : null,
        child: SizedBox(width: 24, height: 24,
          child: Icon(icon, size: 20, color: enabled ? Colors.white : Colors.grey)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(children: [
    _key(Icons.arrow_drop_up, 'Select Pokémon above', -2),
    Row(children: [
      _key(Icons.arrow_left, 'Select Pokémon to the left', -1),
      Container(width: 24, height: 24, color: const Color(0xFF393939)),
      _key(Icons.arrow_right, 'Select Pokémon to the right', 1),
    ]),
    _key(Icons.arrow_drop_down, 'Select Pokémon below', 2),
  ]);
}
