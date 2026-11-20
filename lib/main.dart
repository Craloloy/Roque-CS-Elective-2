import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shop/services/shop_service.dart';
import 'shop/providers/shop_providers.dart';
import 'shop/pages/app.dart';
import 'shop/pages/appearance.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopAppearance(child: Bootstrap()));
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<ShopService> connection = ShopService.connect();
  @override
  Widget build(BuildContext c) => FutureBuilder(
    future: connection,
    builder: (c, s) {
      if (s.hasData) {
        return ProviderScope(
          overrides: [serviceProvider.overrideWithValue(s.data!)],
          child: const SessionGate(),
        );
      }
      return shell(
        Scaffold(
          body: Center(
            child: s.hasError
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(shopMessage(s.error!)),
                        TextButton(
                          onPressed: () => setState(
                            () => connection = ShopService.connect(),
                          ),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}
