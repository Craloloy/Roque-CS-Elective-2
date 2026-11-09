import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'product_controller.dart';
import 'product_models.dart';
import 'laptop_artwork.dart';

const _purple = Color(0xFF673AB7);
const _ink = Color(0xFF29223E);
const _muted = Color(0xFF746D85);
const _border = Color(0xFFE6E1ED);
String money(double value) => '₱${value.toStringAsFixed(2)}';

class ProductShopPage extends ConsumerStatefulWidget {
  const ProductShopPage({super.key});
  @override
  ConsumerState<ProductShopPage> createState() => _ProductShopPageState();
}

class _ProductShopPageState extends ConsumerState<ProductShopPage> {
  final _scaffold = GlobalKey<ScaffoldState>();
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted && !ref.read(productBrowserProvider).initialized) {
        ref.read(productBrowserProvider.notifier).load();
      }
    });
  }

  Widget _filter(ProductBrowserState state) => _PriceFilter(
    key: ValueKey('${state.bounds.min}:${state.bounds.max}:${state.selected.min}:${state.selected.max}'),
    state: state,
    onApply: (prices) => ref.read(productBrowserProvider.notifier).applyPrices(prices),
    onClear: () => ref.read(productBrowserProvider.notifier).clearPrices(),
  );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productBrowserProvider);
    final controller = ref.read(productBrowserProvider.notifier);
    final wide = MediaQuery.sizeOf(context).width >= 960;
    return Scaffold(
      key: _scaffold,
      backgroundColor: const Color(0xFFF7F5FA),
      drawer: wide ? null : Drawer(
        backgroundColor: Colors.white,
        child: SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Expanded(child: Text('Product filters',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700))),
              IconButton(tooltip: 'Close filters', onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close))]),
            const SizedBox(height: 24), _filter(state),
          ]),
        )),
      ),
      body: SafeArea(child: Column(children: [
        Container(
          color: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20, vertical: 22),
          child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280),
            child: Row(children: [
              Container(width: 46, height: 46,
                decoration: BoxDecoration(color: _purple, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.laptop_mac_rounded, color: Colors.white, size: 27)),
              const SizedBox(width: 13),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Carltronics', style: TextStyle(fontSize: 25, color: _ink,
                  fontWeight: FontWeight.w800, letterSpacing: -0.8)),
                Text('Tech for every kind of day.',
                  style: TextStyle(fontSize: 12, color: _muted)),
              ])),
              IconButton(tooltip: 'Refresh products', onPressed: state.loading ? null :
                () => controller.load(reloadBounds: true), icon: const Icon(Icons.refresh_rounded)),
            ]),
          )),
        ),
        Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF673AB7), Color(0xFFA38DDB), Color(0xFFB9DDD8), Color(0xFFE4BBDD)]))),
        Expanded(child: RefreshIndicator(
          onRefresh: () => controller.load(reloadBounds: true),
          child: SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(wide ? 40 : 16, 28, wide ? 40 : 16, 40),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('HOME  /  LAPTOPS', style: TextStyle(fontSize: 11,
                  color: _muted, letterSpacing: 1.3, fontWeight: FontWeight.w600)),
                const SizedBox(height: 22),
                Container(width: double.infinity, padding: EdgeInsets.all(wide ? 32 : 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEEE7F9), Color(0xFFF3EDF8), Color(0xFFE8F1F0)]),
                    borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('THE CARLTRONICS COLLECTION', style: TextStyle(color: _purple,
                      fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text('From work mode to game mode.',
                      style: TextStyle(fontSize: wide ? 32 : 25, color: _ink,
                        fontWeight: FontWeight.w700, letterSpacing: -0.8)),
                    const SizedBox(height: 10),
                    const Text('Find your next laptop for office work, studying, gaming, or creating.',
                      style: TextStyle(color: _muted, height: 1.5)),
                  ])),
                const SizedBox(height: 30),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (wide) ...[
                    SizedBox(width: 250, child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _border)),
                      child: _filter(state))),
                    const SizedBox(width: 28),
                  ],
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 18, runSpacing: 12, children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('All laptops', style: TextStyle(fontSize: 23,
                            fontWeight: FontWeight.w700, color: _ink)),
                          const SizedBox(height: 5),
                          Text(state.loading ? 'Updating your selection…' :
                            '${state.firstItem}–${state.lastItem} of ${state.total} laptops',
                            style: const TextStyle(color: _muted, fontSize: 13)),
                        ]),
                        if (!wide) OutlinedButton.icon(
                          onPressed: () => _scaffold.currentState!.openDrawer(),
                          icon: const Icon(Icons.tune_rounded, size: 18), label: const Text('Filters')),
                        const Text('Price: low to high', style: TextStyle(color: _muted, fontSize: 12)),
                      ]),
                    const SizedBox(height: 20),
                    if (state.loading)
                      const Padding(padding: EdgeInsets.all(56), child: Center(child: CircularProgressIndicator()))
                    else if (state.error != null)
                      _StatusView(icon: Icons.cloud_off_rounded, message: state.error!,
                        label: 'Try again', onPressed: () => controller.load())
                    else if (state.products.isEmpty)
                      _StatusView(icon: Icons.search_off_rounded, message: 'No laptops match your price range.',
                        label: 'Clear filters', onPressed: state.initialized ? controller.clearPrices : null)
                    else LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 780 ? 4 : width >= 550 ? 3 : width >= 300 ? 2 : 1;
                      return GridView.builder(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns, mainAxisExtent: 310,
                          crossAxisSpacing: 16, mainAxisSpacing: 20),
                        itemCount: state.products.length,
                        itemBuilder: (context, index) => _ProductCard(product: state.products[index]));
                    }),
                    const SizedBox(height: 26),
                    Center(child: Wrap(spacing: 12, runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center, children: [
                        OutlinedButton.icon(onPressed: !state.loading && state.pageCount > 0 && state.page > 1 ?
                          () => controller.goToPage(state.page - 1) : null,
                          icon: const Icon(Icons.chevron_left, size: 18), label: const Text('Previous')),
                        Text(state.pageCount == 0 ? 'No pages' : '${state.page} / ${state.pageCount}',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
                        FilledButton.icon(onPressed: !state.loading && state.page < state.pageCount ?
                          () => controller.goToPage(state.page + 1) : null,
                          icon: const Icon(Icons.chevron_right, size: 18), label: const Text('Next')),
                      ])),
                  ])),
                ]),
                const SizedBox(height: 38),
                const Divider(color: _border),
                const SizedBox(height: 16),
                const Text('CARLTRONICS     /     Work. Play. Create.',
                  style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 0.4)),
              ]),
            )),
          ),
        )),
      ])),
    );
  }
}

