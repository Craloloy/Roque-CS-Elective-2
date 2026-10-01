import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokedex_frame.dart';

class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key, required this.onThemeChanged});
  final ValueChanged<bool> onThemeChanged;

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonService _service = PokemonService();
  late Future<List<Pokemon>> _pokemonFuture;
  Pokemon? _selected;
  List<Pokemon> _pokemon = const [];
  final ScrollController _gridController = ScrollController();
  double _rowExtent = 0;

  @override
  void initState() {
    super.initState();
    _pokemonFuture = _loadList();
  }

  Future<List<Pokemon>> _loadList() async {
    final pokemon = await _service.fetchPokemon();
    if (mounted) setState(() { _pokemon = pokemon; });
    return pokemon;
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  void _navigate(int delta) {
    if (_pokemon.isEmpty) return;
    final current = _pokemon.indexWhere((p) => p.id == _selected?.id);
    if (current < 0) {
      _select(_pokemon.first);
      return;
    }
    if ((delta == -1 && current.isEven) || (delta == 1 && current.isOdd)) return;
    final next = current + delta;
    if (next >= 0 && next < _pokemon.length) _select(_pokemon[next]);
  }

  void _revealSelection() {
    if (!_gridController.hasClients || _rowExtent <= 0) return;
    final index = _pokemon.indexWhere((p) => p.id == _selected?.id);
    if (index < 0) return;
    final position = _gridController.position;
    final top = 16 + (index ~/ 2) * _rowExtent;
    final bottom = top + _rowExtent - 16;
    final target = top < position.pixels ? top - 16
        : bottom > position.pixels + position.viewportDimension
            ? bottom - position.viewportDimension + 16 : position.pixels;
    _gridController.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
    );
  }

  void _select(Pokemon pokemon) {
    setState(() { _selected = pokemon; });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealSelection();
    });
  }

  Widget _buildGrid() => FutureBuilder<List<Pokemon>>(
    future: _pokemonFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: _PokeballLoader());
      }
      if (snapshot.hasError) {
        return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Unable to load Pokémon.'),
          TextButton(
            onPressed: () => setState(() { _pokemonFuture = _loadList(); }),
            child: const Text('Retry'),
          ),
        ]));
      }
      final pokemon = snapshot.data ?? const <Pokemon>[];
      if (pokemon.isEmpty) return const Center(child: Text('No Pokémon found.'));
      return LayoutBuilder(builder: (context, constraints) {
        _rowExtent = ((constraints.maxWidth - 48) / 2) / 0.66 + 16;
        return GridView.builder(
          controller: _gridController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.66,
            crossAxisSpacing: 16, mainAxisSpacing: 16,
          ),
          itemCount: pokemon.length,
          itemBuilder: (context, index) => PokemonCard(
            pokemon: pokemon[index],
            selected: _selected?.id == pokemon[index].id,
            onTap: () => _select(pokemon[index]),
          ),
        );
      });
    },
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101419) : const Color(0xFFF1F2F5),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: PokedexFrame(
                grid: _buildGrid(),
                selectedPokemon: _selected,
                onToggleDark: () => widget.onThemeChanged(!isDark),
                onNavigate: _navigate,
                navigationEnabled: _pokemon.isNotEmpty,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PokeballLoader extends StatefulWidget {
  const _PokeballLoader();

  @override
  State<_PokeballLoader> createState() => _PokeballLoaderState();
}

class _PokeballLoaderState extends State<_PokeballLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RotationTransition(
        turns: _controller,
        child: const SizedBox(width: 64, height: 64,
          child: CustomPaint(painter: _PokeballPainter())),
      ),
      const SizedBox(height: 12),
      const Text('LOADING POKÉMON...',
        style: TextStyle(fontFamily: 'VT323', fontSize: 20)),
    ],
  );
}

class _PokeballPainter extends CustomPainter {
  const _PokeballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 3;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final outline = Paint()
      ..color = const Color(0xFF202020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, center.dy),
      Paint()..color = const Color(0xFFFF363B));
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), outline);
    canvas.restore();
    canvas.drawCircle(center, radius, outline);
    canvas.drawCircle(center, radius * 0.25, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.25, outline);
  }

  @override
  bool shouldRepaint(covariant _PokeballPainter oldDelegate) => false;
}
