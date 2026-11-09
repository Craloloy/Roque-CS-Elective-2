import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_models.dart';

abstract class ProductRepository {
  Future<PriceBand> fetchBounds();
  Future<ProductPage> fetchPage({required PriceBand prices, required int page});
}

class SupabaseProductRepository implements ProductRepository {
  SupabaseProductRepository(this.client, {this.table = 'products'});
  final SupabaseClient client;
  final String table;

  @override
  Future<PriceBand> fetchBounds() async {
    // Only two rows are requested, not the entire catalogue.
    final cheapest = await client.from(table).select('price')
        .order('price').limit(1).timeout(const Duration(seconds: 15));
    final priciest = await client.from(table).select('price')
        .order('price', ascending: false).limit(1).timeout(const Duration(seconds: 15));
    if (cheapest.isEmpty || priciest.isEmpty) return const PriceBand(0, 100);
    final min = double.tryParse(cheapest.first['price'].toString());
    final max = double.tryParse(priciest.first['price'].toString());
    if (min == null || max == null || !min.isFinite || !max.isFinite || min < 0 || max < min) {
      throw const FormatException('The price column must contain non-negative numbers.');
    }
    final low = min.floorToDouble();
    final high = max.ceilToDouble();
    return PriceBand(low, high > low ? high : low + 1);
  }

  @override
  Future<ProductPage> fetchPage({required PriceBand prices, required int page}) async {
    if (page < 1) throw ArgumentError.value(page, 'page');
    final from = (page - 1) * ProductBrowserState.pageSize;
    final to = from + ProductBrowserState.pageSize - 1;
    // Filter first, then deterministically order and paginate on Supabase.
    // A unique ID breaks price ties so adjacent pages do not overlap.
    final response = await client.from(table)
        .select('id,name,price,image_url')
        .gte('price', prices.min)
        .lte('price', prices.max)
        .order('price')
        .order('id')
        .range(from, to)
        .count(CountOption.exact)
        .timeout(const Duration(seconds: 15));
    return ProductPage(response.data.map(ShopProduct.fromJson).toList(), response.count);
  }
}
