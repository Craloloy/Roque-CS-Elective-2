class SupabaseConfig {
  // Supabase Dashboard > Project Settings > API.
  static const url = 'https://YOUR-PROJECT.supabase.co';
  // Client publishable key or legacy anon key. Never use a service-role key.
  static const anonKey = 'YOUR-CLIENT-PUBLISHABLE-OR-ANON-KEY';
  static const productsTable = 'products';

  static bool get configured => !url.contains('YOUR-PROJECT') &&
      !anonKey.startsWith('YOUR-') && url.isNotEmpty && anonKey.isNotEmpty;
}
