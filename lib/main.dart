import 'package:flutter/material.dart';

import 'screens/pokedex_screen.dart';

void main() {
  runApp(const PokedexApp());
}

class PokedexApp extends StatefulWidget {
  const PokedexApp({super.key});

  @override
  State<PokedexApp> createState() => _PokedexAppState();
}

class _PokedexAppState extends State<PokedexApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        fontFamily: 'VT323',
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        fontFamily: 'VT323',
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: PokedexScreen(
        onThemeChanged: (dark) => setState(() {
          _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
        }),
      ),
    );
  }
}
