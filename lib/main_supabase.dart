import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_browser/product_shop_page.dart';
import 'product_browser/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!SupabaseConfig.configured) {
    runApp(const MaterialApp(home: Scaffold(body: Center(child: Padding(
      padding: EdgeInsets.all(24), child: Text(
        'Add your Supabase URL and client key in lib/product_browser/supabase_config.dart, then restart the app.'))))));
    return;
  }
  // anonKey is accepted by Supabase Flutter 2.x and supports legacy anon
  // or client publishable keys. Never pass a service-role key here.
  await Supabase.initialize(url: SupabaseConfig.url, anonKey: SupabaseConfig.anonKey);
  runApp(const ProviderScope(child: ProductBrowserExample()));
}

class ProductBrowserExample extends StatelessWidget {
  const ProductBrowserExample({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Campus Shop', debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)), useMaterial3: true),
    home: const ProductShopPage());
}
