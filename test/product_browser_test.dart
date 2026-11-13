import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ecommerce_app/product_browser/product_controller.dart';
import 'package:flutter_ecommerce_app/product_browser/product_models.dart';
import 'package:flutter_ecommerce_app/product_browser/product_repository.dart';
import 'package:flutter_ecommerce_app/product_browser/product_shop_page.dart';

class FakeRepository implements ProductRepository {
  final calls = <({PriceBand prices, int page})>[];
  final products = List.generate(
    20,
    (i) => ShopProduct(
      id: '${i + 1}',
      name: 'Item ${i + 1}',
      price: (i + 1) * 25.0,
      imageUrl: 'carltronics://laptop/student',
    ),
  );
  Future<ProductPage> Function(PriceBand, int)? handler;
  bool failMutations = false;

  @override
  Future<PriceBand> fetchBounds() async {
    if (products.isEmpty) return const PriceBand(0, 100);
    final prices = products.map((p) => p.price).toList()..sort();
    final low = prices.first.floorToDouble();
    final high = prices.last.ceilToDouble();
    return PriceBand(low < 25 ? low : 0, high > low ? high : low + 1);
  }

  @override
  Future<ProductPage> fetchPage({
    required PriceBand prices,
    required int page,
    String? category,
    String search = '',
  }) async {
    calls.add((prices: prices, page: page));
    if (handler != null) return handler!(prices, page);
    final matches =
        products.where((p) {
            if (p.price < prices.min || p.price > prices.max) return false;
            if (category != null && p.laptopCategory != category) return false;
            if (search.isNotEmpty &&
                !p.name.toLowerCase().contains(search.toLowerCase())) {
              return false;
            }
            return true;
          }).toList()
          ..sort((a, b) {
            final byPrice = a.price.compareTo(b.price);
            return byPrice != 0 ? byPrice : a.id.compareTo(b.id);
          });
    return ProductPage(
      matches.skip((page - 1) * 8).take(8).toList(),
      matches.length,
    );
  }

