class ShopProduct {
  const ShopProduct({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
  });
  final String id;
  final String name;
  final double price;
  final String? imageUrl;

  String? get laptopCategory {
    final uri = Uri.tryParse(imageUrl ?? '');
    if (uri != null &&
        (uri.scheme == 'carltronics' || uri.scheme == 'apex') &&
        uri.host == 'laptop') {
      return uri.pathSegments.firstOrNull;
    }
    final lower = name.toLowerCase();
    if (lower.contains('nitro') ||
        lower.contains('victus') ||
        lower.contains('tuf') ||
        lower.contains('loq') ||
        lower.contains('rog') ||
        lower.contains('zephyrus')) {
      return 'gaming';
    }
    if (lower.contains('proart') ||
        lower.contains('xps') ||
        lower.contains('yoga pro')) {
      return 'creator';
    }
    if (lower.contains('aero') ||
        lower.contains('swift') ||
        lower.contains('zenbook') ||
        lower.contains('yoga slim')) {
      return 'ultrabook';
    }
    if (lower.contains('ideapad') ||
        lower.contains('inspiron') ||
        lower.contains('aspire 3') ||
        lower.contains('vivobook 15')) {
      return 'office';
    }
    return 'student';
  }

  /// Resolves a real bundled studio laptop photo for known models or categories.
  String get resolvedPhotoAsset {
    final url = imageUrl?.trim() ?? '';
    if (url.startsWith('assets/')) return url;
    final lower = name.toLowerCase();
    if (lower.contains('v14')) return 'assets/products/lenovo-v14.webp';
    if (lower.contains('aspire lite')) {
      return 'assets/products/acer-aspire-lite.webp';
    }
    if (lower.contains('vivobook go')) {
      return 'assets/products/asus-vivobook-go-15.webp';
    }
    if (lower.contains('hp laptop 14')) {
      return 'assets/products/hp-laptop-14.webp';
    }
    if (lower.contains('aspire 3')) return 'assets/products/acer-aspire-3.webp';
    if (lower.contains('ideapad')) {
      return 'assets/products/lenovo-ideapad-slim-3.webp';
    }
    if (lower.contains('vivobook 15')) {
      return 'assets/products/asus-vivobook-15.webp';
    }
    if (lower.contains('inspiron')) {
      return 'assets/products/dell-inspiron-15.webp';
    }
    if (lower.contains('aero')) {
      return 'assets/products/hp-pavilion-aero-13.webp';
    }
    if (lower.contains('swift')) {
      return 'assets/products/acer-swift-go-14.webp';
    }
    if (lower.contains('zenbook')) {
      return 'assets/products/asus-zenbook-14.webp';
    }
    if (lower.contains('yoga slim')) {
      return 'assets/products/lenovo-yoga-slim-7.webp';
    }
    if (lower.contains('nitro')) return 'assets/products/acer-nitro-v-15.webp';
    if (lower.contains('victus')) return 'assets/products/hp-victus-15.webp';
    if (lower.contains('tuf')) {
      return 'assets/products/asus-tuf-gaming-a15.webp';
    }
    if (lower.contains('loq')) return 'assets/products/lenovo-loq-15.webp';
    if (lower.contains('rog') || lower.contains('zephyrus')) {
      return 'assets/products/asus-rog-zephyrus-g14.webp';
    }
    if (lower.contains('yoga pro')) {
      return 'assets/products/lenovo-yoga-pro-9i.webp';
    }
    if (lower.contains('proart')) return 'assets/products/asus-proart-p16.webp';
    if (lower.contains('xps')) return 'assets/products/dell-xps-16.webp';
    return switch (laptopCategory) {
      'gaming' => 'assets/products/acer-nitro-v-15.webp',
      'creator' => 'assets/products/dell-xps-16.webp',
      'ultrabook' => 'assets/products/asus-zenbook-14.webp',
      'office' => 'assets/products/dell-inspiron-15.webp',
      _ => 'assets/products/lenovo-v14.webp',
    };
  }

  /// Generates concise hardware specs for mobile cards and detail sheets.
  String get shortSpecs => switch (laptopCategory) {
    'gaming' => price >= 90000
        ? 'RTX 4070 • 32GB • 1TB SSD • 165Hz'
        : 'RTX 4050 • 16GB • 512GB SSD • 144Hz',
    'creator' => 'Core Ultra 9 • 32GB • 1TB SSD • OLED',
    'ultrabook' => 'Core Ultra 7 • 16GB • 512GB SSD • 1.2kg',
    'office' => 'Core i5 • 16GB RAM • 512GB NVMe SSD',
    _ => 'Core i3 / Ryzen 3 • 8GB RAM • 512GB SSD',
  };

