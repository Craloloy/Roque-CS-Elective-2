# Pokédex Midterm — Video Script

**Presenter:** Carl Rey M. Roque  
**Course:** CS Elective 2 — Mobile Development with Flutter  
**Target:** 11–13 minutes, including clicks and code navigation. Stop before 15 minutes.

Read the spoken paragraphs naturally. The “On screen” instructions are recording cues, not lines to read. Rehearse once with the finished app so your explanation matches what you demonstrate.

## Before recording

1. Switch to `midterm-exam`, run `flutter pub get`, and fully restart with `flutter run -d chrome`.
2. Open the app beside VS Code. Keep the browser in a portrait-shaped window, around 450 × 850 pixels.
3. Open these files in tabs: `main.dart`, `state/pokedex_state.dart`, `state/pokedex_controller.dart`, `services/pokemon_service.dart`, `screens/pokedex_screen.dart`, `widgets/favorite_button.dart`, `widgets/favorites_panel.dart`, and `widgets/nickname_editor.dart`.
4. Start a fresh app session so the favorites panel is empty. Use Bulbasaur for the nickname demonstration and Charmander for a second favorite.
5. For the error demonstration, prepare to disable your network temporarily, or use Chrome DevTools → Network → Offline. Click the app's REFRESH button after disabling the network. Return to Online and press Retry afterward. A timed-out request may take 15 seconds; trim the waiting period if needed, while showing the resulting state.
6. Keep any terminal test output you want to show. Only claim a test passed if the output confirms it.

## 0:00–0:40 — Introduction

**On screen:** Show the app and the `midterm-exam` branch in GitHub or VS Code.

Good day, Sir. I’m Carl Rey Roque, and this is my Pokédex application for our CS Elective 2 midterm exam.

I continued from my previous `state-mgt-act` branch and created a new branch called `midterm-exam`. For this version, I chose Riverpod as my state management approach.

The application includes asynchronous Pokémon loading, a nickname editor, favorites, heart indicators, and type filtering. I also kept the Pokédex-inspired interface, so opening a Pokémon still happens inside the device's screen.

## 0:40–1:40 — Loading, refreshing, and error handling

**On screen:** Show the loaded grid. Click REFRESH. Demonstrate the loading animation. Briefly trigger an offline error, restore the network, and press Retry.

The home page fetches the first 30 Pokémon from PokéAPI. While the request is running, the screen shows a loading indicator. When the request succeeds, the Pokémon appear in a scrollable grid.

The Poké Ball at the upper right is the refresh button. The important part is that refresh calls the same `fetch()` method used for the initial load. Pull-to-refresh and Retry also call that method. There is no separate refresh method with duplicated fetching logic.

If the request fails, the app shows an error message and a Retry action. Here I’m temporarily disabling the connection to demonstrate that state. After restoring the connection, I can retry without restarting the app.

## 1:40–3:00 — Nickname editor

**On screen:** Open Bulbasaur. Scroll if needed, press Give a nickname, enter “Leafy,” and save. Go back to the grid. Reopen it, change the nickname to “Sprout,” then remove it. Optionally set “Leafy” again for the favorites demo.

Opening a Pokémon shows its original name, image, ID, types, height, and weight. I can give it a nickname using this editor.

For example, I’ll name Bulbasaur “Leafy.” When I save, the nickname appears in the details and on its card. The original name stays visible, so the user can still identify which Pokémon it is.

I can edit the existing nickname, or remove it using the Remove button. A blank nickname also removes the saved nickname. The input is trimmed, and the app limits the nickname to 24 characters.

These changes are stored in Riverpod state using the Pokémon's ID. I do not overwrite the original name coming from the API.

## 3:00–4:20 — Favorites and the persistent panel

**On screen:** Expand FAVORITES while empty if not already demonstrated. Add Bulbasaur and Charmander using their card hearts. Expand/collapse the panel. Open a favorite. Remove it from the panel while viewing details.

Each card has a heart button. An outlined heart means the Pokémon is not a favorite, and a filled heart means it is. Tapping it changes the status immediately without opening the card.

