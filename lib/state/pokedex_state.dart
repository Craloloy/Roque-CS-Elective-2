import 'package:flutter/material.dart';

import '../models/pokemon.dart';

enum PokemonStatus { initial, loading, success, error }

/// One immutable snapshot. API data and personal edits have separate fields,
/// so fetching a new list never overwrites favorites or nicknames.
class PokedexState {
  PokedexState({
    List<Pokemon> pokemon = const [],
    this.status = PokemonStatus.initial,
    this.errorMessage,
    this.selectedId,
    this.selectedType,
    Map<int, String> nicknames = const {},
    Set<int> favoriteIds = const {},
    this.favoritesExpanded = false,
    this.themeMode = ThemeMode.system,
  }) : pokemon = List.unmodifiable(pokemon),
       nicknames = Map.unmodifiable(nicknames),
       favoriteIds = Set.unmodifiable(favoriteIds);

  final List<Pokemon> pokemon;
  final PokemonStatus status;
  final String? errorMessage;
  final int? selectedId;
  final String? selectedType;
  final Map<int, String> nicknames;
  final Set<int> favoriteIds;
  final bool favoritesExpanded;
  final ThemeMode themeMode;

  bool get isLoading => status == PokemonStatus.loading;
  Pokemon? get selectedPokemon => pokemonById(selectedId);
  List<String> get availableTypes =>
      (pokemon.expand((p) => p.types).toSet().toList()..sort());
  List<Pokemon> get visiblePokemon => List.unmodifiable(
    pokemon.where(
      (p) => selectedType == null || p.types.contains(selectedType),
    ),
  );
  // Favorites deliberately ignore the active type filter.
  List<Pokemon> get favorites =>
      List.unmodifiable(pokemon.where((p) => favoriteIds.contains(p.id)));

  Pokemon? pokemonById(int? id) {
    for (final entry in pokemon) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  String? nicknameFor(int id) => nicknames[id];
  bool isFavorite(int id) => favoriteIds.contains(id);
  int countForType(String? type) =>
      pokemon.where((p) => type == null || p.types.contains(type)).length;

  PokedexState copyWith({
    List<Pokemon>? pokemon,
    PokemonStatus? status,
    String? errorMessage,
    bool clearError = false,
    int? selectedId,
    bool clearSelection = false,
    String? selectedType,
    bool clearType = false,
    Map<int, String>? nicknames,
    Set<int>? favoriteIds,
    bool? favoritesExpanded,
    ThemeMode? themeMode,
  }) => PokedexState(
    pokemon: pokemon ?? this.pokemon,
    status: status ?? this.status,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    selectedId: clearSelection ? null : selectedId ?? this.selectedId,
    selectedType: clearType ? null : selectedType ?? this.selectedType,
    nicknames: nicknames ?? this.nicknames,
    favoriteIds: favoriteIds ?? this.favoriteIds,
    favoritesExpanded: favoritesExpanded ?? this.favoritesExpanded,
    themeMode: themeMode ?? this.themeMode,
  );
}
