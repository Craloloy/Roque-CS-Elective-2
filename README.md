# MagiStore

A Flutter campus shop for books, study supplies, uniforms, and accessories. Browse by category, search, filter by price, or save items for later. The demo checkout includes bookstore pickup and a claim QR.

## Run

Set your Supabase project URL and client key in `lib/product_browser/supabase_config.dart`.

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 3000
```

MagiStore uses Supabase for email/password and GitHub sign-in. For GitHub, use the Supabase provider callback as the **Authorization callback URL** in your GitHub OAuth App. Enable the provider in Supabase and add `http://localhost:3000/` to the allowed redirect URLs. The existing native callback remains compatible with the previous setup.

The catalog, bag, favorites, and simulated checkout are part of the local demo. Cart and order data are stored on the device per signed-in account. Product prices and quantities are sample values; no payments are processed.
