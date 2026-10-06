import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  const PokemonCard({
    super.key, required this.pokemon, required this.onTap,
    this.selected = false,
  });
  final Pokemon pokemon;
  final VoidCallback onTap;
  final bool selected;

  Color get _typeColor {
    switch (pokemon.types.isEmpty ? '' : pokemon.types.first) {
      case 'grass': return const Color(0xFF70A94C);
      case 'fire': return const Color(0xFFDB7941);
      case 'water': return const Color(0xFF4F9CC7);
      case 'bug': return const Color(0xFF9AA840);
      case 'poison': return const Color(0xFF9B6DB4);
      case 'electric': return const Color(0xFFE0B83E);
      case 'normal': return const Color(0xFFAE957B);
      default: return const Color(0xFF7397A0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFF2CF) : const Color(0xFF302A1B);
    final accent = _typeColor;
    final textStyle = TextStyle(fontFamily: 'VT323', fontSize: 18, color: ink);
    return Semantics(
      selected: selected,
      label: '${pokemon.name}, ID ${pokemon.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: selected ? const Color(0x668BC34A) : const Color(0x33202020),
              offset: const Offset(0, 3), blurRadius: selected ? 8 : 3),
          ],
        ),
        child: Material(
          color: dark ? const Color(0xFFB68F3E) : const Color(0xFFF1CE68),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: selected ? const Color(0xFF7EC74B) : const Color(0xFFAC8133),
              width: selected ? 3 : 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: dark
                      ? [Color.lerp(accent, Colors.black, 0.55)!, const Color(0xFF282A28)]
                      : [Color.lerp(accent, Colors.white, 0.5)!, const Color(0xFFFFF2CB)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Column(children: [
                    Row(children: [
                      Expanded(
                        child: Text(pokemon.name.toUpperCase(), maxLines: 1,
                          overflow: TextOverflow.ellipsis, style: textStyle),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.catching_pokemon, size: 14, color: ink),
                    ]),
                    const SizedBox(height: 5),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFAB8946), width: 2),
                          gradient: RadialGradient(
                            colors: dark
                              ? [accent.withAlpha(180), const Color(0xFF17201F)]
                              : [Colors.white, Color.lerp(accent, Colors.white, 0.6)!],
                          ),
                        ),
                        padding: const EdgeInsets.all(5),
                        child: pokemon.imageUrl == null
                          ? const Center(child: Icon(Icons.image_not_supported_outlined))
                          : Hero(
                            tag: 'pokemon-artwork-${pokemon.id}',
                            child: Image.network(
                              pokemon.imageUrl!, fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                              semanticLabel: pokemon.name,
                              loadingBuilder: (context, child, progress) => progress == null
                                ? child : const Center(child: CircularProgressIndicator()),
                              errorBuilder: (context, error, stackTrace) =>
                                const Center(child: Icon(Icons.broken_image_outlined)),
                            ),
                          ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(pokemon.types.isEmpty ? 'POKÉMON' : pokemon.types.join(' / ').toUpperCase(),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: textStyle.copyWith(fontSize: 15)),
                    Divider(height: 7, thickness: 1, color: ink.withAlpha(90)),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(pokemon.heightCm == null ? '—' : '${pokemon.heightCm} cm',
                        style: textStyle.copyWith(fontSize: 14)),
                      Text(pokemon.weightKg == null ? '—' : '${pokemon.weightKg!.toStringAsFixed(1)} kg',
                        style: textStyle.copyWith(fontSize: 14)),
                    ]),
                    const SizedBox(height: 3),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('ID: #${pokemon.id.toString().padLeft(3, '0')}',
                        style: textStyle.copyWith(fontSize: 16)),
                      Icon(selected ? Icons.star : Icons.star_border, size: 13, color: ink),
                    ]),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
