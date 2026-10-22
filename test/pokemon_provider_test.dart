import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/models/pokemon.dart';
import 'package:flutter_application_1/services/pokemon_service.dart';
import 'package:flutter_application_1/state/pokedex_controller.dart';
import 'package:flutter_application_1/state/pokedex_state.dart';
import 'package:flutter_application_1/widgets/pokedex_frame.dart';
import 'package:flutter_application_1/widgets/pokemon_card.dart';
import 'package:flutter_application_1/widgets/favorites_panel.dart';
import 'package:flutter_application_1/screens/pokemon_detail_screen.dart';

Pokemon entry(int id, {String? name, List<String> types = const []}) =>
    Pokemon(id: id, name: name ?? 'pokemon-$id', imageUrl: null, types: types);

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

ProviderContainer containerFor(PokemonService service) {
  final container = ProviderContainer(
    overrides: [pokemonServiceProvider.overrideWithValue(service)],
  );
  addTearDown(() {
    container.dispose();
    service.dispose();
  });
  return container;
}

Future<void> showApp(WidgetTester tester, ProviderContainer container) async {
  tester.view.resetPhysicalSize();
  tester.view.physicalSize = const Size(500, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const PokedexApp()),
  );
  await tester.pumpAndSettle();
}

void main() {
  test(
    'fetch transitions through loading/success and coalesces duplicate calls',
    () async {
      final pending = Completer<List<Pokemon>>();
      final service = FakeService()..load = () => pending.future;
      final container = containerFor(service);
      final controller = container.read(pokedexProvider.notifier);
      final statuses = <PokemonStatus>[];
      container.listen(pokedexProvider, (_, next) => statuses.add(next.status));
      final request = controller.fetch();
      expect(container.read(pokedexProvider).isLoading, isTrue);
      expect(identical(controller.fetch(), request), isTrue);
      pending.complete(List.generate(35, (i) => entry(i + 1)));
      await request;
      expect(statuses, [PokemonStatus.loading, PokemonStatus.success]);
      expect(service.calls, 1);
      expect(container.read(pokedexProvider).pokemon, hasLength(30));
      expect(
        () => container.read(pokedexProvider).pokemon.clear(),
        throwsUnsupportedError,
      );
    },
  );

  test('same fetch method retries errors, clears errors, and handles empty results', () async {
    final service = FakeService()
      ..load = () async => throw Exception('Offline');
    final container = containerFor(service);
    final controller = container.read(pokedexProvider.notifier);
    await controller.fetch();
    expect(container.read(pokedexProvider).status, PokemonStatus.error);
    expect(container.read(pokedexProvider).errorMessage, 'Offline');
    service.load = () async => [];
    await controller.fetch();
    expect(container.read(pokedexProvider).status, PokemonStatus.success);
    expect(container.read(pokedexProvider).errorMessage, isNull);
    expect(container.read(pokedexProvider).selectedPokemon, isNull);
  });

  test('nickname creation, editing, validation and removal preserve original names', () async {
    final container = containerFor(FakeService());
    final controller = container.read(pokedexProvider.notifier);
    await controller.fetch();
    expect(controller.saveNickname(1, '  Leafy  '), isNull);
    expect(container.read(pokedexProvider).nicknameFor(1), 'Leafy');
    controller.saveNickname(1, 'Sprout');
    expect(container.read(pokedexProvider).nicknameFor(1), 'Sprout');
    expect(container.read(pokedexProvider).pokemonById(1)!.name, 'pokemon-1');
    expect(controller.saveNickname(1, 'x' * 25), isNotNull);
    expect(container.read(pokedexProvider).nicknameFor(1), 'Sprout');
    controller.removeNickname(1);
    expect(container.read(pokedexProvider).nicknameFor(1), isNull);
    controller.saveNickname(1, 'Leafy');
    controller.saveNickname(1, '   ');
    expect(container.read(pokedexProvider).nicknameFor(1), isNull);
  });

  test(
    'favorites are unique and ignore type filters; both types match',
    () async {
      final service = FakeService()
        ..load = () async => [
          entry(1, types: ['grass', 'poison']),
          entry(2, types: ['water']),
          entry(3, types: ['poison']),
        ];
      final container = containerFor(service);
      final controller = container.read(pokedexProvider.notifier);
      await controller.fetch();
      controller.toggleFavorite(2);
      controller.filterByType('poison');
      expect(container.read(pokedexProvider).visiblePokemon.map((p) => p.id), [
        1,
        3,
      ]);
      expect(container.read(pokedexProvider).favorites.single.id, 2);
      controller.navigate(1);
      expect(container.read(pokedexProvider).selectedId, 3);
      controller.selectPokemon(2);
      expect(container.read(pokedexProvider).selectedType, isNull);
      expect(container.read(pokedexProvider).selectedId, 2);
      controller.toggleFavorite(2);
      expect(container.read(pokedexProvider).favorites, isEmpty);
      controller.toggleFavorite(999);
      expect(container.read(pokedexProvider).favoriteIds, isEmpty);
    },
  );

  test(
    'personal edits made during fetch survive its completion and failure',
    () async {
      final service = FakeService();
      final container = containerFor(service);
      final controller = container.read(pokedexProvider.notifier);
      await controller.fetch();
      final pending = Completer<List<Pokemon>>();
      service.load = () => pending.future;
      final request = controller.fetch();
      controller.saveNickname(1, 'Leafy');
      controller.toggleFavorite(1);
      controller.toggleFavoritesPanel();
      controller.setDarkMode(true);
      pending.complete([entry(1), entry(2)]);
      await request;
      expect(container.read(pokedexProvider).nicknameFor(1), 'Leafy');
      expect(container.read(pokedexProvider).isFavorite(1), isTrue);
      expect(container.read(pokedexProvider).favoritesExpanded, isTrue);
      expect(container.read(pokedexProvider).themeMode, ThemeMode.dark);
      service.load = () async => throw Exception('Offline');
      await controller.fetch();
      expect(container.read(pokedexProvider).nicknameFor(1), 'Leafy');
      expect(container.read(pokedexProvider).favorites.single.id, 1);
    },
  );

  test(
    'fetch preserves valid filters and clears missing types after refresh',
    () async {
      final service = FakeService()
        ..load = () async => [
          entry(1, types: ['grass']),
        ];
      final container = containerFor(service);
      final controller = container.read(pokedexProvider.notifier);
      await controller.fetch();
      controller.filterByType('grass');
      await controller.fetch();
      expect(container.read(pokedexProvider).selectedType, 'grass');
      service.load = () async => [
        entry(2, types: ['water']),
      ];
      await controller.fetch();
      expect(container.read(pokedexProvider).selectedType, isNull);
      expect(container.read(pokedexProvider).selectedId, 2);
    },
  );

  test('disposed controller safely ignores an in-flight response', () async {
    final pending = Completer<List<Pokemon>>();
    final service = FakeService()..load = () => pending.future;
    final container = ProviderContainer(
      overrides: [pokemonServiceProvider.overrideWithValue(service)],
    );
    final request = container.read(pokedexProvider.notifier).fetch();
    container.dispose();
    pending.complete([entry(1)]);
    await request;
    service.dispose();
  });

  test('recalling fetch makes fresh list and detail HTTP requests', () async {
    var listCalls = 0;
    var detailCalls = 0;
    final service = PokemonService(
      client: MockClient((request) async {
        if (request.url.path == '/api/v2/pokemon') {
          listCalls++;
          expect(request.url.queryParameters['limit'], '30');
          return http.Response(
            jsonEncode({
              'results': [
                {'url': 'https://pokeapi.co/api/v2/pokemon/1/'},
              ],
            }),
            200,
          );
        }
        detailCalls++;
        return http.Response(
          jsonEncode({'id': 1, 'name': 'version-$detailCalls', 'sprites': {}}),
          200,
        );
      }),
    );
    final container = containerFor(service);
    final controller = container.read(pokedexProvider.notifier);
    await controller.fetch();
    await controller.fetch();
    expect(listCalls, 2);
    expect(detailCalls, 2);
    expect(container.read(pokedexProvider).pokemon.single.name, 'version-2');
  });

  testWidgets(
    'heart updates cards/panel without opening details; panel stays on details',
    (tester) async {
      final container = containerFor(FakeService());
      await showApp(tester, container);
      await tester.tap(find.byKey(const ValueKey('favorites-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('favorites-empty')), findsOneWidget);
      final card = find.byType(PokemonCard).first;
      await tester.tap(
        find.descendant(
          of: card,
          matching: find.byKey(const ValueKey('favorite-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PokemonDetailScreen), findsNothing);
      expect(find.text('FAVORITES (1)'), findsOneWidget);
      final frame = tester.element(find.byType(PokedexFrame));
      await tester.tap(find.byKey(const ValueKey('open-favorite-1')));
      await tester.pumpAndSettle();
      expect(find.byType(PokemonDetailScreen), findsOneWidget);
      expect(tester.element(find.byType(PokedexFrame)), same(frame));
      expect(find.byType(FavoritesPanel), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(FavoritesPanel),
          matching: find.byKey(const ValueKey('favorite-1')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('favorites-empty')), findsOneWidget);
      expect(container.read(pokedexProvider).isFavorite(1), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nickname dialog saves, edits, removes, and updates the grid', (
    tester,
  ) async {
    final container = containerFor(FakeService());
    await showApp(tester, container);
    await tester.tap(
      find.descendant(
        of: find.byType(PokemonCard),
        matching: find.text('POKEMON-2'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('edit-nickname')));
    await tester.tap(find.byKey(const ValueKey('edit-nickname')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      'Leafy',
    );
    await tester.tap(find.byKey(const ValueKey('save-nickname')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-nickname-2')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('card-nickname-2')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(PokemonCard),
        matching: find.text('POKEMON-2'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('edit-nickname')));
    await tester.tap(find.byKey(const ValueKey('edit-nickname')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextFormField, 'Leafy'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('nickname-input')),
      'Sprout',
    );
    await tester.tap(find.byKey(const ValueKey('save-nickname')));
    await tester.pumpAndSettle();
    expect(container.read(pokedexProvider).nicknameFor(2), 'Sprout');
    await tester.tap(find.byKey(const ValueKey('edit-nickname')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('remove-nickname')));
    await tester.pumpAndSettle();
    expect(container.read(pokedexProvider).nicknameFor(2), isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'type chips and All update cards, with the same fetch for refresh',
    (tester) async {
      final service = FakeService()
        ..load = () async => [
          entry(1, types: ['grass', 'poison']),
          entry(2, types: ['water']),
        ];
      final container = containerFor(service);
      await showApp(tester, container);
      await tester.tap(find.byKey(const ValueKey('type-grass')));
      await tester.pumpAndSettle();
      expect(find.text('POKEMON-2'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('type-all')));
      await tester.pumpAndSettle();
      expect(find.text('POKEMON-2'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh Pokémon'));
      await tester.pumpAndSettle();
      expect(service.calls, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
