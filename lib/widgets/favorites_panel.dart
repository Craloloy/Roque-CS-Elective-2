import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/pokedex_controller.dart';
import 'favorite_button.dart';

/// Outside the inner Navigator, so the same panel is available on every page.
class FavoritesPanel extends ConsumerWidget {
  const FavoritesPanel({super.key, required this.onOpenPokemon});
  final ValueChanged<int> onOpenPokemon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pokedexProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final favorites = state.favorites;
    return Material(
      color: dark ? const Color(0xFF34232E) : const Color(0xFFFFEAF0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            key: const ValueKey('favorites-toggle'),
            onTap: () =>
                ref.read(pokedexProvider.notifier).toggleFavoritesPanel(),
            child: Semantics(
              button: true,
              label:
                  '${state.favoritesExpanded ? "Collapse" : "Expand"} favorites',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFE2476B),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'FAVORITES (${favorites.length})',
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                    Icon(
                      state.favoritesExpanded
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: Duration(
              milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220,
            ),
            alignment: Alignment.topCenter,
            child: !state.favoritesExpanded
                ? const SizedBox(width: double.infinity)
                : favorites.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'No favorites yet. Tap a heart to add a Pokémon.',
                      key: ValueKey('favorites-empty'),
                      textAlign: TextAlign.center,
                    ),
                  )
                : SizedBox(
                    height: 90,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: favorites.length,
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final pokemon = favorites[index];
                        final nickname = state.nicknameFor(pokemon.id);
                        return SizedBox(
                          width: 180,
                          child: Card(
                            margin: EdgeInsets.zero,
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('open-favorite-${pokemon.id}'),
                              onTap: () => onOpenPokemon(pokemon.id),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 34,
                                      height: 40,
                                      child: pokemon.imageUrl == null
                                          ? const Icon(Icons.catching_pokemon)
                                          : Image.network(
                                              pokemon.imageUrl!,
                                              errorBuilder: (_, error, trace) =>
                                                  const Icon(
                                                    Icons.catching_pokemon,
                                                  ),
                                            ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pokemon.name.toUpperCase(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (nickname != null)
                                            Text(
                                              nickname,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    FavoriteButton(
                                      pokemonId: pokemon.id,
                                      compact: true,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
