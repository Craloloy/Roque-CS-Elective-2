# Carl Shop

A violet and lavender Flutter storefront with a left price filter, Supabase pagination, and Riverpod state management. On smaller screens, the filter opens in a left drawer.

## Setup

Add your Supabase project URL and client publishable/anon key in `lib/product_browser/supabase_config.dart`.

The `products` table uses `id`, `name`, numeric `price`, and nullable `image_url`. For a new database, run `sql/optional_demo_setup.sql` in Supabase SQL Editor. To add the pictured sample products, run `sql/carl_shop_sample_products.sql`. It keeps existing products and skips sample names already present.

Images can use HTTPS URLs or bundled `assets/` paths. Product queries and column mappings are in `lib/product_browser/product_repository.dart` and `product_models.dart`.

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

Filtering and pagination run on Supabase, with eight products per page ordered by price and ID. Applying or resetting the price range returns to page one. Refresh reloads products and price bounds.
