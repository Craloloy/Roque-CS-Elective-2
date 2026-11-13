import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'laptop_artwork.dart';
import 'product_controller.dart';
import 'product_models.dart';

// tasteskill 2.5 palette: architectural monochrome & stone, zero violet/lavender.
const _productDetailRoute = '/laptop-details';
const _ink = Color(0xFF111111);
const _muted = Color(0xFF5C5C56);
const _canvas = Color(0xFFF6F6F3);
const _surfaceAlt = Color(0xFFEFEFEA);
const _border = Color(0xFFE4E4DF);
const _danger = Color(0xFFB91C1C);
const _dangerBg = Color(0xFFFEF2F2);

String money(double value) => '₱${value.toStringAsFixed(2)}';

const _laptopCategories = [
  ('student', 'Student'),
  ('office', 'Office'),
  ('ultrabook', 'Ultrabook'),
  ('gaming', 'Gaming'),
  ('creator', 'Creator'),
];

String _categorySamplePhoto(String category) => switch (category) {
  'gaming' => 'assets/products/acer-nitro-v-15.webp',
  'creator' => 'assets/products/dell-xps-16.webp',
  'ultrabook' => 'assets/products/asus-zenbook-14.webp',
  'office' => 'assets/products/dell-inspiron-15.webp',
  _ => 'assets/products/lenovo-v14.webp',
};

class ProductShopPage extends ConsumerStatefulWidget {
  const ProductShopPage({
    super.key,
    this.canManageCatalog = false,
    this.accountAction,
  });

  final bool canManageCatalog;
  final Widget? accountAction;
  @override
  ConsumerState<ProductShopPage> createState() => _ProductShopPageState();
}

