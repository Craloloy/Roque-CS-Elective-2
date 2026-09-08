import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog_screen.dart';
import 'checkout_screen.dart';
import 'components.dart';
import 'notifications_screen.dart';
import 'order_screen.dart';
import 'product_screen.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    /* In-memory fallback. */
  }
  final store = Store(prefs: prefs);
  if (prefs == null) {
    store.persistenceError =
        'Local storage unavailable. Your saved data lasts for this session.';
  }
  runApp(MagisApp(store: store));
}

class MagisApp extends StatefulWidget {
  final Store store;
  final String initialLocation;
  const MagisApp({super.key, required this.store, this.initialLocation = '/'});
  @override
  State<MagisApp> createState() => _MagisAppState();
}

class _MagisAppState extends State<MagisApp> {
  late final GoRouter router;
  @override
  void initState() {
    super.initState();
    router = GoRouter(
      initialLocation: widget.initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => reactive(() => CatalogScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/product/:id',
          builder: (_, state) {
            final products = catalog.where(
              (p) => p.active && p.id == state.pathParameters['id'],
            );
            return products.isEmpty
                ? missing()
                : reactive(
                    () => ProductScreen(
                      key: ValueKey(products.first.id),
                      store: widget.store,
                      product: products.first,
                    ),
                  );
          },
        ),
        GoRoute(
          path: '/cart',
          builder: (_, _) => reactive(() => CartScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/checkout',
          builder: (_, _) =>
              reactive(() => CheckoutScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/orders',
          builder: (_, _) => reactive(() => OrdersScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, _) =>
              reactive(() => NotificationsScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/alerts',
          builder: (_, _) =>
              reactive(() => NotificationsScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/alert',
          builder: (_, _) =>
              reactive(() => NotificationsScreen(store: widget.store)),
        ),
        GoRoute(
          path: '/orders/:id',
          builder: (_, state) {
            final order = widget.store.order(state.pathParameters['id']!);
            return order == null
                ? missing()
                : reactive(
                    () => OrderScreen(
                      key: ValueKey(order.id),
                      store: widget.store,
                      order: order,
                    ),
                  );
          },
        ),
      ],
      errorBuilder: (context, state) {
        final path = state.uri.path.toLowerCase();
        if (path.contains('alert') || path.contains('notif')) {
          return reactive(() => NotificationsScreen(store: widget.store));
        }
        if (path.startsWith('/order')) {
          return reactive(() => OrdersScreen(store: widget.store));
        }
        return missing();
      },
    );
  }

  Widget reactive(Widget Function() build) =>
      ListenableBuilder(listenable: widget.store, builder: (_, _) => build());
  Widget missing() => AppFrame(
    store: widget.store,
    child: const EmptyState(
      title: 'This page isn’t here',
      message: 'The product or saved order could not be found.',
      icon: Icons.explore_off_outlined,
    ),
  );
  @override
  void dispose() {
    router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) => MaterialApp.router(
      title: 'MagiStore · Your campus essentials',
      debugShowCheckedModeBanner: false,
      theme: Brand.theme(Brightness.light),
      darkTheme: Brand.theme(Brightness.dark),
      themeMode: widget.store.dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    ),
  );
}
