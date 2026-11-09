import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_models.dart';
import 'product_repository.dart';
import 'supabase_config.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) =>
    SupabaseProductRepository(Supabase.instance.client, table: SupabaseConfig.productsTable));

final productBrowserProvider = NotifierProvider<ProductBrowserController, ProductBrowserState>(
    ProductBrowserController.new);

class ProductBrowserController extends Notifier<ProductBrowserState> {
  int _request = 0;

  @override
  ProductBrowserState build() => ProductBrowserState();

  Future<void> load({bool reloadBounds = false}) async {
    final ticket = ++_request;
    final repository = ref.read(productRepositoryProvider);
    state = state.copyWith(loading: true, clearError: true);
    try {
      if (reloadBounds || !state.initialized) {
        final bounds = await repository.fetchBounds();
        if (!ref.mounted || ticket != _request) return;
        final wasAll = !state.initialized ||
            (state.selected.min == state.bounds.min && state.selected.max == state.bounds.max);
        final min = state.selected.min.clamp(bounds.min, bounds.max).toDouble();
        final max = state.selected.max.clamp(bounds.min, bounds.max).toDouble();
        state = state.copyWith(bounds: bounds, initialized: true,
          selected: wasAll ? bounds : PriceBand(min, max));
      }
      final prices = state.selected;
      var requestedPage = state.page;
      var result = await repository.fetchPage(prices: prices, page: requestedPage);
      if (!ref.mounted || ticket != _request) return;
      // A deletion can remove the last row on the final page.
      final lastPage = result.total == 0 ? 1 : (result.total / ProductBrowserState.pageSize).ceil();
      if (requestedPage > lastPage) {
        requestedPage = lastPage;
        result = await repository.fetchPage(prices: prices, page: requestedPage);
        if (!ref.mounted || ticket != _request) return;
      }
      state = state.copyWith(products: result.items, total: result.total,
        page: requestedPage, loading: false, clearError: true);
    } catch (error) {
      if (!ref.mounted || ticket != _request) return;
      final message = switch (error) {
        TimeoutException() => 'The request timed out. Check your connection and try again.',
        PostgrestException() => 'Supabase could not load products: ${error.message}',
        FormatException() => error.message,
        _ => 'Unable to load products. Check your connection and Supabase settings.',
      };
      // Do not leave old-page items visible under a new page/filter label.
      state = state.copyWith(products: [], total: 0, loading: false, error: message);
    }
  }

  Future<void> applyPrices(PriceBand prices) async {
    if (!state.initialized || !prices.min.isFinite || !prices.max.isFinite || prices.min > prices.max) return;
    state = state.copyWith(
      selected: PriceBand(prices.min.clamp(state.bounds.min, state.bounds.max).toDouble(),
        prices.max.clamp(state.bounds.min, state.bounds.max).toDouble()),
      page: 1, products: [], total: 0);
    await load();
  }

  Future<void> clearPrices() => applyPrices(state.bounds);

  Future<void> goToPage(int page) async {
    if (!state.initialized || page < 1 || page > state.pageCount || page == state.page) return;
    state = state.copyWith(page: page, products: []);
    await load();
  }
}
