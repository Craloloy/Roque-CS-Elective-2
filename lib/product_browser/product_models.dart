class ShopProduct {
  const ShopProduct({required this.id, required this.name, required this.price, this.imageUrl});
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  factory ShopProduct.fromJson(Map<String, dynamic> row) {
    final price = double.tryParse(row['price'].toString());
    if (row['id'] == null || row['name'] is! String || price == null ||
        !price.isFinite || price < 0) {
      throw const FormatException('Products need an id, name, and non-negative numeric price.');
    }
    return ShopProduct(id: row['id'].toString(), name: row['name'] as String,
      price: price, imageUrl: row['image_url'] as String?);
  }
}

class PriceBand {
  const PriceBand(this.min, this.max);
  final double min;
  final double max;
}

class ProductPage {
  const ProductPage(this.items, this.total);
  final List<ShopProduct> items;
  final int total;
}

class ProductBrowserState {
  ProductBrowserState({List<ShopProduct> products = const [], this.bounds = const PriceBand(0, 100),
    this.selected = const PriceBand(0, 100), this.page = 1, this.total = 0,
    this.loading = false, this.initialized = false, this.error})
    : products = List.unmodifiable(products);

  static const pageSize = 8;
  final List<ShopProduct> products;
  final PriceBand bounds;
  final PriceBand selected;
  final int page;
  final int total;
  final bool loading;
  final bool initialized;
  final String? error;
  int get pageCount => total == 0 ? 0 : (total / pageSize).ceil();
  int get firstItem => products.isEmpty ? 0 : (page - 1) * pageSize + 1;
  int get lastItem => products.isEmpty ? 0 : firstItem + products.length - 1;

  ProductBrowserState copyWith({List<ShopProduct>? products, PriceBand? bounds,
    PriceBand? selected, int? page, int? total, bool? loading,
    bool? initialized, String? error, bool clearError = false}) => ProductBrowserState(
      products: products ?? this.products, bounds: bounds ?? this.bounds,
      selected: selected ?? this.selected, page: page ?? this.page,
      total: total ?? this.total, loading: loading ?? this.loading,
      initialized: initialized ?? this.initialized,
      error: clearError ? null : error ?? this.error);
}
