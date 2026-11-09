# Apex Computing

A mobile-first Flutter laptop & workstation storefront for office work, studying, gaming, and creative work. Includes real product photos, Supabase-backed create/edit/delete product actions, a bottom-sheet price range filter, 8-item-per-page Supabase pagination, and Riverpod state management.

## Setup

Add your Supabase project URL and client publishable/anon key in `lib/product_browser/supabase_config.dart`.

The `products` table uses `id`, `name`, numeric `price`, and nullable `image_url`. For a new database, run `sql/optional_demo_setup.sql` in Supabase SQL Editor. Then run `sql/carltronics_sample_products.sql` to enable CRUD Row Level Security policies and seed 20 sample laptops.

The seed removes unchanged merchandise and numbered placeholders from the previous demo. Other existing products remain. Running it again skips laptop names already present. Prices are demo values, not current retail quotes.

Demo laptops use generic built-in illustrations via `carltronics://laptop/office`, `student`, `ultrabook`, `gaming`, or `creator`. Replace `image_url` with an HTTPS product photo URL to use real photos. Bundled `assets/` paths are also supported.

## Run

```powershell
flutter pub get
flutter run
```

Both `lib/main.dart` and `lib/main_supabase.dart` launch the Carltronics storefront.

## Development

```powershell
flutter analyze
flutter test
```

Price filtering, pagination, and product create/update/delete run on Supabase, with eight laptops per page ordered by price and ID. Applying or resetting the price range returns to page one. Editing, adding, or deleting a laptop refreshes the product list and price bounds from Supabase. Queries and column mappings are in `lib/product_browser/product_repository.dart` and `lib/product_browser/product_models.dart`.
