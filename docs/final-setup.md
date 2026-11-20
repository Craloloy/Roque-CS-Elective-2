# Run MagiStore
The final project opens from `lib/main.dart`. Start in the extracted folder that contains `pubspec.yaml`. The existing Flutter project targets Dart 3.13.1 or later (within Dart 3); check `flutter --version`.

## 1. Set up the database
In your **Roque-CS-Elective-2** Supabase project, open **SQL Editor → New query**. Paste the whole contents of each file and run them **separately, in this order**:

1. `supabase/migrations/001_magistore.sql`: creates the `magistore` schema, tables, policies, functions, signup trigger, and the `magistore-products` image bucket. New and existing Auth users get customer profiles; admin is never taken from signup data. Run once. If a schema or bucket with that name already exists, the transaction stops without replacing it. Inspect the existing installation before retrying.
2. `supabase/migrations/002_catalog.sql`: adds 15 campus products in six categories. The photos for those products are already in the Flutter assets. New photos chosen in the staff form go to Supabase Storage.
3. `supabase/migrations/003_uniform_sizes.sql`: saves PE uniform sizes on order items. If your database already has 001 and 002, run 003 next.
4. `supabase/migrations/004_pickup_notifications.sql`: lets students confirm their own ready orders. Students get ready-to-claim alerts in the app.
5. `supabase/migrations/005_remove_pickup_email.sql`: removes the old pickup email job and queue if the earlier version of 004 was already applied. If you deployed the old `pickup-emails` Edge Function, delete it from the dashboard after running 005. This does not affect signup or sign-in emails.

**Data API → Settings → Exposed schemas:** add `magistore`, keep existing entries, and save. Do not run the previous laptop activity’s scripts in `sql/`. In Table Editor or Schema Visualizer, set the schema dropdown to **magistore**, not **public**. Optionally run `supabase/check_setup.sql` to verify the installation.

The core shop tables are `roles`, `profiles`, `categories`, `products`, `orders`, and `order_items`. The original relationships match the supplied diagram. Two order fields serve the exam: `order_items.product_name` preserves the name after a product is deleted, and `orders.request_id` prevents a repeated checkout request from placing the order twice. Unit prices and totals are decimal pesos. PE uniforms require a size (XS–XL), which is recorded in the bag and on the receipt. Stock is still shared across sizes for each product.

## 2. Enable sign-in
Keep Email enabled in **Authentication → Sign In / Providers**. For Google, create a **Web application** OAuth client in Google Cloud (Google Auth Platform → Clients) and configure its consent screen. If it is in Testing, add your demo Google account as a test user.