  @override
  Future<ShopProduct> createProduct({
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    if (failMutations) throw TimeoutException('Mutation timed out');
    final created = ShopProduct(
      id: '${products.length + 100}',
      name: name.trim(),
      price: price,
      imageUrl: imageUrl,
    );
    products.add(created);
    return created;
  }

  @override
  Future<ShopProduct> updateProduct({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    if (failMutations) throw TimeoutException('Mutation timed out');
    final index = products.indexWhere((p) => p.id == id);
    if (index == -1) throw const FormatException('Product not found.');
    final updated = ShopProduct(
      id: id,
      name: name.trim(),
      price: price,
      imageUrl: imageUrl,
    );
    products[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (failMutations) throw TimeoutException('Mutation timed out');
    products.removeWhere((p) => p.id == id);
  }
}

void main() {
  late FakeRepository repository;
  late ProviderContainer container;
  late ProductBrowserController controller;

  setUp(() {
    repository = FakeRepository();
    container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    controller = container.read(productBrowserProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('eight per page, correct totals and final partial page', () async {
    await controller.load();
    expect(container.read(productBrowserProvider).products.length, 8);
    expect(container.read(productBrowserProvider).pageCount, 3);
    await controller.goToPage(2);
    expect(container.read(productBrowserProvider).products.first.id, '9');
    await controller.goToPage(3);
    final state = container.read(productBrowserProvider);
    expect(state.products.length, 4);
    expect(state.firstItem, 17);
    expect(state.lastItem, 20);
    await controller.goToPage(4);
    expect(container.read(productBrowserProvider).page, 3);
  });

  test('price endpoints are included and filtering resets to page one', () async {
    await controller.load();
    await controller.goToPage(3);
    await controller.applyPrices(const PriceBand(100, 200));
    final state = container.read(productBrowserProvider);
    expect(state.page, 1);
    expect(state.total, 5);
    expect(state.products.first.price, 100);
    expect(state.products.last.price, 200);
    expect(repository.calls.last.page, 1);
    await controller.clearPrices();
    expect(container.read(productBrowserProvider).total, 20);
  });

  test('an empty match has zero pages and clearing recovers', () async {
    await controller.load();
    await controller.applyPrices(const PriceBand(1, 2));
    final state = container.read(productBrowserProvider);
    expect(state.products, isEmpty);
    expect(state.total, 0);
    expect(state.pageCount, 0);
    expect(state.firstItem, 0);
    await controller.clearPrices();
    expect(container.read(productBrowserProvider).total, 20);
  });

  test('a stale response cannot replace a newer filter result', () async {
    await controller.load();
    final old = Completer<ProductPage>();
    repository.handler = (prices, page) async =>
        prices.min == 10 ? old.future : const ProductPage([], 0);
    final oldRequest = controller.applyPrices(const PriceBand(10, 50));
    await controller.applyPrices(const PriceBand(100, 200));
    old.complete(ProductPage([repository.products.first], 1));
    await oldRequest;
    expect(container.read(productBrowserProvider).selected.min, 100);
    expect(container.read(productBrowserProvider).products, isEmpty);
  });

  test('error clears busy state and a retry recovers', () async {
    repository.handler = (prices, page) async =>
        throw TimeoutException('Offline');
    await controller.load();
    expect(container.read(productBrowserProvider).loading, false);
    expect(container.read(productBrowserProvider).error, contains('timed out'));
    repository.handler = null;
    await controller.load();
    expect(container.read(productBrowserProvider).error, isNull);
    expect(container.read(productBrowserProvider).total, 20);
  });

  test('deleting the last item on the final page returns to a valid page', () async {
    await controller.load();
    await controller.goToPage(3);
    for (final id in ['17', '18', '19', '20']) {
      final ok = await controller.deleteProduct(id);
      expect(ok, isTrue);
    }
    final state = container.read(productBrowserProvider);
    expect(state.page, 2);
    expect(state.total, 16);
    expect(state.products.length, 8);
  });

  test('updating and creating products refreshes list and price bounds', () async {
    await controller.load();
    final updated = await controller.updateProduct(
      id: '1',
      name: 'Lenovo V14 Upgraded',
      price: 750.0,
      imageUrl: 'carltronics://laptop/gaming',
    );
    expect(updated, isTrue);
    var state = container.read(productBrowserProvider);
    expect(state.bounds.max, 750.0);
    expect(state.selected.max, 750.0);

    final created = await controller.createProduct(
      name: 'ASUS ProArt Studio',
      price: 900.0,
      imageUrl: 'carltronics://laptop/creator',
    );
    expect(created, isTrue);
    state = container.read(productBrowserProvider);
    expect(state.total, 21);
    expect(state.bounds.max, 900.0);
  });

  testWidgets('customers can browse but cannot manage laptops', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProductShopPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.byKey(const Key('addProductButton')), findsNothing);
    expect(find.byKey(const Key('edit_1')), findsNothing);
    expect(find.byKey(const Key('delete_1')), findsNothing);

    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailPage), findsOneWidget);
    expect(find.byTooltip('Edit laptop'), findsNothing);
    expect(find.byTooltip('Delete laptop'), findsNothing);
  });

  testWidgets('phone UI renders cards, edits, deletes, and filters without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: ProductShopPage(canManageCatalog: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Apex Computing'), findsOneWidget);
    expect(find.text('1–8 of 20 laptops'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Open Filter Bottom Sheet from the bottom
    await tester.tap(find.byKey(const Key('openFiltersButton')));
    await tester.pumpAndSettle();
    expect(find.text('Filter by Price'), findsOneWidget);
    await tester.tap(find.byTooltip('Close filters'));
    await tester.pumpAndSettle();

    // Tap Item 1 to navigate to the dedicated ProductDetailPage (next page)
    await tester.tap(find.text('Item 1'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailPage), findsOneWidget);
    expect(find.text('SPECIFICATIONS'), findsOneWidget);
    await tester.tap(find.byTooltip('Back to catalog'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailPage), findsNothing);

    // Edit Item 1 on phone screen
    await tester.tap(find.byKey(const Key('edit_1')));
    await tester.pumpAndSettle();
    expect(find.text('Edit laptop'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('productNameField')),
      'Lenovo V14 Gen 4',
    );
    await tester.enterText(
      find.byKey(const Key('productPriceField')),
      '20.00',
    );
    await tester.tap(find.byKey(const Key('saveProductButton')));
    await tester.pumpAndSettle();

    expect(find.text('Lenovo V14 Gen 4'), findsOneWidget);
    expect(find.text('₱20.00'), findsOneWidget);

    // Delete Item 1 on phone screen
    await tester.tap(find.byKey(const Key('delete_1')));
    await tester.pumpAndSettle();
    expect(find.text('Delete laptop?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirmDeleteButton')));
    await tester.pumpAndSettle();

    expect(find.text('Lenovo V14 Gen 4'), findsNothing);
    expect(find.text('1–8 of 19 laptops'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
