import 'package:flutter/material.dart';

import '../models/pokemon.dart';
import '../services/pokemon_service.dart';

enum PokemonStatus { initial, loading, success, error }

/// Shared application state for both the grid and the detail route.
class PokemonProvider extends ChangeNotifier {
  PokemonProvider({PokemonService? service})
      : _service = service ?? PokemonService();

  final PokemonService _service;
  List<Pokemon> _pokemon = const [];
  PokemonStatus _status = PokemonStatus.initial;
  String? _errorMessage;
  int? _selectedId;
  ThemeMode _themeMode = ThemeMode.system;
  bool _disposed = false;

  List<Pokemon> get pokemon => _pokemon;
  PokemonStatus get status => _status;
  String? get errorMessage => _errorMessage;
  ThemeMode get themeMode => _themeMode;
  bool get isLoading => _status == PokemonStatus.loading;
  Pokemon? get selectedPokemon => pokemonById(_selectedId);

  Pokemon? pokemonById(int? id) {
    for (final entry in _pokemon) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// The UI calls this method for initial loading, retry, and refresh.
  Future<void> fetchPokemon({bool refresh = false}) async {
    if (_disposed || isLoading) return;
    _status = PokemonStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await _service.fetchPokemon(forceRefresh: refresh);
      if (_disposed) return;
      _pokemon = List<Pokemon>.unmodifiable(result.take(30));
      if (selectedPokemon == null) {
        _selectedId = _pokemon.isEmpty ? null : _pokemon.first.id;
      }
      _status = PokemonStatus.success;
    } catch (error) {
      if (_disposed) return;
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      _status = PokemonStatus.error;
    }
    notifyListeners();
  }

  Future<void> refresh() => fetchPokemon(refresh: true);

  void selectPokemon(int id) {
    if (_disposed || isLoading || pokemonById(id) == null) return;
    _selectedId = id;
    notifyListeners();
  }

  void navigate(int delta) {
    if (_disposed || isLoading || _pokemon.isEmpty) return;
    final current = _pokemon.indexWhere((p) => p.id == _selectedId);
    if (current < 0) {
      selectPokemon(_pokemon.first.id);
      return;
    }
    if ((delta == -1 && current.isEven) ||
        (delta == 1 && current.isOdd)) return;
    final next = current + delta;
    if (next >= 0 && next < _pokemon.length) {
      selectPokemon(_pokemon[next].id);
    }
  }

  void setDarkMode(bool dark) {
    if (_disposed) return;
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _service.dispose();
    super.dispose();
  }
}
