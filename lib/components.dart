import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'store.dart';
import 'theme.dart';

void toast(
  BuildContext context,
  String message, {
  IconData icon = Icons.info_outline_rounded,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 2000),
}) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      dismissDirection: DismissDirection.horizontal,
      content: Row(
        children: [
          Icon(icon, color: Brand.gold, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel == null
          ? null
          : SnackBarAction(
              label: actionLabel,
              textColor: Brand.gold,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onAction?.call();
              },
            ),
      duration: duration,
    ),
  );
}

class AppFrame extends StatelessWidget {
  final Store store;
  final Widget child;
  final String active;
  final GlobalKey? bagKey;
  const AppFrame({
    super.key,
    required this.store,
    required this.child,
    this.active = 'Shop',
    this.bagKey,
  });
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: wide ? 40 : 16,
        title: InkWell(
          onTap: () => context.go('/'),
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/branding/addu-seal.jpg',
                  width: 42,
                  height: 42,
                  fit: BoxFit.contain,
                  semanticLabel: 'Ateneo de Davao University seal',
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MagiStore',
                    style: TextStyle(
                      fontSize: wide ? 23 : 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.8,
                    ),
                  ),
                  if (wide)
                    const Text(
                      'ATENEO DE DAVAO UNIVERSITY',
                      style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 1.8,
                        color: Brand.muted,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (wide) ...[
            _nav(context, 'Shop', '/'),
            _nav(context, 'My orders', '/orders'),
            _nav(
              context,
              'Notifications',
              '/notifications',
              badgeCount: store.readyOrdersCount,
            ),
            const SizedBox(width: 22),
          ],
          if (!wide)
            IconButton(
              tooltip: 'Order notifications',
              onPressed: () => context.go('/notifications'),
              icon: Badge(
                isLabelVisible: store.readyOrdersCount > 0,
                label: Text('${store.readyOrdersCount}'),
                backgroundColor: Colors.teal.shade600,
                textColor: Brand.white,
                child: Icon(
                  active == 'Notifications' || active == 'Alerts'
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  size: 21,
                  color: active == 'Notifications' || active == 'Alerts'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Toggle light / dark mode',
            onPressed: store.toggleTheme,
            icon: Icon(
              store.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 21,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: wide ? 36 : 12),
            child: IconButton(
              key: bagKey,
              tooltip: 'Shopping bag',
              onPressed: () => context.go('/cart'),
              icon: TweenAnimationBuilder<double>(
                key: ValueKey(store.count),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(
                  milliseconds: MediaQuery.disableAnimationsOf(context)
                      ? 0
                      : 250,
                ),
                builder: (context, value, child) => Transform.scale(
                  scale: 1 + .2 * (1 - (value * 2 - 1).abs()),
                  child: child,
                ),
                child: Badge(
                  isLabelVisible: store.count > 0,
                  label: Text('${store.count}'),
                  backgroundColor: Brand.gold,
                  textColor: Brand.navy,
                  child: const Icon(Icons.shopping_bag_outlined, size: 23),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (store.persistenceError != null)
            MaterialBanner(
              content: Text(store.persistenceError!),
              actions: [
                TextButton(
                  onPressed: () {
                    store.persistenceError = null;
                    store.changed();
                  },
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF142436) : Brand.white,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0xFF243B52).withValues(alpha: 0.6)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 60,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return IconThemeData(
                      size: 22,
                      color: selected
                          ? (isDark ? Brand.gold : Brand.blue)
                          : (isDark
                              ? const Color(0xFF8A99A8)
                              : const Color(0xFF64748B)),
                    );
                  }),
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);
                    return TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.15,
                      color: selected
                          ? (isDark ? Brand.gold : Brand.blue)
                          : (isDark
                              ? const Color(0xFF8A99A8)
                              : const Color(0xFF64748B)),
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 60,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  selectedIndex: active == 'My orders'
                      ? 1
                      : ((active == 'Notifications' || active == 'Alerts') ? 2 : 0),
                  onDestinationSelected: (i) =>
                      context.go(['/', '/orders', '/notifications'][i]),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.storefront_outlined),
                      selectedIcon: Icon(Icons.storefront),
                      label: 'Shop',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.confirmation_number_outlined),
                      selectedIcon: Icon(Icons.confirmation_number),
                      label: 'My orders',
                    ),
                    NavigationDestination(
                      icon: Badge(
                        isLabelVisible: store.readyOrdersCount > 0,
                        label: Text(
                          '${store.readyOrdersCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor:
                            isDark ? Brand.gold : const Color(0xFF0D9488),
                        textColor: isDark ? Brand.navy : Brand.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: store.readyOrdersCount > 0,
                        label: Text(
                          '${store.readyOrdersCount}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor:
                            isDark ? Brand.gold : const Color(0xFF0D9488),
                        textColor: isDark ? Brand.navy : Brand.white,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: const Icon(Icons.notifications),
                      ),
                      label: 'Alerts',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _nav(
    BuildContext context,
    String title,
    String path, {
    int badgeCount = 0,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: TextButton(
      onPressed: () => context.go(path),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: active == title ? FontWeight.w800 : FontWeight.w500,
              color: active == title
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (badgeCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.teal.shade600,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final double maxWidth;
  const PageBody({super.key, required this.children, this.maxWidth = 1240});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 18 : 36,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class StockBadge extends StatelessWidget {
  final int stock;
  final bool reserve;
  const StockBadge({super.key, required this.stock, this.reserve = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = reserve || stock == 0
        ? (isDark ? const Color(0xFFD8B4FE) : Brand.purple)
        : stock <= 5
        ? (isDark ? const Color(0xFFFDBA74) : Brand.orange)
        : (isDark ? const Color(0xFF4ADE80) : Brand.green);
    final label = reserve || stock == 0
        ? 'For reservation'
        : stock <= 5
        ? 'Only $stock left'
        : 'In stock';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? .18 : .10),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: isDark ? .35 : 0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 5, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  final Product product;
  final double? height;
  const ProductImage({super.key, required this.product, this.height});
  @override
  Widget build(BuildContext context) => Image.asset(
    product.image,
    height: height,
    fit: BoxFit.contain,
    semanticLabel: '${product.name}, concept merchandise artwork',
    errorBuilder: (_, _, _) => SizedBox(
      height: height ?? 100,
      child: const Center(child: Icon(Icons.image_not_supported_outlined)),
    ),
  );
}

class SectionHeading extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;
  const SectionHeading(this.title, this.subtitle, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 7),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String title, message;
  final IconData icon;
  final VoidCallback? onAction;
  final String action;
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.shopping_bag_outlined,
    this.onAction,
    this.action = 'Explore essentials',
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 54, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 20),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          FilledButton(
            onPressed: onAction ?? () => context.go('/'),
            child: Text(action),
          ),
        ],
      ),
    ),
  );
}

class InfoBox extends StatelessWidget {
  final String text;
  final IconData icon;
  const InfoBox(this.text, {super.key, this.icon = Icons.info_outline});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF16273A)
            : Theme.of(context).colorScheme.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF263C52)
              : Theme.of(context).colorScheme.primary.withValues(alpha: .12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFFCBD7E6) : null,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityControl extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const QuantityControl({
    super.key,
    required this.value,
    required this.onChanged,
  });
  @override
  State<QuantityControl> createState() => _QuantityControlState();
}

class _QuantityControlState extends State<QuantityControl> {
  // Tracks interaction focus locally; the repository owns the authoritative quantity.
  bool focused = false;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Focus(
      onFocusChange: (v) => setState(() => focused = v),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16273A) : Colors.transparent,
          border: Border.all(
            color: focused
                ? Theme.of(context).colorScheme.primary
                : (isDark ? const Color(0xFF2B445E) : Theme.of(context).dividerColor),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Decrease quantity',
              visualDensity: VisualDensity.compact,
              color: isDark ? const Color(0xFFD4E3F3) : null,
              onPressed: () => widget.onChanged(widget.value - 1),
              icon: const Icon(Icons.remove, size: 17),
            ),
            SizedBox(
              width: 25,
              child: Text(
                '${widget.value}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE6EDF5) : null,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Increase quantity',
              visualDensity: VisualDensity.compact,
              color: isDark ? const Color(0xFFD4E3F3) : null,
              onPressed: () => widget.onChanged(widget.value + 1),
              icon: const Icon(Icons.add, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}
