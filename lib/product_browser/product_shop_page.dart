import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_controller.dart';
import 'product_models.dart';

String money(double value) => '₱${value.toStringAsFixed(2)}';

class ProductShopPage extends ConsumerStatefulWidget {
  const ProductShopPage({super.key});
  @override
  ConsumerState<ProductShopPage> createState() => _ProductShopPageState();
}

class _ProductShopPageState extends ConsumerState<ProductShopPage> {
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
  Widget build(BuildContext context) {
    final state = ref.watch(productBrowserProvider);
    final controller = ref.read(productBrowserProvider.notifier);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(title: const Text('Campus Shop'), actions: [
        IconButton(tooltip: 'Refresh products', onPressed: state.loading ? null :
          () => controller.load(reloadBounds: true), icon: const Icon(Icons.refresh)),
      ]),
      body: RefreshIndicator(
        onRefresh: () => controller.load(reloadBounds: true),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(padding: const EdgeInsets.all(16), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Find your next favorite', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                const Text('Choose a price range to browse products.'),
                const SizedBox(height: 16),
                _PriceFilter(
                  key: ValueKey('${state.bounds.min}:${state.bounds.max}:${state.selected.min}:${state.selected.max}'),
                  bounds: state.bounds, selected: state.selected,
                  enabled: state.initialized && !state.loading,
                  onApply: controller.applyPrices, onClear: controller.clearPrices),
                const SizedBox(height: 12),
                Text(state.loading ? 'Loading products…' :
                  'Showing ${state.firstItem}–${state.lastItem} of ${state.total} products'),
              ]),
            ),
          ))),
          if (state.loading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator())))
          else if (state.error != null)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.cloud_off_rounded, size: 40),
                const SizedBox(height: 12),
                Text(state.error!, textAlign: TextAlign.center),
                TextButton(onPressed: () => controller.load(), child: const Text('Retry')),
              ])))
          else if (state.products.isEmpty)
            SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.search_off_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('No products match this price range.'),
                TextButton(onPressed: state.initialized ? controller.clearPrices : null,
                  child: const Text('Clear price filter')),
              ])))
          else
            SliverPadding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              sliver: SliverLayoutBuilder(builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final columns = width < 520 ? 2 : width < 850 ? 3 : 4;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns, mainAxisExtent: 270,
                    mainAxisSpacing: 14, crossAxisSpacing: 14),
                  delegate: SliverChildBuilderDelegate((context, index) =>
                    _ProductCard(product: state.products[index]), childCount: state.products.length));
              })),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16, runSpacing: 10, children: [
                OutlinedButton.icon(onPressed: !state.loading && state.page > 1 ?
                  () => controller.goToPage(state.page - 1) : null,
                  icon: const Icon(Icons.chevron_left), label: const Text('Previous')),
                Text(state.pageCount == 0 ? 'No pages' : 'Page ${state.page} of ${state.pageCount}'),
                FilledButton.icon(onPressed: !state.loading && state.page < state.pageCount ?
                  () => controller.goToPage(state.page + 1) : null,
                  icon: const Icon(Icons.chevron_right), label: const Text('Next')),
              ]))),
        ]),
      ),
    );
  }
}

class _PriceFilter extends StatefulWidget {
  const _PriceFilter({super.key, required this.bounds, required this.selected,
    required this.enabled, required this.onApply, required this.onClear});
  final PriceBand bounds;
  final PriceBand selected;
  final bool enabled;
  final ValueChanged<PriceBand> onApply;
  final VoidCallback onClear;
  @override
  State<_PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<_PriceFilter> {
  late RangeValues _draft = RangeValues(widget.selected.min, widget.selected.max);
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [const Icon(Icons.payments_outlined), const SizedBox(width: 8),
        const Expanded(child: Text('Price range', style: TextStyle(fontWeight: FontWeight.bold))),
        TextButton(onPressed: widget.enabled ? widget.onClear : null, child: const Text('Reset'))]),
      Text('${money(_draft.start)} – ${money(_draft.end)}',
        style: Theme.of(context).textTheme.titleMedium),
      RangeSlider(min: widget.bounds.min, max: widget.bounds.max, values: _draft,
        labels: RangeLabels(money(_draft.start), money(_draft.end)),
        onChanged: widget.enabled ? (value) => setState(() => _draft = value) : null,
        onChangeEnd: widget.enabled ? (value) => widget.onApply(PriceBand((value.start * 100).round() / 100, (value.end * 100).round() / 100)) : null),
      const Text('Release the slider to apply the filter.'),
    ])),
  );
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ShopProduct product;
  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero, clipBehavior: Clip.antiAlias,
    child: Padding(padding: const EdgeInsets.all(12), child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SizedBox(width: double.infinity,
          child: product.imageUrl == null || product.imageUrl!.isEmpty
            ? const Icon(Icons.shopping_bag_outlined, size: 56)
            : Image.network(product.imageUrl!, fit: BoxFit.contain,
              errorBuilder: (_, error, stack) => const Icon(Icons.broken_image_outlined, size: 48)))),
        const SizedBox(height: 12),
        Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(money(product.price), style: TextStyle(
          color: Theme.of(context).colorScheme.primary, fontSize: 19, fontWeight: FontWeight.bold)),
      ])),
  );
}
