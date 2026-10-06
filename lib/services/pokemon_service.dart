import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon.dart';

class PokemonService {
  PokemonService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  void dispose() => _client.close();
  final Map<int, Map<String, dynamic>> _pokemonCache = {};

  Future<Map<String, dynamic>> _loadPokemon(int id) async {
    final cached = _pokemonCache[id];
    if (cached != null) return cached;
    final data = await _getJson('/api/v2/pokemon/$id/');
    _pokemonCache[id] = data;
    return data;
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final response = await _client.get(Uri.https('pokeapi.co', path))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw Exception('Unable to load Pokémon (${response.statusCode}).');
    }
    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid Pokémon response.');
    }
    return data;
  }

  // A Future fits because fetching produces one completed list.
  // A Stream would be appropriate for ongoing updates over time.
  Future<List<Pokemon>> fetchPokemon({bool forceRefresh = false}) async {
    if (forceRefresh) _pokemonCache.clear();
    try {
      final response = await _client
          .get(Uri.https('pokeapi.co', '/api/v2/pokemon', {'limit': '30'}))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Unable to load Pokémon (${response.statusCode}).');
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic> || data['results'] is! List) {
        throw const FormatException('Invalid Pokémon response.');
      }

      final entries = (data['results'] as List).take(30).toList();
      final pokemon = <Pokemon>[];
      // Fetch in small batches; each response supplies the real image URL.
      for (var start = 0; start < entries.length; start += 5) {
        final batch = entries.skip(start).take(5);
        final results = await Future.wait(batch.map((item) async {
          if (item is! Map<String, dynamic> || item['url'] is! String) {
            throw const FormatException('Invalid Pokémon data.');
          }
          final segments = Uri.parse(item['url'] as String)
              .pathSegments.where((part) => part.isNotEmpty);
          final id = segments.isEmpty ? null : int.tryParse(segments.last);
          if (id == null || id <= 0) {
            throw const FormatException('Invalid Pokémon ID.');
          }
          return Pokemon.fromJson(await _loadPokemon(id));
        }));
        pokemon.addAll(results);
      }
      return pokemon;
    } on TimeoutException {
      throw Exception('The request timed out. Please try again.');
    } on http.ClientException {
      throw Exception('Unable to connect. Check your internet connection.');
    } on FormatException {
      throw Exception('The server returned invalid Pokémon data.');
    }
  }
}
