import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/pokedex_controller.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.pokemonId,
    this.compact = false,
  });
  final int pokemonId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorite = ref.watch(
      pokedexProvider.select((s) => s.isFavorite(pokemonId)),
    );
    return IconButton(
      key: ValueKey('favorite-$pokemonId'),
      tooltip: favorite ? 'Remove from favorites' : 'Add to favorites',
      isSelected: favorite,
      onPressed: () =>
          ref.read(pokedexProvider.notifier).toggleFavorite(pokemonId),
      constraints: BoxConstraints.tightFor(
        width: compact ? 36 : 44,
        height: compact ? 36 : 44,
      ),
      padding: EdgeInsets.zero,
      icon: Icon(
        favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: favorite ? const Color(0xFFE2476B) : null,
        size: compact ? 22 : 25,
      ),
    );
  }
}
