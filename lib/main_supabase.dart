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
    title: 'Carl Shop', debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF673AB7)),
      scaffoldBackgroundColor: const Color(0xFFF7F5FA),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAF8FD),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE6E1ED))),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ),
    home: const ProductShopPage());
}
