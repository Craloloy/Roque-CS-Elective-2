import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const FruitShopApp());

class Fruit {
  const Fruit({
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    this.rating = 4.8,
    this.reviews = 100,
  });

  final String name;
  final double price;
  final String image;
  final String description;
  final double rating;
  final int reviews;
}

const fruits = <String, Fruit>{
  'apple': Fruit(
    name: 'Fresh Apple',
    price: 120,
    image: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?auto=format&fit=crop&w=600&q=85',
    description: 'Crisp, sweet, and freshly picked.',
    rating: 4.9,
    reviews: 128,
  ),
  'banana': Fruit(
    name: 'Premium Banana',
    price: 85,
    image: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=600&q=85',
    description: 'Naturally sweet and creamy.',
    rating: 4.8,
    reviews: 96,
  ),
  'orange': Fruit(
    name: 'Juicy Orange',
    price: 100,
    image: 'https://images.unsplash.com/photo-1547514701-42782101795e?auto=format&fit=crop&w=600&q=85',
    description: 'Bright, juicy, and full of flavor.',
    rating: 4.7,
    reviews: 84,
  ),
  'strawberry': Fruit(
    name: 'Fresh Strawberry',
    price: 180,
    image: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?auto=format&fit=crop&w=600&q=85',
    description: 'Sweet, colorful, and delicious.',
    rating: 4.9,
    reviews: 142,
  ),
  'watermelon': Fruit(
    name: 'Sweet Watermelon',
    price: 75,
    image: 'https://images.unsplash.com/photo-1563114773-84221bd62daa?auto=format&fit=crop&w=600&q=85',
    description: 'Cool, juicy, and refreshing.',
    rating: 4.8,
    reviews: 73,
  ),
  'grapes': Fruit(
    name: 'Seedless Grapes',
    price: 150,
    image: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?auto=format&fit=crop&w=600&q=85',
    description: 'Small, juicy, and naturally sweet.',
    rating: 4.8,
    reviews: 91,
  ),
};

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const ShopHomePage(),
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

class FruitShopApp extends StatelessWidget {
  const FruitShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Freshly',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F9F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF315C35)),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      routerConfig: router,
    );
  }
}

class ShopHomePage extends StatefulWidget {
  const ShopHomePage({super.key});

  @override
  State<ShopHomePage> createState() => _ShopHomePageState();
}

class _ShopHomePageState extends State<ShopHomePage> {
  final searchController = TextEditingController();
  String category = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.toLowerCase();
    final visible = fruits.entries
        .where((e) => e.value.name.toLowerCase().contains(query))
        .toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFDDEBD8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco_rounded, color: Color(0xFF315C35)),
            ),
            const SizedBox(width: 10),
            const Text('freshly', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 23)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Shopping cart',
            onPressed: () {},
            icon: Badge(label: const Text('2'), child: const Icon(Icons.shopping_bag_outlined)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 25),
        children: [
          const Text(
            'Good food starts\nwith fresh fruit.',
            style: TextStyle(fontSize: 29, height: 1.08, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          const Text('Picked fresh. Delivered simply.', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 17),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search fruits...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 17),
          Container(
            height: 112,
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBD8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('FRESH PICK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF315C35), letterSpacing: 1.2)),
                      SizedBox(height: 5),
                      Text('Freshness you\ncan taste.', style: TextStyle(fontSize: 21, height: 1.05, fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    fruits['apple']!.image,
                    width: 95,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 21),
          const Text('Categories', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 9),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Popular', 'Best sellers'].map((item) {
                final selected = category == item;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: selected,
                    onSelected: (_) => setState(() => category = item),
                    showCheckmark: false,
                    selectedColor: const Color(0xFF315C35),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87, fontWeight: FontWeight.w700),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Fresh fruits', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              Text('${visible.length} items', style: const TextStyle(color: Colors.black45, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visible.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
            ),
            itemBuilder: (_, index) {
              final entry = visible[index];
              return FruitCard(slug: entry.key, fruit: entry.value);
            },
          ),
        ],
      ),
      bottomNavigationBar: const NavigationBar(
        height: 66,
        selectedIndex: 0,
        destinations: [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class FruitCard extends StatelessWidget {
  const FruitCard({super.key, required this.slug, required this.fruit});

  final String slug;
  final Fruit fruit;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => context.go('/fruit/$slug'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5ED), borderRadius: BorderRadius.circular(8)),
                    child: const Text('FRESH', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF315C35))),
                  ),
                  const Icon(Icons.favorite_border, size: 19, color: Colors.black38),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: double.infinity,
                      child: Image.network(
                        fruit.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined)),
                      ),
                    ),
                  ),
                ),
              ),
              Text(fruit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFE2A62B)),
                  const SizedBox(width: 2),
                  Text('${fruit.rating}', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('₱${fruit.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: const Color(0xFF315C35), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.add, color: Colors.white, size: 19),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FruitDetailPage extends StatefulWidget {
  const FruitDetailPage({super.key, required this.fruit});

  final Fruit fruit;

  @override
  State<FruitDetailPage> createState() => _FruitDetailPageState();
}

class _FruitDetailPageState extends State<FruitDetailPage> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final total = widget.fruit.price * quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        leading: IconButton(onPressed: () => context.go('/'), icon: const Icon(Icons.arrow_back_rounded)),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.favorite_border_rounded)), const SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(color: const Color(0xFFEAF1E6), borderRadius: BorderRadius.circular(24)),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              widget.fruit.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported_outlined, size: 45)),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFEAF1E6), borderRadius: BorderRadius.circular(8)),
                child: const Text('FRESH PICK', style: TextStyle(color: Color(0xFF315C35), fontSize: 10, fontWeight: FontWeight.w900)),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, size: 18, color: Color(0xFFE2A62B)),
              const SizedBox(width: 3),
              Text('${widget.fruit.rating} (${widget.fruit.reviews})'),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.fruit.name, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text(widget.fruit.description, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          const SizedBox(height: 17),
          Text('₱${widget.fruit.price.toStringAsFixed(0)} / kg', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(child: Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800))),
              IconButton.filledTonal(onPressed: quantity > 1 ? () => setState(() => quantity--) : null, icon: const Icon(Icons.remove, size: 17)),
              SizedBox(width: 42, child: Center(child: Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w800)))),
              IconButton.filledTonal(onPressed: () => setState(() => quantity++), icon: const Icon(Icons.add, size: 17)),
            ],
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: const Row(
              children: [
                Icon(Icons.local_shipping_outlined, color: Color(0xFF315C35)),
                SizedBox(width: 10),
                Expanded(child: Text('Fresh delivery • Same-day preparation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.fruit.name} added to cart!'))),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF315C35),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Add to cart', style: TextStyle(fontWeight: FontWeight.w800)),
                Text('₱${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FruitNotFoundPage extends StatelessWidget {
  const FruitNotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.storefront_rounded),
          label: const Text('Back to shop'),
        ),
      ),
    );
  }
}
