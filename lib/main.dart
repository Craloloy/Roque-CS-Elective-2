import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const FruitApp());

class Fruit {
  const Fruit(this.name, this.emoji, this.description);
  final String name, emoji, description;
}

const fruits = <String, Fruit>{
  'apple': Fruit('Apple', '🍎', 'Crisp, sweet, and refreshing.'),
  'banana': Fruit('Banana', '🍌', 'Soft, sweet, and naturally creamy.'),
  'orange': Fruit('Orange', '🍊', 'Juicy, bright, and full of flavor.'),
  'strawberry': Fruit('Strawberry', '🍓', 'Sweet, colorful, and delicious.'),
  'watermelon': Fruit('Watermelon', '🍉', 'Cool, juicy, and refreshing.'),
  'grapes': Fruit('Grapes', '🍇', 'Small, juicy, and naturally sweet.'),
};

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const FruitListPage(),
      routes: [
        GoRoute(
          path: 'fruit/:name',
          builder: (_, state) {
            final fruit = fruits[state.pathParameters['name']?.toLowerCase()];
            return fruit == null
                ? const FruitNotFoundPage()
                : FruitDetailPage(fruit: fruit);
          },
        ),
      ],
    ),
  ],
);

class FruitApp extends StatelessWidget {
  const FruitApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Fruit Shop',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        routerConfig: router,
      );
}

class FruitListPage extends StatelessWidget {
  const FruitListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Fresh Fruits')),
        body: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: fruits.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, index) {
            final fruit = fruits.values.elementAt(index);
            return Card(
              child: ListTile(
                leading: Text(fruit.emoji, style: const TextStyle(fontSize: 40)),
                title: Text(fruit.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(fruit.description),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/fruit/${fruit.name.toLowerCase()}'),
              ),
            );
          },
        ),
      );
}

class FruitDetailPage extends StatelessWidget {
  const FruitDetailPage({super.key, required this.fruit});
  final Fruit fruit;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(fruit.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: const [BoxShadow(blurRadius: 25, color: Color(0x22000000))],
                ),
                alignment: Alignment.center,
                child: Text(fruit.emoji, style: const TextStyle(fontSize: 150)),
              ),
              const SizedBox(height: 30),
              Text(fruit.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              Text(fruit.description, style: const TextStyle(fontSize: 17)),
              const SizedBox(height: 25),
              FilledButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.storefront),
                label: const Text('Back to fruits'),
              ),
            ],
          ),
        ),
      );
}

class FruitNotFoundPage extends StatelessWidget {
  const FruitNotFoundPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to fruits'),
          ),
        ),
      );
}
