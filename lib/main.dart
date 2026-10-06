import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'providers/pokemon_provider.dart';
import 'screens/pokedex_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => PokemonProvider()..fetchPokemon(),
    child: const PokedexApp(),
  ));
}

class PokedexApp extends StatelessWidget {
  const PokedexApp({super.key});

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
      themeMode: context.watch<PokemonProvider>().themeMode,
      home: const PokedexScreen(),
    );
  }
}