class _PriceFilter extends StatefulWidget {
  const _PriceFilter({super.key, required this.state, required this.onApply, required this.onClear});
  final ProductBrowserState state;
  final ValueChanged<PriceBand> onApply;
  final VoidCallback onClear;
  @override
  State<_PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<_PriceFilter> {
  late RangeValues _draft = RangeValues(widget.state.selected.min, widget.state.selected.max);
  late final TextEditingController _min = TextEditingController(text: _draft.start.toStringAsFixed(2));
  late final TextEditingController _max = TextEditingController(text: _draft.end.toStringAsFixed(2));
  String? _error;
  bool get enabled => widget.state.initialized && !widget.state.loading;
  void _apply() {
    final min = double.tryParse(_min.text);
    final max = double.tryParse(_max.text);
    final bounds = widget.state.bounds;
    if (min == null || max == null || !min.isFinite || !max.isFinite || min > max || min < bounds.min || max > bounds.max) {
      setState(() => _error = 'Enter a valid range between ${money(bounds.min)} and ${money(bounds.max)}.');
      return;
    }
    setState(() => _error = null);
    widget.onApply(PriceBand((min * 100).round() / 100, (max * 100).round() / 100));
  }
  @override
  void dispose() { _min.dispose(); _max.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Row(children: [Icon(Icons.tune_rounded, size: 19, color: _ink), SizedBox(width: 9),
      Expanded(child: Text('Refine your search', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ink)))]),
    const SizedBox(height: 22), const Divider(color: _border), const SizedBox(height: 18),
    const Text('PRICE RANGE', style: TextStyle(fontSize: 11, letterSpacing: 1.2,
      fontWeight: FontWeight.w700, color: _muted)),
    const SizedBox(height: 14),
    Text('${money(_draft.start)} – ${money(_draft.end)}',
      style: const TextStyle(fontWeight: FontWeight.w600, color: _ink)),
    RangeSlider(min: widget.state.bounds.min, max: widget.state.bounds.max, values: _draft,
      labels: RangeLabels(money(_draft.start), money(_draft.end)),
      onChanged: enabled ? (value) => setState(() {
        _draft = value; _min.text = value.start.toStringAsFixed(2); _max.text = value.end.toStringAsFixed(2);
      }) : null),
    TextField(controller: _min, enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(labelText: 'Minimum price', prefixText: '₱ ')),
    const SizedBox(height: 14),
    TextField(controller: _max, enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onSubmitted: (_) => enabled ? _apply() : null,
      decoration: const InputDecoration(labelText: 'Maximum price', prefixText: '₱ ')),
    if (_error != null) Padding(padding: const EdgeInsets.only(top: 12),
      child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
    const SizedBox(height: 18),
    SizedBox(width: double.infinity, child: FilledButton(onPressed: enabled ? _apply : null,
      child: const Text('Apply price range'))),
    SizedBox(width: double.infinity, child: TextButton(onPressed: enabled ? widget.onClear : null,
      child: const Text('Reset filters'))),
  ]);
}

