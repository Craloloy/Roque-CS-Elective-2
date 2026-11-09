# Carltronics

A violet and lavender Flutter laptop storefront for office work, studying, gaming, and creative work. Includes a left price filter, Supabase pagination, and Riverpod state management. On phones, filters open in a left drawer.

## Setup

Add your Supabase project URL and client publishable/anon key in `lib/product_browser/supabase_config.dart`.

The `products` table uses `id`, `name`, numeric `price`, and nullable `image_url`. For a new database, run `sql/optional_demo_setup.sql` in Supabase SQL Editor. Then run `sql/carltronics_sample_products.sql` for 20 sample laptops.

The seed removes unchanged merchandise and numbered placeholders from the previous demo. Other existing products remain. Running it again skips laptop names already present. Prices are demo values, not current retail quotes.

Demo laptops use generic built-in illustrations via `carltronics://laptop/office`, `student`, `ultrabook`, `gaming`, or `creator`. Replace `image_url` with an HTTPS product photo URL to use real photos. Bundled `assets/` paths are also supported.

## Run

```powershell
flutter pub get
flutter run -t lib/main_supabase.dart
```

`lib/main.dart` opens the original MagiStore app.

## Development

```powershell
flutter analyze
flutter test test/product_browser_test.dart
```

Price filtering and pagination run on Supabase, with eight laptops per page ordered by price and ID. Applying or resetting the price range returns to page one. Refresh reloads products and price bounds. Queries and column mappings are in `lib/product_browser/product_repository.dart` and `product_models.dart`.
