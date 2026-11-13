# Apex Computing

A Flutter laptop storefront with Supabase Auth, catalog management, price filtering, and eight products per page.

## Run locally

Set your Supabase project URL and client publishable or anon key in `lib/product_browser/supabase_config.dart`.

For an empty database, run `sql/optional_demo_setup.sql` in Supabase SQL Editor, followed by `sql/carltronics_sample_products.sql` if you want the demo catalog. For an existing catalog, keep your data. Run `sql/catalog_auth.sql` to restrict catalog writes to approved managers.

```powershell
flutter pub get
flutter run -d chrome --web-hostname localhost --web-port 8080
```

For Android, run `flutter run` with an emulator or device connected. Both entry points open the same storefront.

## GitHub sign-in

1. In Supabase, open **Authentication → Sign In / Providers → GitHub** and copy the callback URL. It looks like `https://<project-ref>.supabase.co/auth/v1/callback`.
2. In [GitHub OAuth Apps](https://github.com/settings/developers), create a **New OAuth App**. Use `http://localhost:8080/` as the homepage URL for this demo and paste the **Supabase callback URL** into **Authorization callback URL**.
3. Generate a client secret. In Supabase, enable GitHub, enter the GitHub **Client ID** and **Client Secret**, and save. The secret belongs in the Supabase dashboard.
4. In **Supabase → Authentication → URL Configuration**, add these **Redirect URLs** for the targets you use:

   - Chrome demo: `http://localhost:8080/`
   - Android or iOS: `com.craloloy.apexcomputing://auth-callback/`

   If you use a deployed site or another port, allow that exact app URL too. For a dedicated local demo project, you can also set the **Site URL** to `http://localhost:8080/`.

The sign-in page also supports email/password registration and login. If email confirmation is enabled, confirm your address before signing in. See the [Supabase GitHub guide](https://supabase.com/docs/guides/auth/social-sign-in/auth-github) for provider setup.

## Catalog manager access

First sign in and find your account's **User UID** in **Supabase → Authentication → Users**. In SQL Editor, replace the placeholder with that UID and run:

```sql
insert into public.apex_catalog_managers (user_id)
values ('REPLACE_WITH_USER_UID'::uuid)
on conflict do nothing;
```

In the app, open **Account → Refresh catalog access**. Managers can add, edit, and delete laptops. Other accounts can browse and filter the catalog.

## Verify

- Sign in with GitHub and confirm that the browser returns to the shop.
- Sign out, then try email registration and sign-in.
- Check that a regular account cannot write to the catalog.
- As a manager, edit a demo laptop and refresh to confirm the change is saved in Supabase.
- Run `flutter analyze` and `flutter test`.