class _StatusView extends StatelessWidget {
  const _StatusView({required this.icon, required this.message, required this.label, this.onPressed});
  final IconData icon;
  final String message;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(32),
    child: Center(child: Column(children: [Icon(icon, size: 44, color: _purple),
      const SizedBox(height: 14), Text(message, textAlign: TextAlign.center),
      const SizedBox(height: 8), TextButton(onPressed: onPressed, child: Text(label))])));
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});
  final ShopProduct product;
  String? get laptopCategory {
    final uri = Uri.tryParse(product.imageUrl ?? '');
    return uri?.scheme == 'carltronics' && uri?.host == 'laptop'
      ? uri!.pathSegments.firstOrNull : null;
  }
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _border)),
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Container(width: double.infinity, color: const Color(0xFFF1EEF6),
        padding: const EdgeInsets.all(18),
        child: laptopCategory != null
          ? LaptopArtwork(category: laptopCategory!)
          : product.imageUrl == null || product.imageUrl!.isEmpty
          ? const Icon(Icons.laptop_mac_rounded, size: 54, color: Color(0xFFB3A4CE))
          : product.imageUrl!.startsWith('assets/')
          ? Image.asset(product.imageUrl!, fit: BoxFit.contain,
              errorBuilder: (_, error, stack) => const Icon(Icons.laptop_mac_rounded, size: 48, color: _purple))
          : Image.network(product.imageUrl!, fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) => progress == null ? child :
              const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            errorBuilder: (_, error, stack) => const Icon(Icons.laptop_mac_rounded, size: 48, color: _purple)))),
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (laptopCategory != null) ...[
          Text(laptopCategoryLabel(laptopCategory!).toUpperCase(),
            style: const TextStyle(color: _purple, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
        ],
        Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: _ink, height: 1.4, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
          child: Text(money(product.price), style: const TextStyle(fontSize: 21, color: _purple, fontWeight: FontWeight.w700))),
      ])),
    ]),
  );
}
