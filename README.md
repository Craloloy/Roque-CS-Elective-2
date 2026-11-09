# Campus Shop

Supabase product browsing with a price-range slider, 8 products per page, and Riverpod state management.

## Setup

Edit `lib/product_browser/supabase_config.dart`:

```dart
static const url = 'https://YOUR-PROJECT.supabase.co';
static const anonKey = 'YOUR-CLIENT-PUBLISHABLE-OR-ANON-KEY';
static const productsTable = 'products';
```

Use your project's client publishable/anon key from the Supabase dashboard. Keep service-role keys out of Flutter.

The default table uses `id`, `name`, numeric `price`, and nullable `image_url`. If your column names differ, edit the query in `lib/product_browser/product_repository.dart` and the mapping in `product_models.dart`. For example, `name:title` aliases a `title` column to the expected `name`. If no image column exists, remove `image_url` from select; a placeholder will appear.

For a new/demo database, run `sql/optional_demo_setup.sql` in Supabase SQL Editor. For an existing database, keep its schema and policies and adapt the repository. Your current user needs SELECT access under RLS.

## Run

```powershell
flutter pub get
flutter run -t lib/main_supabase.dart
```

This entry point opens the Supabase browsing activity. `lib/main.dart` still opens the original MagiStore app from `PrelimExam`.

## Existing update/delete features

Keep your current authenticated write operations. After a successful change, reload this module:

```dart
await ref.read(productBrowserProvider.notifier).load(reloadBounds: true);
```

This updates the price bounds and corrects the page after deleting the final items on the last page.

## Checks

```powershell
flutter analyze
flutter test test/product_browser_test.dart
```

Flutter tests and a live Supabase connection have not been run in the authoring environment. Supply your configuration and run these checks locally.

Price filtering uses Supabase `gte`/`lte`. Pagination uses inclusive `range` offsets with an exact filtered count. Rows sort by price and then ID for stable page boundaries. The state controller resets to page 1 on filter changes, ignores stale responses, and handles loading, errors/retry, and empty results.