  List<(String label, String value)> get detailedSpecs => switch (laptopCategory) {
    'gaming' => [
      ('Processor', price >= 90000 ? 'AMD Ryzen 9 8945HS' : 'Intel Core i5-13420H'),
      ('Graphics', price >= 90000 ? 'NVIDIA GeForce RTX 4070 8GB' : 'NVIDIA GeForce RTX 4050 6GB'),
      ('Memory', price >= 90000 ? '32GB LPDDR5X' : '16GB DDR5'),
      ('Storage', price >= 90000 ? '1TB PCIe 4.0 NVMe SSD' : '512GB PCIe 4.0 SSD'),
      ('Display', '15.6" FHD+ 144Hz–165Hz IPS Anti-Glare'),
    ],
    'creator' => [
      ('Processor', 'Intel Core Ultra 9 185H / Ryzen AI 9 HX'),
      ('Graphics', 'NVIDIA GeForce RTX 4060 / 4070 Studio'),
      ('Memory', '32GB LPDDR5X Dual-Channel'),
      ('Storage', '1TB PCIe 4.0 NVMe M.2 SSD'),
      ('Display', '16" 3.2K 120Hz 100% DCI-P3 OLED'),
    ],
    'ultrabook' => [
      ('Processor', 'Intel Core Ultra 7 155H / Ryzen 7 8840U'),
      ('Graphics', 'Intel Arc / Radeon 780M Integrated'),
      ('Memory', '16GB LPDDR5X'),
      ('Storage', '512GB PCIe 4.0 NVMe SSD'),
      ('Display', '14" 2.8K OLED / IPS 16:10 Thin-Bezel'),
    ],
    'office' => [
      ('Processor', 'Intel Core i5-1335U / AMD Ryzen 5 7530U'),
      ('Graphics', 'Intel Iris Xe / AMD Radeon Graphics'),
      ('Memory', '16GB DDR4 / LPDDR5'),
      ('Storage', '512GB M.2 NVMe PCIe SSD'),
      ('Display', '15.6" Full HD (1920×1080) Anti-Glare'),
    ],
    _ => [
      ('Processor', 'Intel Core i3-N305 / AMD Ryzen 3 7320U'),
      ('Graphics', 'Integrated UHD / Radeon 610M Graphics'),
      ('Memory', '8GB LPDDR5 Onboard'),
      ('Storage', '512GB PCIe NVMe M.2 SSD'),
      ('Display', '14" / 15.6" Full HD Anti-Glare Display'),
    ],
  };

  ShopProduct copyWith({
    String? id,
    String? name,
    double? price,
    String? imageUrl,
    bool clearImageUrl = false,
  }) => ShopProduct(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
  );

  factory ShopProduct.fromJson(Map<String, dynamic> row) {
    final price = double.tryParse(row['price'].toString());
    if (row['id'] == null ||
        row['name'] is! String ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      throw const FormatException(
        'Products need an id, name, and non-negative numeric price.',
      );
    }
    return ShopProduct(
      id: row['id'].toString(),
      name: row['name'] as String,
      price: price,
      imageUrl: row['image_url'] as String?,
    );
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
  ProductBrowserState({
    List<ShopProduct> products = const [],
    this.bounds = const PriceBand(0, 100),
    this.selected = const PriceBand(0, 100),
    this.category,
    this.search = '',
    this.page = 1,
    this.total = 0,
    this.loading = false,
    this.submitting = false,
    this.initialized = false,
    this.error,
    this.actionError,
  }) : products = List.unmodifiable(products);

  static const pageSize = 8;
  final List<ShopProduct> products;
  final PriceBand bounds;
  final PriceBand selected;
  final String? category;
  final String search;
  final int page;
  final int total;
  final bool loading;
  final bool submitting;
  final bool initialized;
  final String? error;
  final String? actionError;

  bool get isPriceFiltered =>
      initialized &&
      (selected.min > bounds.min + 0.001 || selected.max < bounds.max - 0.001);

  bool get isFiltered =>
      isPriceFiltered || category != null || search.trim().isNotEmpty;

  int get pageCount => total == 0 ? 0 : (total / pageSize).ceil();
  int get firstItem => products.isEmpty ? 0 : (page - 1) * pageSize + 1;
  int get lastItem => products.isEmpty ? 0 : firstItem + products.length - 1;

  ProductBrowserState copyWith({
    List<ShopProduct>? products,
    PriceBand? bounds,
    PriceBand? selected,
    String? category,
    bool clearCategory = false,
    String? search,
    int? page,
    int? total,
    bool? loading,
    bool? submitting,
    bool? initialized,
    String? error,
    String? actionError,
    bool clearError = false,
    bool clearActionError = false,
  }) => ProductBrowserState(
    products: products ?? this.products,
    bounds: bounds ?? this.bounds,
    selected: selected ?? this.selected,
    category: clearCategory ? null : (category ?? this.category),
    search: search ?? this.search,
    page: page ?? this.page,
    total: total ?? this.total,
    loading: loading ?? this.loading,
    submitting: submitting ?? this.submitting,
    initialized: initialized ?? this.initialized,
    error: clearError ? null : error ?? this.error,
    actionError: clearActionError ? null : actionError ?? this.actionError,
  );
}