This Favorites panel can be expanded or collapsed. When there are no favorites, it explains how to add one. Once I tap a heart, the Pokémon appears here immediately.

The panel stays available even when I open a Pokémon's details because it is placed outside the inner page navigator. I can open a favorite from the panel or remove it directly here. The heart on the card and the panel use the same state, so they remain consistent.

## 4:20–5:10 — Type filtering and preserved edits

**On screen:** Select Grass, then Poison, then ALL. Show a favorite from another type still present in the favorites panel. Refresh with a nickname and favorite saved.

The type chips use the actual type data returned by PokéAPI. Selecting Grass displays only matching entries. A Pokémon with two types appears under either matching filter, so Bulbasaur also appears under Poison.

ALL clears the filter and restores the full list. The counts help show how many Pokémon match. The D-pad also follows the filtered list.

Favorites are independent of this filter. If I open a favorite outside the selected type, the app clears the filter so the selection and grid remain consistent.

Refreshing reloads the API data but keeps my nicknames and favorites during the current app session.

## 5:10–6:05 — Why state management matters

**On screen:** Keep the card, details, and favorites panel visible as examples. Then open `pokedex_state.dart`.

State management matters because multiple parts of this app need to display and update the same information.

For example, a favorite is shown by the heart on the card, the heart in the detail view, and an entry in the favorites panel. If each widget maintained its own independent favorite value, they could become inconsistent.

With shared state, there is one source of truth. A user action updates that state, and the widgets that watch it rebuild with the updated value.

In this app, that includes the Pokémon list, loading and error status, nicknames, favorite IDs, selected type, current selection, panel expansion, and theme. Scroll positions, animation controllers, and unfinished text input remain local to the widgets that use them.

## 6:05–7:05 — Why I chose Riverpod

**On screen:** Show `pubspec.yaml`, then `main.dart`.

I chose Riverpod because its separation between state, actions, and widgets fits this application. The app has several related features, but their actions are straightforward: fetch, save a nickname, toggle a favorite, or select a type.

I use `NotifierProvider` with a `PokedexController` and an immutable `PokedexState`. This gives me one place to implement the rules for those actions. It also lets me test the controller without having to run the complete interface or call the real API.

I removed the old Provider implementation. Riverpod is the only state management approach used in this version; I am not combining it with BLoC.

At the app root, `ProviderScope` owns the providers. In widgets, `ref.watch` subscribes to state for rendering, while `ref.read` accesses the notifier when a button needs to trigger an action.

## 7:05–8:40 — State and fetching code

**On screen:** Show the fields and `copyWith` in `pokedex_state.dart`. Then show `fetch()` and `_fetchAndUpdate()` in `pokedex_controller.dart`. Briefly show the HTTP service.

`PokedexState` is a snapshot of the application. Its collections are unmodifiable, and updates create a new state through `copyWith` rather than changing the existing collection in place.

The fetched Pokémon and the personal edits are stored separately. The list holds the API data, nicknames are a map keyed by Pokémon ID, and favorites are a set of IDs.

In the controller, `fetch()` starts the asynchronous operation and remembers the pending Future. If the user triggers it again before it finishes, the method returns the same Future instead of starting a competing request.

The private helper sets the status to loading, awaits the service, and then updates the list and status. Errors are caught and stored in state for the screen to display. Before updating after an asynchronous request, it checks that the Riverpod reference is still mounted.

The service handles HTTP requests, JSON parsing, timeouts, and fetching details in small batches. The controller handles how those results affect app state. The widgets only render that state and invoke actions.

When the request finishes, I copy from the current state. That preserves nickname or favorite changes made while the request was still running.

## 8:40–10:00 — Nickname and favorite actions

**On screen:** Show `saveNickname`, `removeNickname`, and `toggleFavorite`. Show `NicknameEditor` and `FavoriteButton`.

`saveNickname` checks the input and creates an updated map containing the nickname under the Pokémon's ID. `removeNickname` copies the map, removes that entry, and publishes a new state.

