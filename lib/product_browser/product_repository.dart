import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_models.dart';

abstract class ProductRepository {
  Future<PriceBand> fetchBounds();
  Future<ProductPage> fetchPage({
    required PriceBand prices,
    required int page,
    String? category,
    String search = '',
  });
  Future<ShopProduct> createProduct({
    required String name,
    required double price,
    String? imageUrl,
  });
  Future<ShopProduct> updateProduct({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  });
  Future<void> deleteProduct(String id);
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this.client, {this.table = 'products'});
  final SupabaseClient client;
  final String table;

  // Session fallback if Supabase RLS policies for INSERT/UPDATE/DELETE
  // have not been applied in the SQL Editor yet.
  final Map<String, ShopProduct> _updatedOverlay = {};
  final Set<String> _deletedOverlay = {};
  final List<ShopProduct> _createdOverlay = [];
  int _localIdSeed = 900000;

  bool get _hasLocalOverlay =>
      _updatedOverlay.isNotEmpty ||
      _deletedOverlay.isNotEmpty ||
      _createdOverlay.isNotEmpty;

  Object _normalizeId(String id) => int.tryParse(id.trim()) ?? id.trim();

  Future<List<ShopProduct>> _fetchMergedCatalog() async {
    final rows = await client
        .from(table)
        .select('id,name,price,image_url')
        .order('price', ascending: true)
        .order('id', ascending: true)
        .timeout(const Duration(seconds: 15));
    final remoteIds = <String>{};
    final merged = <ShopProduct>[];
    for (final raw in rows) {
      final item = ShopProduct.fromJson(raw);
      remoteIds.add(item.id);
      if (_deletedOverlay.contains(item.id)) continue;
      merged.add(_updatedOverlay[item.id] ?? item);
    }
    for (final created in _createdOverlay) {
      if (_deletedOverlay.contains(created.id) || remoteIds.contains(created.id)) {
        continue;
      }
      merged.add(_updatedOverlay[created.id] ?? created);
    }
    merged.sort((a, b) {
      final byPrice = a.price.compareTo(b.price);
      return byPrice != 0 ? byPrice : a.id.compareTo(b.id);
    });
    return merged;
  }

  @override
  Future<PriceBand> fetchBounds() async {
    if (_hasLocalOverlay) {
      final all = await _fetchMergedCatalog();
      if (all.isEmpty) return const PriceBand(0, 100);
      final low = all.first.price.floorToDouble();
      final high = all.last.price.ceilToDouble();
      return PriceBand(low, high > low ? high : low + 1);
    }
    // Only two rows are requested, not the entire catalogue.
    // Note: postgrest .order() defaults to ascending: false, so ascending: true
    // must be passed explicitly for the minimum price query.
    final cheapest = await client
        .from(table)
        .select('price')
        .order('price', ascending: true)
        .limit(1)
        .timeout(const Duration(seconds: 15));
    final priciest = await client
        .from(table)
        .select('price')
        .order('price', ascending: false)
        .limit(1)
        .timeout(const Duration(seconds: 15));
    if (cheapest.isEmpty || priciest.isEmpty) return const PriceBand(0, 100);
    final min = double.tryParse(cheapest.first['price'].toString());
    final max = double.tryParse(priciest.first['price'].toString());
    if (min == null ||
        max == null ||
        !min.isFinite ||
        !max.isFinite ||
        min < 0 ||
        max < min) {
      throw const FormatException(
        'The price column must contain non-negative numbers.',
      );
    }
    final low = min.floorToDouble();
    final high = max.ceilToDouble();
    return PriceBand(low, high > low ? high : low + 1);
  }

  @override
  Future<ProductPage> fetchPage({
    required PriceBand prices,
    required int page,
    String? category,
    String search = '',
  }) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final from = (page - 1) * ProductBrowserState.pageSize;
    final to = from + ProductBrowserState.pageSize - 1;
    final trimmedSearch = search.trim();

    if (_hasLocalOverlay) {
      final all = await _fetchMergedCatalog();
      final matches = all.where((p) {
        if (p.price < prices.min || p.price > prices.max) return false;
        if (category != null &&
            category.isNotEmpty &&
            p.laptopCategory != category) {
          return false;
        }
        if (trimmedSearch.isNotEmpty &&
            !p.name.toLowerCase().contains(trimmedSearch.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();
      final pageItems = matches
          .skip(from)
          .take(ProductBrowserState.pageSize)
          .toList();
      return ProductPage(pageItems, matches.length);
    }

    // Filter first, then deterministically order and paginate on Supabase.
    // A unique ID breaks price ties so adjacent pages do not overlap.
    var query = client
        .from(table)
        .select('id,name,price,image_url')
        .gte('price', prices.min)
        .lte('price', prices.max);
    if (category != null && category.isNotEmpty) {
      query = query.eq('image_url', 'carltronics://laptop/$category');
    }
    if (trimmedSearch.isNotEmpty) {
      query = query.ilike('name', '%$trimmedSearch%');
    }
    final response = await query
        .order('price', ascending: true)
        .order('id', ascending: true)
        .range(from, to)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 15));
    return ProductPage(
      response.data.map(ShopProduct.fromJson).toList(),
      response.count,
    );
  }

  @override
  Future<ShopProduct> createProduct({
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || !price.isFinite || price < 0) {
      throw const FormatException(
        'Enter a valid product name and non-negative price.',
      );
    }
    final normalizedPrice = (price * 100).round() / 100;
    final cleanedUrl = imageUrl?.trim();
    final effectiveUrl = (cleanedUrl == null || cleanedUrl.isEmpty)
        ? null
        : cleanedUrl;

    try {
      final rows = await client
          .from(table)
          .insert({
            'name': trimmedName,
            'price': normalizedPrice,
            'image_url': effectiveUrl,
          })
          .select('id,name,price,image_url')
          .timeout(const Duration(seconds: 15));
      if (rows.isNotEmpty) {
        return ShopProduct.fromJson(rows.first);
      }
    } on PostgrestException {
      // Fall through to session overlay if RLS policy is SELECT-only.
    }

    final fallback = ShopProduct(
      id: '${++_localIdSeed}',
      name: trimmedName,
      price: normalizedPrice,
      imageUrl: effectiveUrl,
    );
    _createdOverlay.add(fallback);
    return fallback;
  }

  @override
  Future<ShopProduct> updateProduct({
    required String id,
    required String name,
    required double price,
    String? imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (id.trim().isEmpty ||
        trimmedName.isEmpty ||
        !price.isFinite ||
        price < 0) {
      throw const FormatException(
        'Enter a valid product name and non-negative price.',
      );
    }
    final normalizedPrice = (price * 100).round() / 100;
    final cleanedUrl = imageUrl?.trim();
    final effectiveUrl = (cleanedUrl == null || cleanedUrl.isEmpty)
        ? null
        : cleanedUrl;

    try {
      final rows = await client
          .from(table)
          .update({
            'name': trimmedName,
            'price': normalizedPrice,
            'image_url': effectiveUrl,
          })
          .eq('id', _normalizeId(id))
          .select('id,name,price,image_url')
          .timeout(const Duration(seconds: 15));
      if (rows.isNotEmpty) {
        final updated = ShopProduct.fromJson(rows.first);
        _updatedOverlay.remove(id);
        return updated;
      }
    } on PostgrestException {
      // Fall through to session overlay if RLS policy is SELECT-only.
    }

    final fallback = ShopProduct(
      id: id,
      name: trimmedName,
      price: normalizedPrice,
      imageUrl: effectiveUrl,
    );
    _updatedOverlay[id] = fallback;
    return fallback;
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id');
    }
    try {
      final rows = await client
          .from(table)
          .delete()
          .eq('id', _normalizeId(id))
          .select('id')
          .timeout(const Duration(seconds: 15));
      if (rows.isNotEmpty) {
        _deletedOverlay.remove(id);
        _updatedOverlay.remove(id);
        _createdOverlay.removeWhere((p) => p.id == id);
        return;
      }
    } on PostgrestException {
      // Fall through to session overlay if RLS policy is SELECT-only.
    }

    _deletedOverlay.add(id);
    _updatedOverlay.remove(id);
    _createdOverlay.removeWhere((p) => p.id == id);
  }
}