If a confirmation email is missing, check the address and confirmation status in **Authentication → Users**, then check **Logs → Auth** for the signup or resend request. The built-in mail sender only delivers to Supabase organization team members and has a low hourly limit. To deliver confirmation emails to classmates or your instructor, configure [custom SMTP](https://supabase.com/docs/guides/auth/auth-smtp) in the project's Auth settings. Never put the mail server password in Flutter. Changing the localhost port changes where the link opens, not whether the email arrives.

| Setting | Local Chrome demo |
| --- | --- |
| Google Cloud → Authorized JavaScript origins | `http://localhost:3000` |
| Google Cloud → Authorized redirect URIs | `https://knxsdsvcfgtodehxbfye.supabase.co/auth/v1/callback` |
| Supabase → Authentication → Sign In / Providers → Google | Enable it, paste the Google client ID and secret, and save. |
| Supabase → Authentication → URL Configuration → Redirect URLs | Add `http://localhost:3000/`. For changing development ports you can allow `http://localhost:*/`. |
| Supabase → Redirect URLs, Android/iOS demo | Add the already registered app link `com.craloloy.apexcomputing://auth-callback/`. |

If the Site URL is already used by another deployment, leave it in place: this app explicitly supplies its return URL. The app takes its web return port from the browser. The Google callback stays the same when the Flutter port changes. For a different Supabase project, use the callback shown in *that* project's Google provider settings; change the Flutter URL and client publishable key in `lib/product_browser/supabase_config.dart` or pass `--dart-define=SUPABASE_URL=...` and `--dart-define=SUPABASE_PUBLISHABLE_KEY=...`. The Google secret belongs only in the provider settings.

## 3. Run on your laptop
In PowerShell, open the project folder in VS Code, then **Terminal → New Terminal**:

```powershell
flutter pub get
flutter analyze
flutter test test/final_shop_test.dart
flutter run -d chrome --web-port=3000
```

Use `flutter test` for the whole project, including the earlier pickup prototype's tests. The first `flutter pub get` resolves the new file picker dependency. Rebuild after changing Dart configuration. Sign up or sign in; if email confirmation is enabled, check your inbox. A normal account sees Products, Bag, and My orders.

## 4. Give only your demo staff account admin access
Create the staff account first. In **Authentication → Users**, copy **its user UUID**. Run the query below in SQL Editor after replacing the placeholder. Using a UUID avoids promoting the wrong person by name.

```sql
update magistore.profiles
set role_id = (select id from magistore.roles where role = 'admin')
where id = 'PASTE-STAFF-USER-UUID'::uuid
returning id, email;
```

Confirm exactly one row came back. Sign out and back in as that account: the catalog shows **Add product** beside its heading. In **Account**, use **Products**, **Manage categories**, or **Manage orders**. Create a separate account for the customer demonstration and leave it as a customer.

## 5. Try the final project
- **Admin:** create an empty category, add a product with a real JPG/PNG/WebP photo (up to 5 MB), then edit its price and stock. Delete asks for confirmation with the product name. Move or delete products before removing their category.
- **Customer:** filter by category, choose **Under ₱500** or **₱500 & up**, or adjust the price range. Add a product twice; you cannot exceed stock. Place the order and compare the confirmation number and total with **My orders**. Sign out and sign in with a different customer; that order should not be visible.
- **Admin:** open **Account → Manage orders** and change an order to **To claim**. In the student account, open the bell, tap the order, and select **Confirm pickup** once the items have been received. Rename or delete the purchased product: the old receipt should still show the original name and price. No status change or product deletion refunds inventory.
- **Notifications:** The bell shows students their ready orders and low or out-of-stock items they saved or put in their bag. Admins see orders waiting to be processed and stock alerts for the whole catalog. Low stock means five units or fewer. Tap an alert to open its order or product.
- **If checkout fails:** the bag stays intact. If stock changed, pull down in the bag to refresh prices and stock, then adjust quantities and retry. If confirmation times out, check My orders before changing the bag. An unchanged retry uses the same request ID.
- **Screenshots for submission:** select `magistore` in Schema Visualizer; capture the table relationships, database functions (`handle_new_user`, `is_admin`, `checkout`), the trigger on `auth.users`, test accounts in Authentication → Users (the `auth.users` table) and their matching `magistore.profiles` rows, and the RLS policies. Share those screenshots with your instructor using the requested Drive folder. Use demo accounts and keep secrets out of screenshots.

Optional database check: in `tool/db-check`, run `npm install` and `npm test` with Node 22 or newer. This runs the migrations and role/checkout tests against an isolated PostgreSQL engine with local Auth and Storage fixtures; it never connects to your project.

## 6. Submit and demonstrate

1. Submit the [GitHub final-exam branch](https://github.com/Craloloy/Roque-CS-Elective-2/tree/final-exam).
2. Put four groups of screenshots in a Drive folder: **Database Schema**, **Database Functions and Trigger**, **Users**, and **RLS Policies**. Capture your own dashboard with the schema set to `magistore`; the setup handout's `public` screenshots are examples. Share the folder with your instructor and submit its link.
3. Before recording or presenting, confirm that email/password and Google both open the same shop, a new account is a customer, and logging out clears the bag. Demo admin product/category changes and an order status update. Then show a customer's complete checkout and verify that a second customer cannot see the first customer's receipt.

If you already cloned the repository, update your copy from its project folder:

```powershell
git switch final-exam
git pull --ff-only origin final-exam
```

Official references: [Supabase custom schemas](https://supabase.com/docs/guides/api/using-custom-schemas) · [Google sign-in](https://supabase.com/docs/guides/auth/social-login/auth-google) · [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls).