The editor uses a `TextEditingController` for the text being typed. That is only a draft. The shared nickname changes when Save is pressed. Cancel closes the dialog without saving, and the text controller is disposed when the dialog is removed.

`toggleFavorite` copies the set of favorite IDs. If the ID is not in the set, it adds it. Otherwise, it removes it. A set also prevents duplicate favorite IDs.

`FavoriteButton` watches whether its own Pokémon ID is favorited. It uses that value to choose a filled or outlined heart. Its callback calls the notifier's `toggleFavorite` method.

The panel derives its entries from that same ID set and the Pokémon list. Its expanded state is also stored in Riverpod.

## 10:00–11:00 — Derived filters and widget updates

**On screen:** Show `visiblePokemon`, `favorites`, and `availableTypes` in state. Show `filterByType` and the callbacks in `pokedex_screen.dart`.

The filtered list is derived from the full Pokémon list. I do not remove nonmatching entries from the source data. This is why clearing the filter can restore all the Pokémon immediately without another API call.

`visiblePokemon` checks whether each Pokémon's types contain the selected type. With no selected type, all entries are included. `availableTypes` is also derived from the API data, so the chips match the loaded Pokémon.

In the screen, the widgets watch Riverpod state and rebuild when it changes. Notice that the initial load, Retry, refresh button, and pull-to-refresh all point to the controller's same `fetch()` method.

## 11:00–12:00 — Verification, limitations, and closing

**On screen:** Show tests or the README requirement table, then return to the app and GitHub branch.

I included tests for loading and error states, retrying, nickname operations, favorites, filters, and keeping personal edits during refresh. There are also widget tests for the heart button, favorites panel, nickname dialog, and type chips.

[If you ran them successfully: “Here is the output from running the tests.” Otherwise, explain honestly which checks you were able to complete; do not claim all tests passed.]

One limitation is that nicknames and favorites are stored in memory. They remain available during navigation and refresh, but they reset when the application restarts. Persistent storage could be added later, but the exam asks for these values to be managed in app state.

Overall, Riverpod keeps the application consistent by giving the interface a shared state and a clear set of actions. It also separates the presentation from the application logic, which makes the features easier to maintain and test.

That concludes my Pokédex midterm demonstration. The code is pushed to the `midterm-exam` branch. Thank you, Sir.

---

## Quick answers to prepare for follow-up questions

- **Why `Notifier` instead of `AsyncNotifier`?** The app state is a composite snapshot containing both request status and personal/UI data. `Notifier<PokedexState>` makes those fields explicit and keeps personal edits available while a fetch is running. `AsyncNotifier` is another valid Riverpod design, but is not used here.
- **What triggers a rebuild?** Assigning a new `state` in the notifier notifies Riverpod subscribers; `ref.watch` connects a widget to those updates.
- **Why use IDs?** IDs remain stable even when API objects are recreated during refresh. Display names and nicknames are not reliable unique keys.
- **Is Riverpod's `Provider` the old Provider package?** No. `pokemonServiceProvider` is Riverpod's dependency provider. The old `package:provider` dependency is removed.
- **Where is the list fetched?** The controller owns `fetch()` and request state. It delegates transport and parsing to `PokemonService`.
- **Does filtering refetch?** No. It derives a matching list from the 30 already-loaded entries.
- **Does refresh erase favorites?** No. The controller replaces API data while retaining the current personal-data fields.
- **Why no database?** The requirements ask for app state, so this version is intentionally session-only. A database would be a separate persistence layer.

## Recording checklist

- [ ] Show `midterm-exam` branch.
- [ ] Show loading, successful list, refresh, error, and retry.
- [ ] Add, edit, and remove a nickname; keep the original name visible.
- [ ] Add and remove favorites using card hearts.
- [ ] Expand/collapse favorites on the grid and detail screen.
- [ ] Show the empty favorites message.
- [ ] Demonstrate type selection and ALL.
- [ ] Explain `ProviderScope`, `NotifierProvider`, state snapshots, `ref.watch`, and `ref.read`.
- [ ] Explain why state management matters and why you chose Riverpod.
- [ ] Finish before 15 minutes and submit the branch URL plus video.
