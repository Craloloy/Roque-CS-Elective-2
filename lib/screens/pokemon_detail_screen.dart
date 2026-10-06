import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokemon_provider.dart';

/// This route is hosted by the Navigator inside the Pokédex display.
class PokemonDetailScreen extends StatelessWidget {
  const PokemonDetailScreen({super.key, required this.pokemonId});

  final int pokemonId;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PokemonProvider>();
    // The D-pad can browse Pokémon while the detail display is open.
    final pokemon = state.selectedPokemon ?? state.pokemonById(pokemonId);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFF2CF) : const Color(0xFF302A1B);
    final paper = dark ? const Color(0xFF242E26) : const Color(0xFFFFF2CB);
    return Material(
      color: dark ? const Color(0xFF191E25) : const Color(0xFFF9F5E8),
      child: Column(children: [
        Container(
          decoration: BoxDecoration(
            color: paper,
            border: const Border(bottom: BorderSide(color: Color(0xFFAC8133), width: 2)),
          ),
          child: Row(children: [
            BackButton(color: ink),
            Expanded(child: Text('POKÉMON FILE',
              style: TextStyle(color: ink, fontSize: 20, letterSpacing: 1))),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.catching_pokemon, color: ink, size: 20)),
          ]),
        ),
        Expanded(child: pokemon == null
          ? const Center(child: Text('This Pokémon is no longer available.'))
          : AnimatedSwitcher(
              duration: Duration(milliseconds:
                MediaQuery.disableAnimationsOf(context) ? 0 : 240),
              child: SingleChildScrollView(
                key: ValueKey(pokemon.id),
                padding: const EdgeInsets.all(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFAC8133), width: 3),
                  ),
                  child: Column(children: [
                    Text('ID: #${pokemon.id.toString().padLeft(3, '0')}',
                      style: TextStyle(color: ink, fontSize: 22, letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity, height: 210,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFAB8946), width: 2),
                        gradient: RadialGradient(colors: dark
                            ? [const Color(0xFF507549), const Color(0xFF17201F)]
                            : [Colors.white, const Color(0xFFD3E3B5)]),
                      ),
                      child: pokemon.imageUrl == null
                          ? Icon(Icons.image_not_supported_outlined, size: 64, color: ink)
                          : Hero(
                              tag: 'pokemon-artwork-${pokemon.id}',
                              child: Image.network(pokemon.imageUrl!,
                                fit: BoxFit.contain,
                                semanticLabel: pokemon.name,
                                loadingBuilder: (context, child, progress) =>
                                    progress == null ? child
                                        : const Center(child: CircularProgressIndicator()),
                                errorBuilder: (_, error, stackTrace) =>
                                    Icon(Icons.broken_image_outlined, size: 64, color: ink))),
                    ),
                    const SizedBox(height: 16),
                    Text(pokemon.name.toUpperCase(), textAlign: TextAlign.center,
                      style: TextStyle(color: ink, fontSize: 34)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
                      children: pokemon.types.map((type) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: dark ? const Color(0xFF394B32) : const Color(0xFFE0EABC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFAB8946))),
                        child: Text(type.toUpperCase(),
                          style: TextStyle(color: ink, fontSize: 20)),
                      )).toList()),
                    const SizedBox(height: 16),
                    Divider(color: ink.withAlpha(70)),
                    Wrap(spacing: 24, runSpacing: 8, alignment: WrapAlignment.center,
                      children: [
                        if (pokemon.heightCm != null)
                          _Measurement(label: 'HEIGHT', value: '${pokemon.heightCm} cm', ink: ink),
                        if (pokemon.weightKg != null)
                          _Measurement(label: 'WEIGHT',
                            value: '${pokemon.weightKg!.toStringAsFixed(1)} kg', ink: ink),
                      ]),
                  ]),
                ),
              ),
            )),
      ]),
    );
  }
}

class _Measurement extends StatelessWidget {
  const _Measurement({required this.label, required this.value, required this.ink});
  final String label;
  final String value;
  final Color ink;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(label, style: TextStyle(color: ink.withAlpha(180), fontSize: 16)),
    Text(value, style: TextStyle(color: ink, fontSize: 24)),
  ]);
}
