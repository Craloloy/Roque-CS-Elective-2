import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/pokemon_provider.dart';

class PokemonTypeFilters extends StatelessWidget {
  const PokemonTypeFilters({super.key, required this.onTypeChanged});
  final ValueChanged<String?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PokemonProvider>();
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFF2CF) : const Color(0xFF302A1B);
    return Container(
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF242B26) : const Color(0xFFF8F1D7),
        border: Border(bottom: BorderSide(color: ink.withAlpha(50))),
      ),
      padding: const EdgeInsets.only(top: 9, bottom: 7),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            Icon(Icons.tune_rounded, color: ink, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text('FILTER BY TYPE',
              style: TextStyle(color: ink, fontSize: 17, letterSpacing: 0.7))),
            Text('${state.visiblePokemon.length} / ${state.pokemon.length}',
              style: TextStyle(color: ink, fontSize: 17)),
            const SizedBox(width: 4),
            Icon(Icons.swipe_rounded, size: 15, color: ink.withAlpha(150)),
          ]),
        ),
        const SizedBox(height: 5),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(children: <String?>[null, ...state.availableTypes]
            .map((type) {
              final badge = _TypeBadge.forType(type);
              final selected = state.selectedType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 7),
                child: ChoiceChip(
                  key: ValueKey('type-${type ?? 'all'}'),
                  tooltip: type == null ? 'Show all Pokémon'
                      : 'Show ${type.toUpperCase()} Pokémon',
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => onTypeChanged(type),
                  avatar: Container(
                    decoration: BoxDecoration(
                      color: badge.color, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: badge.color.withAlpha(60), blurRadius: 4)],
                    ),
                    child: Icon(badge.icon, color: Colors.white, size: 17)),
                  label: Text('${type?.toUpperCase() ?? 'ALL'} ${state.countForType(type)}'),
                  labelStyle: TextStyle(color: ink, fontFamily: 'VT323', fontSize: 17),
                  backgroundColor: dark ? const Color(0xFF303834) : Colors.white,
                  selectedColor: Color.lerp(badge.color,
                    dark ? const Color(0xFF202820) : Colors.white, dark ? 0.6 : 0.78),
                  side: BorderSide(
                    color: selected ? badge.color : ink.withAlpha(40),
                    width: selected ? 2 : 1),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                ),
              );
            }).toList()),
        ),
      ]),
    );
  }
}

class _TypeBadge {
  const _TypeBadge(this.icon, this.color);
  final IconData icon;
  final Color color;

  static _TypeBadge forType(String? type) {
    switch (type) {
      case 'grass': return const _TypeBadge(Icons.spa_rounded, Color(0xFF70A94C));
      case 'fire': return const _TypeBadge(Icons.local_fire_department_rounded, Color(0xFFE27648));
      case 'water': return const _TypeBadge(Icons.water_drop_rounded, Color(0xFF4F9CC7));
      case 'bug': return const _TypeBadge(Icons.pest_control_rounded, Color(0xFF8F9D35));
      case 'poison': return const _TypeBadge(Icons.science_rounded, Color(0xFF9B6DB4));
      case 'electric': return const _TypeBadge(Icons.bolt_rounded, Color(0xFFBD9224));
      case 'normal': return const _TypeBadge(Icons.pets_rounded, Color(0xFFAE957B));
      case 'flying': return const _TypeBadge(Icons.air_rounded, Color(0xFF929ED1));
      case 'ground': return const _TypeBadge(Icons.landscape_rounded, Color(0xFFB78D59));
      case 'rock': return const _TypeBadge(Icons.terrain_rounded, Color(0xFF9D945F));
      case 'ice': return const _TypeBadge(Icons.ac_unit_rounded, Color(0xFF5FADB3));
      case 'psychic': return const _TypeBadge(Icons.auto_awesome_rounded, Color(0xFFE078A1));
      case 'fighting': return const _TypeBadge(Icons.sports_martial_arts_rounded, Color(0xFFBA5B50));
      case 'ghost': return const _TypeBadge(Icons.nights_stay_rounded, Color(0xFF79689C));
      case 'dragon': return const _TypeBadge(Icons.whatshot_rounded, Color(0xFF7760BE));
      case 'dark': return const _TypeBadge(Icons.dark_mode_rounded, Color(0xFF6C6470));
      case 'steel': return const _TypeBadge(Icons.shield_rounded, Color(0xFF81949C));
      case 'fairy': return const _TypeBadge(Icons.favorite_rounded, Color(0xFFD490B5));
      default: return const _TypeBadge(Icons.catching_pokemon, Color(0xFFDC6266));
    }
  }
}
