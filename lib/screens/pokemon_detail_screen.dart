import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokemon_provider.dart';

class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  // Route identity only. The page reads its actual content from Provider.
  final int pokemonId;

  @override
  Widget build(BuildContext context) {
    final pokemon = context.watch<PokemonProvider>().pokemonById(pokemonId);
    return Scaffold(
      appBar: AppBar(title: Text(pokemon?.name.toUpperCase() ?? 'POKÉMON')),
      body: pokemon == null
          ? const Center(child: Text('This Pokémon is no longer available.'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(children: [
                  Text('ID: #${pokemon.id.toString().padLeft(3, '0')}',
                    style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 24),
                  SizedBox(height: 240, width: double.infinity,
                    child: pokemon.imageUrl == null
                        ? const Icon(Icons.image_not_supported_outlined, size: 64)
                        : Image.network(pokemon.imageUrl!,
                            fit: BoxFit.contain,
                            semanticLabel: pokemon.name,
                            loadingBuilder: (context, child, progress) =>
                                progress == null ? child
                                    : const Center(child: CircularProgressIndicator()),
                            errorBuilder: (_, error, stackTrace) =>
                                const Icon(Icons.broken_image_outlined, size: 64))),
                  const SizedBox(height: 24),
                  Text(pokemon.name.toUpperCase(),
                    style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  Text(pokemon.types.join(' / ').toUpperCase(),
                    style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 12),
                  if (pokemon.heightCm != null)
                    Text('Height: ${pokemon.heightCm} cm',
                      style: const TextStyle(fontSize: 22)),
                  if (pokemon.weightKg != null)
                    Text('Weight: ${pokemon.weightKg!.toStringAsFixed(1)} kg',
                      style: const TextStyle(fontSize: 22)),
                ]),
              )),
            ),
    );
  }
}
