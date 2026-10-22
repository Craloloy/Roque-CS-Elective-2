# Pokédex — CS Elective 2 Midterm

Carl Rey M. Roque • Mobile Development with Flutter

Submission branch: **midterm-exam**, branched from **state-mgt-act** at `ad79381`.

## Run the midterm

From your existing project folder:

```powershell
git fetch origin
git switch midterm-exam
git pull --ff-only origin midterm-exam
flutter pub get
flutter run -d chrome
```

For a fresh copy:

```powershell
git clone --branch midterm-exam https://github.com/Craloloy/Roque-CS-Elective-2.git
cd Roque-CS-Elective-2
flutter pub get
flutter run -d chrome
```

The previous Provider lockfile is removed; `flutter pub get` generates the Riverpod dependency lockfile. Riverpod is pinned to version 3.0.3.

Use a Flutter SDK with Dart **3.12.2 or later**, matching the existing project's SDK constraint. Fully stop and restart the app after pulling: this version replaces the old Provider root with Riverpod's `ProviderScope`.

## State management choice: Riverpod

`flutter_riverpod` is the only state management package used by the application. The old `provider` dependency and `PokemonProvider`/`ChangeNotifier` implementation have been removed. No BLoC or code generation is used.

`ProviderScope` owns a `NotifierProvider<PokedexController, PokedexState>`. Widgets read state using `ref.watch(...)` and invoke actions using `ref.read(pokedexProvider.notifier)`. `PokedexState` holds immutable snapshots; the controller updates state with `copyWith`.

| Requirement | Implementation | Where to demonstrate |
| --- | --- | --- |
| Async list, loading, success, error | `PokedexController.fetch()` calls the existing HTTP service and updates status/error/list | Launch; refresh; disable network and refresh; restore network and retry |
| Refresh recalls the existing method | Initial load, refresh Poké Ball, pull-to-refresh, and Retry all invoke `fetch()` | `lib/screens/pokedex_screen.dart`; no separate `refresh()` method |
| Assign/edit/remove nickname | `saveNickname()` and `removeNickname()` store edits by Pokémon ID | Open a card → Give a nickname → Save/Edit/Remove |
| Expand/collapse favorites throughout the app | `toggleFavoritesPanel()` controls the panel above the inner Navigator | Open FAVORITES from the grid or detail display |
| Favorite hearts on cards | `toggleFavorite()` updates the ID set; `FavoriteButton` watches the current status | Tap the outlined/filled heart; panel updates immediately |
| Actual type filtering and clearing | `filterByType()`; `visiblePokemon` checks API type data | Tap a type chip, then ALL; dual-type entries match either type |

### Shared state and lifetime

- API data: Pokémon list, request status, and error message.
- Personal data: nicknames by ID and a set of favorite IDs.
- UI app state: selected Pokémon, selected type, panel expansion, and theme.
- Refresh updates API data without clearing nicknames/favorites. Changes made during a request are preserved when it finishes.
- The panel lists favorites independently of the type filter. Opening a favorite hidden by the filter clears the filter.
- Personal data is **in memory for the running app session**. Closing/restarting the app resets it; disk persistence is not required by this activity.
- HTTP clients are disposed through Riverpod. Text, scroll, and animation controllers are disposed by their owning widgets. Pending network results are ignored after disposal.

## Project map

```text
lib/main.dart                         ProviderScope + app themes
lib/models/pokemon.dart               API model; original identity is unchanged
lib/services/pokemon_service.dart     PokéAPI HTTP, parsing, timeout, batching
lib/state/pokedex_state.dart          Immutable app state + derived lists
lib/state/pokedex_controller.dart     Riverpod notifier + all app actions
lib/screens/pokedex_screen.dart       Home states, fetch callbacks, inner routes
lib/screens/pokemon_detail_screen.dart Detail view + nickname action
lib/widgets/favorite_button.dart      Reactive heart shared by cards and panel
lib/widgets/favorites_panel.dart      Collapsible favorites across pages
lib/widgets/nickname_editor.dart      Validated input, save, remove, cancel
lib/widgets/pokemon_type_filters.dart Type chips with icons and counts
```

The app retains the existing Pokédex frame, trading-card grid, dark mode, D-pad, in-frame route transitions, and artwork animations. It uses the same PokéAPI endpoint and 30-entry limit.

## Checks

```powershell
flutter analyze
flutter test
flutter build web
```

Automated tests cover state transitions, repeated requests, failure/retry, empty responses, nickname operations, favorite operations, dual-type matching, refresh preservation, disposal, and widget interactions. Tests use fake services/HTTP clients so they do not depend on live PokéAPI availability.

Manual recording checks: follow [the video script](docs/MIDTERM_VIDEO_SCRIPT.md). Demonstrate the actual API with your internet connection enabled; briefly turn it off to demonstrate error/retry. Do not describe checks as passing unless you have run them successfully.

## Submission

- Repository: https://github.com/Craloloy/Roque-CS-Elective-2/tree/midterm-exam
- Video: maximum 15 minutes; the provided script targets roughly 11–13 minutes including live demonstrations.
- Stated deadline: **October 22, 2026, 11:59 PM (Philippines time)**.

## References

- [Riverpod getting started](https://riverpod.dev/docs/introduction/getting_started)
- [Riverpod migration from ChangeNotifier](https://riverpod.dev/docs/migration/from_change_notifier)
- [Flutter Riverpod 3.0.3](https://pub.dev/packages/flutter_riverpod/versions/3.0.3)
