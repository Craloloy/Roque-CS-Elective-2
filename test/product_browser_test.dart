import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/product_browser/product_controller.dart';
import '../lib/product_browser/product_models.dart';
import '../lib/product_browser/product_repository.dart';

class FakeRepository implements ProductRepository {
  final calls = <({PriceBand prices, int page})>[];
  final products = List.generate(20, (i) => ShopProduct(id: '${i+1}', name: 'Item ${i+1}', price: (i+1)*25.0));
  Future<ProductPage> Function(PriceBand, int)? handler;
  @override
  Future<PriceBand> fetchBounds() async => const PriceBand(0, 500);
  @override
  Future<ProductPage> fetchPage({required PriceBand prices, required int page}) async {
    calls.add((prices: prices, page: page));
    if (handler != null) return handler!(prices, page);
    final matches = products.where((p) => p.price >= prices.min && p.price <= prices.max).toList();
    return ProductPage(matches.skip((page-1)*8).take(8).toList(), matches.length);
  }
}

void main() {
  late FakeRepository repository;
  late ProviderContainer container;
  late ProductBrowserController controller;
  setUp(() {
    repository = FakeRepository();
    container = ProviderContainer(overrides: [productRepositoryProvider.overrideWithValue(repository)]);
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
    repository.handler = (prices, page) async => prices.min == 10
      ? old.future : const ProductPage([], 0);
    final oldRequest = controller.applyPrices(const PriceBand(10, 50));
    await controller.applyPrices(const PriceBand(100, 200));
    old.complete(ProductPage([repository.products.first], 1));
    await oldRequest;
    expect(container.read(productBrowserProvider).selected.min, 100);
    expect(container.read(productBrowserProvider).products, isEmpty);
  });

  test('error clears busy state and a retry recovers', () async {
    repository.handler = (prices, page) async => throw TimeoutException('Offline');
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
    repository.products.removeRange(16, 20);
    await controller.load(reloadBounds: true);
    expect(container.read(productBrowserProvider).page, 2);
    expect(container.read(productBrowserProvider).total, 16);
    expect(container.read(productBrowserProvider).products.length, 8);
  });
}
