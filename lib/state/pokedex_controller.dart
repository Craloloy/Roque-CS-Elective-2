import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/pokemon_service.dart';
import 'pokedex_state.dart';

// The service only handles HTTP/JSON. Riverpod owns its lifetime.
final pokemonServiceProvider = Provider<PokemonService>((ref) {
  final service = PokemonService();
  ref.onDispose(service.dispose);
  return service;
});

final pokedexProvider = NotifierProvider<PokedexController, PokedexState>(
  PokedexController.new,
);

class PokedexController extends Notifier<PokedexState> {
  Future<void>? _pendingFetch;

  @override
  PokedexState build() => PokedexState();

  /// Initial load, retry, and refresh ALL recall this exact method.
  /// Repeated taps share the same Future rather than start competing requests.
  Future<void> fetch() {
    return _pendingFetch ??= _fetchAndUpdate().whenComplete(() {
      _pendingFetch = null;
    });
  }

  Future<void> _fetchAndUpdate() async {
    state = state.copyWith(status: PokemonStatus.loading, clearError: true);
    try {
      final pokemon = await ref
          .read(pokemonServiceProvider)
          .fetchPokemon(forceRefresh: true);
      if (!ref.mounted) return;
      var next = state.copyWith(
        pokemon: pokemon.take(30).toList(),
        status: PokemonStatus.success,
        clearError: true,
      );
      if (next.selectedType != null &&
          !next.availableTypes.contains(next.selectedType)) {
        next = next.copyWith(clearType: true);
      }
      state = _withVisibleSelection(next);
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: PokemonStatus.error,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  PokedexState _withVisibleSelection(PokedexState next) {
    final visible = next.visiblePokemon;
    if (visible.any((p) => p.id == next.selectedId)) return next;
    return next.copyWith(
      selectedId: visible.isEmpty ? null : visible.first.id,
      clearSelection: visible.isEmpty,
    );
  }

  void filterByType(String? type) {
    if (type != null && !state.availableTypes.contains(type)) return;
    state = _withVisibleSelection(
      state.copyWith(selectedType: type, clearType: type == null),
    );
  }

  void selectPokemon(int id) {
    if (state.pokemonById(id) == null) return;
    // Opening a favorite outside the current filter clears the filter so the
    // selected detail and D-pad always agree with the grid when returning.
    final hidden = !state.visiblePokemon.any((p) => p.id == id);
    state = state.copyWith(selectedId: id, clearType: hidden);
  }

  void navigate(int delta) {
    final visible = state.visiblePokemon;
    if (visible.isEmpty || state.isLoading) return;
    final current = visible.indexWhere((p) => p.id == state.selectedId);
    if (current < 0) {
      selectPokemon(visible.first.id);
      return;
    }
    if ((delta == -1 && current.isEven) || (delta == 1 && current.isOdd))
      return;
    final next = current + delta;
    if (next >= 0 && next < visible.length) selectPokemon(visible[next].id);
  }

  /// Returns an error for invalid input; null means the edit was saved.
  String? saveNickname(int id, String input) {
    if (state.pokemonById(id) == null) return 'This Pokémon is unavailable.';
    final nickname = input.trim();
    if (nickname.runes.length > 24) return 'Use 24 characters or fewer.';
    if (nickname.isEmpty) {
      removeNickname(id);
      return null;
    }
    state = state.copyWith(nicknames: {...state.nicknames, id: nickname});
    return null;
  }

  void removeNickname(int id) {
    final updated = {...state.nicknames}..remove(id);
    state = state.copyWith(nicknames: updated);
  }

  void toggleFavorite(int id) {
    if (state.pokemonById(id) == null) return;
    final updated = {...state.favoriteIds};
    if (!updated.add(id)) updated.remove(id);
    state = state.copyWith(favoriteIds: updated);
  }

  void toggleFavoritesPanel() {
    state = state.copyWith(favoritesExpanded: !state.favoritesExpanded);
  }

  void setDarkMode(bool dark) {
    state = state.copyWith(themeMode: dark ? ThemeMode.dark : ThemeMode.light);
  }
}
