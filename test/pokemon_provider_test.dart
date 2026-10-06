import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/pokemon.dart';
import 'package:flutter_application_1/providers/pokemon_provider.dart';
import 'package:flutter_application_1/services/pokemon_service.dart';

Pokemon entry(int id, {String? name}) =>
    Pokemon(id: id, name: name ?? 'pokemon-$id', imageUrl: null);

class FakeService extends PokemonService {
  int calls = 0;
  bool? lastRefresh;
  Future<List<Pokemon>> Function() load = () async => [entry(1), entry(2)];

  @override
  Future<List<Pokemon>> fetchPokemon({bool forceRefresh = false}) {
    calls++;
    lastRefresh = forceRefresh;
    return load();
  }
}

void main() {
  test('Notifies loading then success and exposes immutable app state', () async {
    final pending = Completer<List<Pokemon>>();
    final service = FakeService()..load = () => pending.future;
    final state = PokemonProvider(service: service);
    addTearDown(state.dispose);
    final statuses = <PokemonStatus>[];
    state.addListener(() => statuses.add(state.status));
    final request = state.fetchPokemon();
    expect(state.isLoading, isTrue);
    await state.fetchPokemon(); // Duplicate requests do not race.
    expect(service.calls, 1);
    pending.complete(List.generate(35, (index) => entry(index + 1)));
    await request;
    expect(statuses, [PokemonStatus.loading, PokemonStatus.success]);
    expect(state.pokemon, hasLength(30));
    expect(state.selectedPokemon?.id, 1);
    expect(() => state.pokemon.clear(), throwsUnsupportedError);
  });

  test('Refresh reloads data and resolves selection to the new model', () async {
    final service = FakeService();
    final state = PokemonProvider(service: service);
    addTearDown(state.dispose);
    await state.fetchPokemon();
    state.selectPokemon(2);
    service.load = () async => [entry(1), entry(2, name: 'updated')];
    await state.refresh();
    expect(service.calls, 2);
    expect(service.lastRefresh, isTrue);
    expect(state.selectedPokemon?.name, 'updated');
    service.load = () async => [entry(3)];
    await state.refresh();
    expect(state.selectedPokemon?.id, 3);
  });

  test('Error state recovers with retry and clears the old error', () async {
    final service = FakeService()..load = () async => throw Exception('Offline');
    final state = PokemonProvider(service: service);
    addTearDown(state.dispose);
    await state.fetchPokemon();
    expect(state.status, PokemonStatus.error);
    expect(state.errorMessage, 'Offline');
    service.load = () async => [entry(1)];
    await state.refresh();
    expect(state.status, PokemonStatus.success);
    expect(state.errorMessage, isNull);
  });

  test('Selection, directional controls, and theme belong to Provider', () async {
    final state = PokemonProvider(service: FakeService());
    addTearDown(state.dispose);
    await state.fetchPokemon();
    state.navigate(-1);
    expect(state.selectedPokemon?.id, 1);
    state.navigate(1);
    expect(state.selectedPokemon?.id, 2);
    state.selectPokemon(999);
    expect(state.selectedPokemon?.id, 2);
    state.setDarkMode(true);
    expect(state.themeMode, ThemeMode.dark);
  });

  test('A disposed Provider ignores completion of an in-flight request', () async {
    final pending = Completer<List<Pokemon>>();
    final state = PokemonProvider(
      service: FakeService()..load = () => pending.future);
    final request = state.fetchPokemon();
    state.dispose();
    pending.complete([entry(1)]);
    await request;
    expect(state.pokemon, isEmpty);
  });

  test('Refresh makes new list and detail HTTP calls instead of using cache', () async {
    var listCalls = 0;
    var detailCalls = 0;
    final service = PokemonService(client: MockClient((request) async {
      if (request.url.path == '/api/v2/pokemon') {
        listCalls++;
        expect(request.url.queryParameters['limit'], '30');
        return http.Response(jsonEncode({'results': [
          {'url': 'https://pokeapi.co/api/v2/pokemon/1/'}
        ]}), 200);
      }
      detailCalls++;
      return http.Response(jsonEncode({
        'id': 1, 'name': 'version-$detailCalls', 'sprites': {},
      }), 200);
    }));
    final state = PokemonProvider(service: service);
    addTearDown(state.dispose);
    await state.fetchPokemon();
    await state.refresh();
    expect(listCalls, 2);
    expect(detailCalls, 2);
    expect(state.pokemon.single.name, 'version-2');
  });

  testWidgets('Tapping a grid card opens details that react to Provider updates',
      (tester) async {
    final service = FakeService();
    final state = PokemonProvider(service: service);
    addTearDown(state.dispose);
    await state.fetchPokemon();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: state, child: const PokedexApp()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('POKEMON-2'));
    await tester.pumpAndSettle();
    expect(find.text('ID: #002'), findsOneWidget);
    service.load = () async => [entry(1), entry(2, name: 'updated')];
    await state.refresh();
    await tester.pumpAndSettle();
    expect(find.text('UPDATED'), findsNWidgets(2));
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh Pokémon'));
    await tester.pumpAndSettle();
    expect(service.calls, 3);
    expect(tester.takeException(), isNull);
  });
}
