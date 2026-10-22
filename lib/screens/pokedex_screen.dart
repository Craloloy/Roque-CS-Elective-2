import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/pokedex_controller.dart';
import '../state/pokedex_state.dart';
import '../widgets/favorites_panel.dart';
import 'pokemon_detail_screen.dart';
import '../widgets/pokemon_card.dart';
import '../widgets/pokedex_frame.dart';
import '../widgets/pokemon_type_filters.dart';

class PokedexScreen extends ConsumerStatefulWidget {
  const PokedexScreen({super.key});

  @override
  ConsumerState<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends ConsumerState<PokedexScreen> {
  // Only view mechanics live here; all displayed data lives in Provider.
  final ScrollController _gridController = ScrollController();
  final GlobalKey<NavigatorState> _displayNavigator =
      GlobalKey<NavigatorState>();
  final HeroController _heroController = HeroController();
  double _rowExtent = 0;

  @override
  void initState() {
    super.initState();
    // Defer the first state change until the widget tree is mounted.
    Future.microtask(() {
      if (mounted &&
          ref.read(pokedexProvider).status == PokemonStatus.initial) {
        ref.read(pokedexProvider.notifier).fetch();
      }
    });
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
  }

  void _navigate(int delta) {
    ref.read(pokedexProvider.notifier).navigate(delta);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _revealSelection();
    });
  }

  void _revealSelection() {
    if (!_gridController.hasClients || _rowExtent <= 0) return;
    final state = ref.read(pokedexProvider);
    final index = state.visiblePokemon.indexWhere(
      (p) => p.id == state.selectedPokemon?.id,
    );
    if (index < 0) return;
    final position = _gridController.position;
    final top = 16 + (index ~/ 2) * _rowExtent;
    final bottom = top + _rowExtent - 16;
    final target = top < position.pixels
        ? top - 16
        : bottom > position.pixels + position.viewportDimension
        ? bottom - position.viewportDimension + 16
        : position.pixels;
    _gridController.animateTo(
      target
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble(),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _openPokemon(int id) {
    ref.read(pokedexProvider.notifier).selectPokemon(id);
    _displayNavigator.currentState!.popUntil((route) => route.isFirst);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _displayNavigator.currentState!.push(
      PageRouteBuilder<void>(
        settings: RouteSettings(name: '/pokemon/$id'),
        transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 420),
        reverseTransitionDuration: Duration(
          milliseconds: reduceMotion ? 0 : 320,
        ),
        pageBuilder: (_, animation, secondaryAnimation) =>
            PokemonDetailScreen(pokemonId: id),
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final eased = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0.04),
                end: Offset.zero,
              ).animate(eased),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGrid(PokedexState state) {
    if (state.status == PokemonStatus.initial || state.isLoading) {
      return const Center(child: _PokeballLoader());
    }
    if (state.status == PokemonStatus.error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                state.errorMessage ?? 'Unable to load Pokémon.',
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: ref.read(pokedexProvider.notifier).fetch,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.pokemon.isEmpty) {
      return const Center(child: Text('No Pokémon found.'));
    }
    final pokemon = state.visiblePokemon;
    return Column(
      children: [
        PokemonTypeFilters(
          onTypeChanged: (type) {
            ref.read(pokedexProvider.notifier).filterByType(type);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _gridController.hasClients)
                _gridController.jumpTo(0);
            });
          },
        ),
        Expanded(
          child: pokemon.isEmpty
              ? const Center(child: Text('No Pokémon match this type.'))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    _rowExtent = ((constraints.maxWidth - 48) / 2) / 0.66 + 16;
                    return RefreshIndicator(
                      onRefresh: ref.read(pokedexProvider.notifier).fetch,
                      child: GridView.builder(
                        controller: _gridController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.66,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: pokemon.length,
                        itemBuilder: (context, index) => PokemonCard(
                          pokemon: pokemon[index],
                          selected:
                              state.selectedPokemon?.id == pokemon[index].id,
                          onTap: () => _openPokemon(pokemon[index].id),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pokedexProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF101419)
          : const Color(0xFFF1F2F5),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewport) => SingleChildScrollView(
            child: SizedBox(
              height: viewport.maxHeight < 600 ? 600 : viewport.maxHeight,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: PokedexFrame(
                      grid: Column(
                        children: [
                          FavoritesPanel(onOpenPokemon: _openPokemon),
                          Expanded(
                            child: ClipRect(
                              child: NavigatorPopHandler<void>(
                                onPopWithResult: (_) =>
                                    _displayNavigator.currentState!.pop(),
                                child: HeroControllerScope(
                                  controller: _heroController,
                                  child: Navigator(
                                    key: _displayNavigator,
                                    onGenerateRoute: (_) =>
                                        MaterialPageRoute<void>(
                                          settings: const RouteSettings(
                                            name: '/',
                                          ),
                                          builder: (_) => Consumer(
                                            builder: (context, ref, child) =>
                                                Material(
                                                  color:
                                                      Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? const Color(0xFF191E25)
                                                      : Colors.white,
                                                  child: _buildGrid(
                                                    ref.watch(pokedexProvider),
                                                  ),
                                                ),
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      selectedPokemon: state.selectedPokemon,
                      onToggleDark: () => ref
                          .read(pokedexProvider.notifier)
                          .setDarkMode(!isDark),
                      onRefresh: ref.read(pokedexProvider.notifier).fetch,
                      isLoading: state.isLoading,
                      onNavigate: _navigate,
                      navigationEnabled:
                          state.visiblePokemon.isNotEmpty && !state.isLoading,
                    ),
                  ),
                ),
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
        child: const SizedBox(
          width: 64,
          height: 64,
          child: CustomPaint(painter: _PokeballPainter()),
        ),
      ),
      const SizedBox(height: 12),
      const Text(
        'LOADING POKÉMON...',
        style: TextStyle(fontFamily: 'VT323', fontSize: 20),
      ),
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
    canvas.drawRect(
      Rect.fromLTRB(0, 0, size.width, center.dy),
      Paint()..color = const Color(0xFFFF363B),
    );
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      outline,
    );
    canvas.restore();
    canvas.drawCircle(center, radius, outline);
    canvas.drawCircle(center, radius * 0.25, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius * 0.25, outline);
  }

  @override
  bool shouldRepaint(covariant _PokeballPainter oldDelegate) => false;
}
