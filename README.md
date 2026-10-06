# Pokédex — State Management Activity

Branch: `state-mgt-act`, continued from `pokedex-act`.

## Run

Use Flutter with Dart 3.12.2 or later, as required by the existing project.

```sh
flutter pub get
flutter run -d chrome
```

## Activity requirements

- The PokéAPI list request uses `limit=30`; `Pokemon` models contain API-provided ID, name, and image plus types, height, and weight.
- `PokemonProvider` is a `ChangeNotifier` registered above `MaterialApp`. It owns loading/success/error state, the Pokémon list, selection, error message, and theme mode.
- `fetchPokemon()` is the Provider method used by the UI; `PokemonService` handles HTTP and JSON parsing.
- The existing scrollable trading-card grid and Pokédex frame are preserved.
- Pull down on the grid or press the labeled upper-right Poké Ball refresh button to make a fresh API request, including fresh detail requests. Retry uses the same Provider method.
- Tap a card to open its individual page with a fade/slide transition and shared artwork animation inside the stationary Pokédex frame. Back returns to the same grid and scroll position. The D-pad also browses entries in the detail display. The route passes only the ID; name, image, ID, and other displayed data are read from Provider and update when app state changes.
- Scroll and animation controllers remain widget-owned view mechanics; Pokémon data is not kept in local widget state.

## Verification

```sh
flutter analyze
flutter test
```

Tests cover model parsing, state transitions, errors/retry, refresh HTTP calls, selection, request completion after disposal, and grid-to-detail navigation. GitHub Actions runs analysis and tests on this branch.

## Submission

Submit the branch URL in Daigler:

https://github.com/Craloloy/Roque-CS-Elective-2/tree/state-mgt-act
