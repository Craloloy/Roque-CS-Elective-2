import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShopAppearance extends StatefulWidget {
  const ShopAppearance({super.key, required this.child});
  final Widget child;

  static ValueNotifier<ThemeMode>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AppearanceScope>()?.notifier;

  @override
  State<ShopAppearance> createState() => _ShopAppearanceState();
}

class _ShopAppearanceState extends State<ShopAppearance> {
  final mode = ValueNotifier(ThemeMode.system);
  static const preference = 'magistore.appearance';

  @override
  void initState() {
    super.initState();
    mode.addListener(save);
    restore();
  }

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted || mode.value != ThemeMode.system) return;
      mode.value = switch (prefs.getString(preference)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // The theme still works when browser storage is unavailable.
    }
  }

  Future<void> save() async {
    final value = mode.value.name;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preference, value);
    } catch (_) {
      // Keep the theme choice for this visit.
    }
  }

  @override
  void dispose() {
    mode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AppearanceScope(notifier: mode, child: widget.child);
}

class _AppearanceScope extends InheritedNotifier<ValueNotifier<ThemeMode>> {
  const _AppearanceScope({required super.notifier, required super.child});
}

class ShopThemeToggle extends StatelessWidget {
  const ShopThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = ShopAppearance.of(context);
    if (mode == null) return const SizedBox.shrink();
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Switch to light mode' : 'Switch to dark mode',
      onPressed: () => mode.value = dark ? ThemeMode.light : ThemeMode.dark,
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