class _ProductShopPageState extends ConsumerState<ProductShopPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !ref.read(productBrowserProvider).initialized) {
        ref.read(productBrowserProvider.notifier).load();
      }
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    Future.microtask(() {
      if (mounted) {
        ref.read(productBrowserProvider.notifier).load(reloadBounds: true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError ? _danger : _ink,
          duration: const Duration(seconds: 2),
          content: Text(message),
        ),
      );
  }

  Future<void> _openFilterBottomSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(productBrowserProvider);
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Filter by Price',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close filters',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded, color: _ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _PriceFilter(
                    key: ValueKey(
                      '${state.bounds.min}:${state.bounds.max}:${state.selected.min}:${state.selected.max}',
                    ),
                    state: state,
                    onApply: (prices) {
                      Navigator.of(sheetContext).pop();
                      ref
                          .read(productBrowserProvider.notifier)
                          .applyPrices(prices);
                    },
                    onClear: () {
                      Navigator.of(sheetContext).pop();
                      _searchController.clear();
                      ref.read(productBrowserProvider.notifier).clearPrices();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openCreateDialog() async {
    final createdName = await showDialog<String>(
      context: context,
      builder: (_) => const _ProductFormDialog(),
    );
    if (createdName != null && mounted) {
      _showSnack('Added "$createdName" to catalog.');
    }
  }

  Future<void> _openEditDialog(ShopProduct product) async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (updatedName != null && mounted) {
      _showSnack('Updated "$updatedName".');
    }
  }

  Future<void> _openDeleteDialog(ShopProduct product) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteProductDialog(product: product),
    );
    if (deleted == true && mounted) {
      _showSnack('Deleted "${product.name}".');
    }
  }

  Future<void> _openProductPage(ShopProduct product) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        settings: const RouteSettings(name: _productDetailRoute),
        builder: (_) => ProductDetailPage(
          initialProduct: product,
          canManageCatalog: widget.canManageCatalog,
        ),
      ),
    );
    if (result != null && mounted) {
      _showSnack(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productBrowserProvider);
    final controller = ref.read(productBrowserProvider.notifier);
    final width = MediaQuery.sizeOf(context).width;
    final horizontalEdge = width >= 1024 ? 32.0 : (width >= 600 ? 20.0 : 16.0);

    return Scaffold(
      backgroundColor: _canvas,
      body: SafeArea(
        child: Column(
          children: [
            // Clean architectural header with equal left/right edges
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalEdge,
                vertical: 12,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _ink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.laptop_mac_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Apex Computing',
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: _ink,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                Text(
                                  'Laptops & Workstations',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: _muted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (widget.canManageCatalog)
                            FilledButton.icon(
                              key: const Key('addProductButton'),
                              onPressed: state.loading || state.submitting
                                  ? null
                                  : _openCreateDialog,
                              style: FilledButton.styleFrom(
                                backgroundColor: _ink,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text(
                                'Add laptop',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Refresh products',
                            visualDensity: VisualDensity.compact,
                            onPressed: state.loading
                                ? null
                                : () => controller.load(reloadBounds: true),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: _ink,
                              size: 20,
                            ),
                          ),
                          if (widget.accountAction != null) widget.accountAction!,
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Search + Bottom-Sheet Filter button row
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: controller.applySearch,
                                onChanged: (value) {
                                  if (value.isEmpty &&
                                      state.search.isNotEmpty) {
                                    controller.applySearch('');
                                  }
                                },
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _ink,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search laptops by model…',
                                  hintStyle: const TextStyle(
                                    fontSize: 12.5,
                                    color: _muted,
                                  ),
                                  filled: true,
                                  fillColor: _canvas,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 0,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: _muted,
                                  ),
                                  suffixIcon:
                                      _searchController.text.isNotEmpty ||
                                              state.search.isNotEmpty
                                          ? IconButton(
                                              tooltip: 'Clear search',
                                              padding: EdgeInsets.zero,
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                size: 16,
                                              ),
                                              onPressed: () {
                                                _searchController.clear();
                                                controller.applySearch('');
                                              },
                                            )
                                          : null,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: _border),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: _border),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 38,
                            child: OutlinedButton.icon(
                              key: const Key('openFiltersButton'),
                              onPressed: _openFilterBottomSheet,
                              style: OutlinedButton.styleFrom(
                                backgroundColor: state.isPriceFiltered
                                    ? _ink
                                    : Colors.white,
                                foregroundColor: state.isPriceFiltered
                                    ? Colors.white
                                    : _ink,
                                side: BorderSide(
                                  color: state.isPriceFiltered ? _ink : _border,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.tune_rounded, size: 16),
                              label: Text(
                                state.isPriceFiltered
                                    ? 'Price Filter • On'
                                    : 'Filters',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Category filter pills + status line
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _CategoryPill(
                              label: 'All',
                              selected: state.category == null,
                              onTap: state.loading
                                  ? null
                                  : () => controller.selectCategory(null),
                            ),
                            for (final cat in _laptopCategories)
                              _CategoryPill(
                                label: cat.$2,
                                selected: state.category == cat.$1,
                                onTap: state.loading
                                    ? null
                                    : () => controller.selectCategory(
                                        state.category == cat.$1
                                            ? null
                                            : cat.$1,
                                      ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            'All laptops',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.loading
                                  ? 'Updating your selection…'
                                  : '${state.firstItem}–${state.lastItem} of ${state.total} laptops',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (state.isFiltered)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: state.loading
                                  ? null
                                  : () {
                                      _searchController.clear();
                                      controller.clearPrices();
                                    },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Text(
                                  'Reset filters',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            )
                          else
                            Flexible(
                              child: Text(
                                state.initialized
                                    ? '${money(state.selected.min)} – ${money(state.selected.max)}'
                                    : 'Price: low to high',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(color: _border, height: 1),

            // Product Grid with equal left/right content edges
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => controller.load(reloadBounds: true),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalEdge,
                    14,
                    horizontalEdge,
                    20,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (state.loading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 64),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (state.error != null)
                            _StatusView(
                              icon: Icons.cloud_off_rounded,
                              message: state.error!,
                              label: 'Try again',
                              onPressed: () => controller.load(),
                            )
                          else if (state.products.isEmpty)
                            _StatusView(
                              icon: Icons.search_off_rounded,
                              message: 'No laptops match your price range.',
                              label: 'Clear filters',
                              onPressed: state.initialized
                                  ? () {
                                      _searchController.clear();
                                      controller.clearPrices();
                                    }
                                  : null,
                            )
                          else
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final w = constraints.maxWidth;
                                final columns = w >= 860
                                    ? 4
                                    : w >= 580
                                    ? 3
                                    : w >= 280
                                    ? 2
                                    : 1;
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        mainAxisExtent: 262,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: state.products.length,
                                  itemBuilder: (context, index) {
                                    final product = state.products[index];
                                    return _ProductCard(
                                      product: product,
                                      busy: state.submitting,
                                      canManageCatalog: widget.canManageCatalog,
                                      onTap: () => _openProductPage(product),
                                      onEdit: () => _openEditDialog(product),
                                      onDelete: () =>
                                          _openDeleteDialog(product),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Pagination Bar
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalEdge,
                vertical: 10,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: !state.loading &&
                                state.pageCount > 0 &&
                                state.page > 1
                            ? () => controller.goToPage(state.page - 1)
                            : null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text(
                          'Previous',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      Flexible(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _surfaceAlt,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            state.pageCount == 0
                                ? 'No pages'
                                : '${state.page} / ${state.pageCount}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: _ink,
                            ),
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: !state.loading &&
                                state.page < state.pageCount
                            ? () => controller.goToPage(state.page + 1)
                            : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text(
                          'Next',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _relatedProductsProvider =
    FutureProvider.autoDispose.family<List<ShopProduct>, ({String id, String? category})>(
      (ref, product) => ref.watch(productRepositoryProvider).fetchRelated(
        productId: product.id,
        category: product.category,
      ),
    );

/// Dedicated next-page screen for viewing a laptop and performing Update/Delete.
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.initialProduct,
    this.canManageCatalog = false,
  });
  final bool canManageCatalog;
  final ShopProduct initialProduct;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  late ShopProduct _product = widget.initialProduct;

  Future<void> _handleEdit() async {
    final updatedName = await showDialog<String>(
      context: context,
      builder: (_) => _ProductFormDialog(product: _product),
    );
    if (updatedName != null && mounted) {
      final latest = ref
          .read(productBrowserProvider)
          .products
          .where((p) => p.id == _product.id)
          .firstOrNull;
      if (latest != null) {
        setState(() => _product = latest);
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: _ink,
            content: Text('Updated "$updatedName".'),
          ),
        );
    }
  }

  Future<void> _handleDelete() async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteProductDialog(product: _product),
    );
    if (deleted == true && mounted) {
      Navigator.of(context).pop('Deleted "${_product.name}".');
    }
  }

  void _backToStore() {
    Navigator.of(context).popUntil(
      (route) => route.isFirst || route.settings.name != _productDetailRoute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final category = _product.laptopCategory;
    final width = MediaQuery.sizeOf(context).width;
    final edge = width >= 600 ? 24.0 : 16.0;
    const sectionGap = SizedBox(height: 16);
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (category != null) ...[
          _CategoryPill(
            label: laptopCategoryLabel(category),
            selected: false,
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          header: true,
          child: Text(
            _product.name,
            style: const TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          money(_product.price),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Laptop details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
          if (widget.canManageCatalog)
            PopupMenuButton<String>(
              tooltip: 'Manage laptop',
              onSelected: (action) async {
                if (action == 'edit') {
                  await _handleEdit();
                } else {
                  await _handleDelete();
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit laptop')),
                PopupMenuItem(value: 'delete', child: Text('Delete laptop')),
              ],
            ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _border)),
        ),
        child: SafeArea(
          top: false,
          minimum: EdgeInsets.fromLTRB(edge, 10, edge, 10),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _backToStore,
                  icon: const Icon(Icons.storefront_outlined, size: 19),
                  label: const Text('Back to store'),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(edge, 16, edge, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailCard(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 620;
                        final photo = Container(
                          height: wide ? 260 : 190,
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _canvas,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _ProductPhoto(product: _product),
                        );
                        if (wide) {
                          return Row(
                            children: [
                              Expanded(flex: 6, child: photo),
                              const SizedBox(width: 24),
                              Expanded(flex: 5, child: summary),
                            ],
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [photo, sectionGap, summary],
                        );
                      },
                    ),
                  ),
                  sectionGap,
                  _DetailCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Semantics(
                          header: true,
                          child: const Text(
                            'Specifications',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final spec in _product.detailedSpecs)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                  flex: 1,
                                  fit: FlexFit.tight,
                                  child: Text(
                                    spec.$1,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    spec.$2,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  sectionGap,
                  _DetailCard(
                    child: _RelatedProducts(
                      product: _product,
                      canManageCatalog: widget.canManageCatalog,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _border),
    ),
    child: child,
  );
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({
    required this.product,
    required this.canManageCatalog,
  });

  final ShopProduct product;
  final bool canManageCatalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = _relatedProductsProvider((
      id: product.id,
      category: product.laptopCategory,
    ));
    final related = ref.watch(request);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related products',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        related.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => TextButton(
            onPressed: () => ref.invalidate(request),
            child: const Text('Retry loading related products'),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const Text('No other laptops to show yet.');
            }
            return Column(
              children: [
                for (final item in items)
                  ListTile(
                    key: ValueKey('related_product_${item.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: SizedBox(
                      width: 54,
                      height: 42,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _canvas,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _ProductPhoto(product: item),
                      ),
                    ),
                    title: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(money(item.price)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () async {
                      final result = await Navigator.of(context).push<String>(
                        MaterialPageRoute<String>(
                          settings: const RouteSettings(name: _productDetailRoute),
                          builder: (_) => ProductDetailPage(
                            initialProduct: item,
                            canManageCatalog: canManageCatalog,
                          ),
                        ),
                      );
                      if (!context.mounted) return;
                      ref.invalidate(request);
                      if (result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result)),
                        );
                      }
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProductPhoto extends StatelessWidget {
  const _ProductPhoto({required this.product});
  final ShopProduct product;

  @override
  Widget build(BuildContext context) {
    final rawUrl = product.imageUrl?.trim() ?? '';
    final isHttp =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://');
    if (isHttp) {
      return Image.network(
        rawUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Image.asset(
          product.resolvedPhotoAsset,
          fit: BoxFit.contain,
        ),
      );
    }
    return Image.asset(
      product.resolvedPhotoAsset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => LaptopArtwork(
        category: product.laptopCategory ?? 'student',
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 6),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _ink : _canvas,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? _ink : _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _ink,
          ),
        ),
      ),
    ),
  );
}

class _PriceFilter extends StatefulWidget {
  const _PriceFilter({
    super.key,
    required this.state,
    required this.onApply,
    required this.onClear,
  });
  final ProductBrowserState state;
  final ValueChanged<PriceBand> onApply;
  final VoidCallback onClear;
  @override
  State<_PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<_PriceFilter> {
  late RangeValues _draft = RangeValues(
    widget.state.selected.min.clamp(
      widget.state.bounds.min,
      widget.state.bounds.max,
    ),
    widget.state.selected.max.clamp(
      widget.state.bounds.min,
      widget.state.bounds.max,
    ),
  );
  late final TextEditingController _min = TextEditingController(
    text: _draft.start.toStringAsFixed(2),
  );
  late final TextEditingController _max = TextEditingController(
    text: _draft.end.toStringAsFixed(2),
  );
  String? _error;

  bool get enabled => widget.state.initialized && !widget.state.loading;

  void _setDraft(double min, double max) {
    final bounds = widget.state.bounds;
    final clampedMin = min.clamp(bounds.min, bounds.max).toDouble();
    final clampedMax = max.clamp(clampedMin, bounds.max).toDouble();
    setState(() {
      _error = null;
      _draft = RangeValues(clampedMin, clampedMax);
      _min.text = clampedMin.toStringAsFixed(2);
      _max.text = clampedMax.toStringAsFixed(2);
    });
  }

  void _apply() {
    final min = double.tryParse(_min.text.replaceAll(',', '').trim());
    final max = double.tryParse(_max.text.replaceAll(',', '').trim());
    final bounds = widget.state.bounds;
    if (min == null ||
        max == null ||
        !min.isFinite ||
        !max.isFinite ||
        min > max ||
        min < bounds.min ||
        max > bounds.max) {
      setState(
        () => _error =
            'Enter a valid range between ${money(bounds.min)} and ${money(bounds.max)}.',
      );
      return;
    }
    setState(() => _error = null);
    widget.onApply(
      PriceBand((min * 100).round() / 100, (max * 100).round() / 100),
    );
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.state.bounds;
    final sliderMax = bounds.max > bounds.min ? bounds.max : bounds.min + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drag the slider or enter exact minimum and maximum prices.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
        const SizedBox(height: 12),
        const Divider(color: _border, height: 1),
        const SizedBox(height: 12),
        const Text(
          'PRICE RANGE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: _muted,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${money(_draft.start)} – ${money(_draft.end)}',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: _ink,
          ),
        ),
        RangeSlider(
          activeColor: _ink,
          inactiveColor: _border,
          min: bounds.min,
          max: sliderMax,
          values: RangeValues(
            _draft.start.clamp(bounds.min, sliderMax),
            _draft.end.clamp(bounds.min, sliderMax),
          ),
          labels: RangeLabels(money(_draft.start), money(_draft.end)),
          onChanged: enabled
              ? (value) => setState(() {
                  _error = null;
                  _draft = value;
                  _min.text = value.start.toStringAsFixed(2);
                  _max.text = value.end.toStringAsFixed(2);
                })
              : null,
        ),
        if (bounds.max >= 60000) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PresetChip(
                label: 'Under ₱30k',
                enabled: enabled,
                onTap: () => _setDraft(bounds.min, 30000),
              ),
              _PresetChip(
                label: '₱30k–₱60k',
                enabled: enabled,
                onTap: () => _setDraft(30000, 60000),
              ),
              _PresetChip(
                label: '₱60k+',
                enabled: enabled,
                onTap: () => _setDraft(60000, bounds.max),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _min,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Minimum price',
                  prefixText: '₱ ',
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _max,
                enabled: enabled,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => enabled ? _apply() : null,
                decoration: const InputDecoration(
                  labelText: 'Maximum price',
                  prefixText: '₱ ',
                ),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: enabled ? widget.onClear : null,
                child: const Text('Reset filters'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: enabled ? _apply : null,
                child: const Text('Apply price range'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label, style: const TextStyle(fontSize: 11.5)),
    visualDensity: VisualDensity.compact,
    onPressed: enabled ? onTap : null,
  );
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
    required this.label,
    this.onPressed,
  });
  final IconData icon;
  final String message;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 40, color: _ink),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TextButton(onPressed: onPressed, child: Text(label)),
        ],
      ),
    ),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.busy,
    required this.canManageCatalog,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final ShopProduct product;
  final bool busy;
  final bool canManageCatalog;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final category = product.laptopCategory;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio photo on neutral stone ground (tasteskill Rule 1 & 6)
            SizedBox(
              height: 104,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: _canvas,
                    padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
                    child: _ProductPhoto(product: product),
                  ),
                  if (category != null)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _border),
                        ),
                        child: Text(
                          laptopCategoryLabel(category).toUpperCase(),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 8.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.shortSpecs,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: _muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        money(product.price),
                        style: const TextStyle(
                          fontSize: 15.5,
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (canManageCatalog) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 30,
                              child: OutlinedButton.icon(
                                key: Key('edit_${product.id}'),
                                onPressed: busy ? null : onEdit,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _ink,
                                  side: const BorderSide(color: _border),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: const Icon(Icons.edit_outlined, size: 13),
                                label: const Text(
                                  'Edit',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          SizedBox(
                            height: 30,
                            width: 32,
                            child: IconButton.filledTonal(
                              key: Key('delete_${product.id}'),
                              tooltip: 'Delete ${product.name}',
                              onPressed: busy ? null : onDelete,
                              style: IconButton.styleFrom(
                                backgroundColor: _dangerBg,
                                foregroundColor: _danger,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormDialog extends ConsumerStatefulWidget {
  const _ProductFormDialog({this.product});
  final ShopProduct? product;

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.product?.name ?? '',
  );
  late final TextEditingController _price = TextEditingController(
    text: widget.product != null
        ? widget.product!.price.toStringAsFixed(2)
        : '',
  );
  late String _category = widget.product?.laptopCategory ?? 'student';
  String? _localError;

  bool get isEditing => widget.product != null;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final price = double.tryParse(_price.text.replaceAll(',', '').trim());
    if (name.isEmpty) {
      setState(() => _localError = 'Please enter a laptop name.');
      return;
    }
    if (price == null || !price.isFinite || price < 0) {
      setState(() => _localError = 'Please enter a valid non-negative price.');
      return;
    }
    setState(() => _localError = null);

    final existingUrl = widget.product?.imageUrl;
    final keepCustomUrl =
        existingUrl != null &&
        existingUrl.isNotEmpty &&
        widget.product?.laptopCategory == null &&
        _category == (widget.product?.laptopCategory ?? '');
    final imageUrl = keepCustomUrl
        ? existingUrl
        : 'carltronics://laptop/$_category';

    final controller = ref.read(productBrowserProvider.notifier);
    final ok = isEditing
        ? await controller.updateProduct(
            id: widget.product!.id,
            name: name,
            price: price,
            imageUrl: imageUrl,
          )
        : await controller.createProduct(
            name: name,
            price: price,
            imageUrl: imageUrl,
          );

    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(name);
    } else {
      setState(() {
        _localError = ref.read(productBrowserProvider).actionError ??
            'Could not save changes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(
      productBrowserProvider.select((s) => s.submitting),
    );
    final previewAsset = widget.product != null &&
            _category == widget.product!.laptopCategory
        ? widget.product!.resolvedPhotoAsset
        : _categorySamplePhoto(_category);

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        isEditing ? 'Edit laptop' : 'Add laptop',
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 108,
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _canvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: Image.asset(
                  previewAsset,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => LaptopArtwork(category: _category),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const Key('productNameField'),
                controller: _name,
                enabled: !submitting,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Laptop name',
                  hintText: 'e.g. ASUS Zenbook 14',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('productPriceField'),
                controller: _price,
                enabled: !submitting,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onSubmitted: (_) => submitting ? null : _submit(),
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₱ ',
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'CATEGORY',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final entry in _laptopCategories)
                    ChoiceChip(
                      label: Text(
                        entry.$2,
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _category == entry.$1,
                      onSelected: submitting
                          ? null
                          : (_) => setState(() => _category = entry.$1),
                    ),
                ],
              ),
              if (_localError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _dangerBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _localError!,
                    style: const TextStyle(color: _danger, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('saveProductButton'),
          onPressed: submitting ? null : _submit,
          child: Text(
            submitting
                ? 'Saving…'
                : (isEditing ? 'Save changes' : 'Add laptop'),
          ),
        ),
      ],
    );
  }
}

class _DeleteProductDialog extends ConsumerStatefulWidget {
  const _DeleteProductDialog({required this.product});
  final ShopProduct product;

  @override
  ConsumerState<_DeleteProductDialog> createState() =>
      _DeleteProductDialogState();
}

class _DeleteProductDialogState extends ConsumerState<_DeleteProductDialog> {
  String? _error;

  Future<void> _confirmDelete() async {
    setState(() => _error = null);
    final ok = await ref
        .read(productBrowserProvider.notifier)
        .deleteProduct(widget.product.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = ref.read(productBrowserProvider).actionError ??
            'Could not delete product.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitting = ref.watch(
      productBrowserProvider.select((s) => s.submitting),
    );
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: const Text(
        'Delete laptop?',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remove "${widget.product.name}" (${money(widget.product.price)}) from the Apex Computing catalog?',
              style: const TextStyle(color: _ink, height: 1.4),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: _danger, fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('confirmDeleteButton'),
          style: FilledButton.styleFrom(backgroundColor: _danger),
          onPressed: submitting ? null : _confirmDelete,
          child: Text(submitting ? 'Deleting…' : 'Delete'),
        ),
      ],
    );
  }
}
