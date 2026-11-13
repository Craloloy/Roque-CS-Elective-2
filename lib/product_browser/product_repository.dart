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

  Object _normalizeId(String id) => int.tryParse(id.trim()) ?? id.trim();

  @override
  Future<PriceBand> fetchBounds() async {
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

    final row = await client
        .from(table)
        .insert({
          'name': trimmedName,
          'price': normalizedPrice,
          'image_url': effectiveUrl,
        })
        .select('id,name,price,image_url')
        .single()
        .timeout(const Duration(seconds: 15));
    return ShopProduct.fromJson(row);
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

    final row = await client
        .from(table)
        .update({
          'name': trimmedName,
          'price': normalizedPrice,
          'image_url': effectiveUrl,
        })
        .eq('id', _normalizeId(id))
        .select('id,name,price,image_url')
        .maybeSingle()
        .timeout(const Duration(seconds: 15));
    if (row == null) {
      throw StateError('The product could not be updated. Check catalog access.');
    }
    return ShopProduct.fromJson(row);
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (id.trim().isEmpty) {
      throw ArgumentError.value(id, 'id');
    }
    final row = await client
        .from(table)
        .delete()
        .eq('id', _normalizeId(id))
        .select('id')
        .maybeSingle()
        .timeout(const Duration(seconds: 15));
    if (row == null) {
      throw StateError('The product could not be deleted. Check catalog access.');
    }
  }
}
