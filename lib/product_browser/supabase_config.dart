class SupabaseConfig {
  // Supabase Dashboard > Project Settings > API.
  static const url = 'https://knxsdsvcfgtodehxbfye.supabase.co';
  // Client publishable key or legacy anon key. Never use a service-role key.
  static const anonKey = 'sb_publishable_wRG2sg4a-dzT56RCOt-6jg_LOHeToEc';
  static const productsTable = 'products';

  static bool get configured =>
      !url.contains('YOUR-PROJECT') &&
      !anonKey.startsWith('YOUR-') &&
      url.isNotEmpty &&
      anonKey.isNotEmpty;
}
