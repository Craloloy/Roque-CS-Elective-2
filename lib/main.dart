import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() => runApp(const FreshCartApp());

class Fruit {
  const Fruit({
    required this.name,
    required this.emoji,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  final String name;
  final String emoji;
  final String description;
  final double price;
  final String category;
  final String imageUrl;
}

const fruits = <String, Fruit>{
  'apple': Fruit(
    name: 'Honeycrisp Apple',
    emoji: '🍎',
    description: 'Crisp, juicy, and naturally sweet.',
    price: 89,
    category: 'Fruits',
    imageUrl: 'https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=900&q=85',
  ),
  'banana': Fruit(
    name: 'Premium Banana',
    emoji: '🍌',
    description: 'Creamy, sweet, and ready to enjoy.',
    price: 69,
    category: 'Fruits',
    imageUrl: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=900&q=85',
  ),
  'orange': Fruit(
    name: 'Valencia Orange',
    emoji: '🍊',
    description: 'Bright, juicy, and bursting with citrus.',
    price: 99,
    category: 'Citrus',
    imageUrl: 'https://images.unsplash.com/photo-1547514701-42782101795e?w=900&q=85',
  ),
  'strawberry': Fruit(
    name: 'Fresh Strawberries',
    emoji: '🍓',
    description: 'Sweet, fragrant, and picked at peak ripeness.',
    price: 149,
    category: 'Berries',
    imageUrl: 'https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=900&q=85',
  ),
  'watermelon': Fruit(
    name: 'Seedless Watermelon',
    emoji: '🍉',
    description: 'Cool, refreshing, and perfect for sharing.',
    price: 199,
    category: 'Fruits',
    imageUrl: 'https://images.unsplash.com/photo-1563114773-84221bd62daa?w=900&q=85',
  ),
  'grapes': Fruit(
    name: 'Sweet Green Grapes',
    emoji: '🍇',
    description: 'Crunchy, juicy, and naturally sweet.',
    price: 129,
    category: 'Berries',
    imageUrl: 'https://images.unsplash.com/photo-1537640538966-79f369143f8f?w=900&q=85',
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

class FreshCartApp extends StatelessWidget {
  const FreshCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'FreshCart',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF176B45),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
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
  String selectedCategory = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, Fruit>> get visibleFruits {
    final query = searchController.text.trim().toLowerCase();
    return fruits.entries.where((entry) {
      final matchesSearch = query.isEmpty ||
          entry.value.name.toLowerCase().contains(query) ||
          entry.value.category.toLowerCase().contains(query);
      final matchesCategory = selectedCategory == 'All' ||
          entry.value.category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Shop'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Wishlist'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHero()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 30),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    const Text('Popular picks', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('${visibleFruits.length} items', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 16,
                  childAspectRatio: .70,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, index) {
                    final entry = visibleFruits[index];
                    return FruitCard(slug: entry.key, fruit: entry.value);
                  },
                  childCount: visibleFruits.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF176B45),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FreshCart', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('Freshness delivered', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
              const Spacer(),
              Badge(
                label: const Text('2'),
                child: IconButton.filledTonal(
                  onPressed: () {},
                  icon: const Icon(Icons.shopping_bag_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search fruits, berries, citrus...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF176B45), Color(0xFF2C9B62)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x22176B45), blurRadius: 20, offset: Offset(0, 10))],
        ),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Farm fresh.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  Text('Delivered happy.', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  SizedBox(height: 8),
                  Text('Get 20% off your first order', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
            const Text('🍓', style: TextStyle(fontSize: 68)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    const categories = ['All', 'Fruits', 'Citrus', 'Berries'];
    return SizedBox(
      height: 58,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (_, index) {
          final category = categories[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => selectedCategory = category),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : Colors.black87,
            ),
            selectedColor: const Color(0xFF176B45),
            backgroundColor: Colors.white,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          );
        },
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/fruit/$slug'),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          fruit.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFEAF2E9),
                            alignment: Alignment.center,
                            child: Text(fruit.emoji, style: const TextStyle(fontSize: 70)),
                          ),
                          loadingBuilder: (_, child, progress) => progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFFEAF2E9),
                                  alignment: Alignment.center,
                                  child: Text(fruit.emoji, style: const TextStyle(fontSize: 64)),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withOpacity(.92),
                        child: const Icon(Icons.favorite_border, size: 19),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(fruit.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(fruit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              Text('₱${fruit.price.toStringAsFixed(0)} / pack', style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 9),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF4B740)),
                  const SizedBox(width: 3),
                  const Text('4.9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF176B45),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white),
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
    final fruit = widget.fruit;
    final total = fruit.price * quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton.filledTonal(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Product details', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.shopping_bag_outlined)),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total', style: TextStyle(color: Colors.black54, fontSize: 12)),
                    Text('₱${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${fruit.name} added to your cart')),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Add to cart'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16)),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        children: [
          Hero(
            tag: fruit.name,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: AspectRatio(
                aspectRatio: 1.1,
                child: Image.network(
                  fruit.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: const Color(0xFFEAF2E9),
                    alignment: Alignment.center,
                    child: Text(fruit.emoji, style: const TextStyle(fontSize: 150)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFE8F3EC), borderRadius: BorderRadius.circular(10)),
                child: Text(fruit.category, style: const TextStyle(color: Color(0xFF176B45), fontWeight: FontWeight.w800, fontSize: 12)),
              ),
              const Spacer(),
              const Icon(Icons.star_rounded, color: Color(0xFFF4B740), size: 19),
              const SizedBox(width: 3),
              const Text('4.9  •  128 reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Text(fruit.name, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('₱${fruit.price.toStringAsFixed(0)} / pack', style: const TextStyle(fontSize: 20, color: Color(0xFF176B45), fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Text(fruit.description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black54)),
          const SizedBox(height: 22),
          const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton.filledTonal(
                onPressed: quantity == 1 ? null : () => setState(() => quantity--),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(width: 48, child: Text('$quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              IconButton.filledTonal(
                onPressed: () => setState(() => quantity++),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Why you’ll love it', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Benefit(icon: Icons.local_shipping_outlined, title: 'Fast delivery', subtitle: 'Same-day available'),
              SizedBox(width: 10),
              _Benefit(icon: Icons.eco_outlined, title: 'Farm fresh', subtitle: 'Picked with care'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF7F8F4), borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF176B45)),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)), Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.black54))])),
          ],
        ),
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
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Back to shop'),
        ),
      ),
    );
  }
}
