import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'components.dart';
import 'product_viewer.dart';
import 'store.dart';
import 'theme.dart';

class ProductScreen extends StatefulWidget {
  final Store store;
  final Product product;
  const ProductScreen({super.key, required this.store, required this.product});
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final bagAnchor = GlobalKey();
  final viewerAnchor = GlobalKey();
  String? variant;
  int quantity = 1;
  bool adding = false, added = false;
  Future<void> flyToBag() async {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final source =
        viewerAnchor.currentContext?.findRenderObject() as RenderBox?;
    final target = bagAnchor.currentContext?.findRenderObject() as RenderBox?;
    if (source == null || target == null) return;
    final from = source.localToGlobal(source.size.center(Offset.zero));
    final end = target.localToGlobal(target.size.center(Offset.zero));
    final begin = Offset(
      from.dx,
      from.dy.clamp(100, MediaQuery.sizeOf(context).height - 150),
    );
    final control = Offset((begin.dx + end.dx) / 2, end.dy - 100);
    final entry = OverlayEntry(
      builder: (_) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        builder: (context, t, _) {
          final position =
              begin * ((1 - t) * (1 - t)) +
              control * (2 * (1 - t) * t) +
              end * (t * t);
          return Positioned(
            left: position.dx - 42,
            top: position.dy - 42,
            width: 84,
            height: 84,
            child: IgnorePointer(
              child: Opacity(
                opacity: 1 - t,
                child: Transform.scale(
                  scale: 1 - .65 * t,
                  child: ProductImage(product: widget.product),
                ),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 550));
    entry.remove();
    entry.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.length == 1) {
      variant = widget.product.variants.keys.first;
    }
  }

  Future<void> add(bool reserve) async {
    if (widget.product.variants.isNotEmpty && variant == null) {
      toast(
        context,
        'Please select a size or variant.',
        icon: Icons.info_outline_rounded,
      );
      return;
    }
    if (reserve) {
      final approved = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(
            Icons.inventory_2_outlined,
            color: Brand.purple,
            size: 32,
          ),
          title: const Text('Save your spot'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${widget.product.name} · $variant'),
              const SizedBox(height: 14),
              const Text(
                'This variant is currently unavailable. Full advance payment secures your reservation.',
              ),
              const SizedBox(height: 12),
              const InfoBox(
                'Estimated restock: 2–3 weeks. This is an estimate, not a guaranteed date. Schedule your pickup after restock.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Please review your chosen item and variant before reserving. Your pickup window becomes available after restock.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('I understand · Reserve'),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
    }
    final error = widget.store.add(
      widget.product,
      variant!,
      quantity,
      reserve: reserve,
    );
    if (error != null) {
      if (mounted) toast(context, error, icon: Icons.error_outline_rounded);
      return;
    }
    setState(() {
      adding = true;
      added = true;
    });
    HapticFeedback.lightImpact();
    flyToBag();
    await Future<void>.delayed(
      Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 600),
    );
    if (!mounted) return;
    toast(
      context,
      reserve
          ? 'Reservation added. Complete checkout to secure your item.'
          : 'Item added to your bag.',
      icon: Icons.check_circle_outline_rounded,
      actionLabel: 'VIEW BAG',
      onAction: () => context.go('/cart'),
    );
    setState(() => adding = false);
  }

  void _showSizeGuide(BuildContext context) {
    final isDark = widget.store.dark || Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF142436) : Brand.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF263C52) : Brand.border,
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: (isDark ? Brand.gold : Brand.blue).withValues(alpha: .14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.straighten_rounded,
                color: isDark ? Brand.gold : Brand.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'PE Uniform Size Guide',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? const Color(0xFFE6EDF5) : Brand.navy,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Measurements are in inches. Standard unisex athletic sizing for Ateneo male and female students.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFFAAB8C6) : Brand.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(
                  color: isDark ? const Color(0xFF263C52) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E3248) : const Color(0xFFE2E8F0),
                    ),
                    children: [
                      for (final header in ['Size', 'Chest', 'Top Length', 'Waist', 'Pants Length'])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          child: Text(
                            header,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: isDark ? const Color(0xFF9DCBFA) : Brand.navy,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (final row in const [
                    ['XS', '36"', '25"', '26–28"', '36"'],
                    ['S', '38"', '26"', '28–30"', '37"'],
                    ['M', '40"', '27"', '30–32"', '38"'],
                    ['L', '42"', '28"', '32–34"', '39"'],
                    ['XL', '44"', '29"', '34–36"', '40"'],
                  ])
                    TableRow(
                      decoration: BoxDecoration(
                        color: row[0] == 'S' || row[0] == 'L'
                            ? (isDark ? const Color(0xFF18293B).withValues(alpha: .5) : const Color(0xFFF8FAFC))
                            : Colors.transparent,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                          child: Text(
                            row[0],
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              color: isDark ? Brand.gold : Brand.blue,
                            ),
                          ),
                        ),
                        for (int i = 1; i < 5; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                            child: Text(
                              row[i],
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFFD4E3F3) : Brand.ink,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Brand.gold.withValues(alpha: .15)
                      : Brand.gold.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? Brand.gold.withValues(alpha: .4)
                        : Brand.gold.withValues(alpha: .3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: isDark ? Brand.gold : Brand.navy,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pants feature a flexible drawstring elastic waistband. If between sizes, choose one size up.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFF7DE98) : Brand.navy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF243B52) : const Color(0xFFE2E8F0),
              foregroundColor: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () => Navigator.pop(c),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final isDark = widget.store.dark || Theme.of(context).brightness == Brightness.dark;
    final stock = variant == null
        ? widget.store.available(p)
        : widget.store.stock(p, variant!);
    final reserve = stock == 0;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.category.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            color: Brand.muted,
          ),
        ),
        const SizedBox(height: 14),
        Text(p.name, style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 14),
        StockBadge(stock: stock),
        const SizedBox(height: 22),
        Text(
          money(p.price),
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 17),
        Text(p.detail),
        const SizedBox(height: 25),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              p.category == 'PE Uniforms'
                  ? 'Choose your size'
                  : 'Choose your variant',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (p.category == 'PE Uniforms')
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                ),
                onPressed: () => _showSizeGuide(context),
                icon: Icon(
                  Icons.straighten_rounded,
                  size: 16,
                  color: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                ),
                label: const Text('Size Guide'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: p.variants.keys
              .map(
                (v) => ChoiceChip(
                  avatar: p.category == 'PE Uniforms' && widget.store.stock(p, v) == 0
                      ? Icon(
                          Icons.schedule,
                          size: 13,
                          color: isDark ? const Color(0xFFF7DE98) : Brand.gold,
                        )
                      : null,
                  label: Text(
                    '$v${widget.store.stock(p, v) == 0 ? ' · reserve' : ''}',
                    style: TextStyle(
                      color: variant == v
                          ? (isDark ? Brand.white : Brand.blue)
                          : (isDark ? const Color(0xFFD4E3F3) : Brand.ink),
                      fontWeight:
                          variant == v ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                  selected: variant == v,
                  selectedColor: isDark
                      ? const Color(0xFF254366)
                      : Brand.blue.withValues(alpha: .14),
                  backgroundColor:
                      isDark ? const Color(0xFF16273A) : Brand.cream,
                  side: BorderSide(
                    color: variant == v
                        ? (isDark ? const Color(0xFF9DCBFA) : Brand.blue)
                        : (isDark ? const Color(0xFF2B445E) : Brand.border),
                  ),
                  onSelected: (_) => setState(() {
                    variant = v;
                    quantity = 1;
                    added = false;
                  }),
                ),
              )
              .toList(),
        ),
        if (variant != null && p.category == 'PE Uniforms') ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                widget.store.stock(p, variant!) == 0
                    ? Icons.info_outline_rounded
                    : Icons.check_circle_outline_rounded,
                size: 15,
                color: widget.store.stock(p, variant!) == 0
                    ? (isDark ? const Color(0xFFF7DE98) : Brand.gold)
                    : (isDark ? const Color(0xFF4ADE80) : Colors.teal),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.store.stock(p, variant!) == 0
                      ? 'Size $variant is currently out of stock. Pre-order reservation enabled.'
                      : 'Size $variant is in stock (${widget.store.stock(p, variant!)} available for pickup).',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: widget.store.stock(p, variant!) == 0
                        ? (isDark ? const Color(0xFFF7DE98) : Brand.navy)
                        : (isDark ? const Color(0xFF4ADE80) : Colors.teal.shade800),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (p.category == 'PE Uniforms') ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF162536)
                  : Brand.blue.withValues(alpha: .06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF243B52)
                    : Brand.blue.withValues(alpha: .15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Complete 2-Piece Uniform Set',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 1× White Ateneo PE Top (with royal blue trims & university crest)\n• 1× Full-Length Navy Athletic Pants (with vertical ATENEO print)',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: isDark ? const Color(0xFFD4E3F3) : Brand.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            const Text('Quantity'),
            const SizedBox(width: 20),
            QuantityControl(
              value: quantity,
              onChanged: (v) {
                final max = reserve ? 5 : stock;
                if (v >= 1 && v <= max) {
                  setState(() => quantity = v);
                } else {
                  toast(context, 'Choose between 1 and $max.');
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 25),
        LayoutBuilder(
          builder: (context, box) => Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              width: adding ? 56 : box.maxWidth,
              height: 52,
              duration: Duration(
                milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 300,
              ),
              curve: Curves.easeOutCubic,
              child: FilledButton(
                key: const Key('addToCart'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: reserve ? Brand.gold : null,
                  foregroundColor: reserve ? Brand.navy : null,
                  disabledBackgroundColor: reserve ? Brand.gold : Brand.blue,
                  disabledForegroundColor: Brand.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(adding ? 28 : 12),
                  ),
                ),
                onPressed: adding ? null : () => add(reserve),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: adding
                      ? const Icon(
                          Icons.check,
                          key: ValueKey('success'),
                          size: 23,
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                reserve
                                    ? Icons.bookmark_border
                                    : Icons.shopping_bag_outlined,
                                size: 19,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                reserve
                                    ? 'Reserve & Secure Slot'
                                    : 'Add to Cart',
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (added || widget.store.count > 0) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go('/cart'),
              child: Text('View bag (${widget.store.count}) →'),
            ),
          ),
        ],
        const SizedBox(height: 22),
        const InfoBox(
          'Your online order replaces the bookstore paper slip and cashier visit. Pay in-app, then bring your QR for one express pickup.',
          icon: Icons.storefront_outlined,
        ),
        const SizedBox(height: 22),
        const Divider(),
        if (p.category == 'PE Uniforms')
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Size & fit guidance'),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Standard Ateneo unisex athletic sizing for male and female students. Tops feature a relaxed athletic cut in breathable poly-cotton. Full-length track pants include a flexible drawstring elastic waistband and side pockets. If between sizes, we recommend choosing one size up for comfort.',
                ),
              ),
            ],
          ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Materials & details'),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(p.material),
            ),
          ],
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Pickup & reservations'),
          children: const [
            Padding(
              padding: EdgeInsets.only(bottom: 20),
              child: Text(
                'Bring your Ateneo ID and claim QR to the selected pickup point. Reserved items are scheduled after restock. All prices and fulfillment information in this project are samples.',
              ),
            ),
          ],
        ),
      ],
    );
    return AppFrame(
      store: widget.store,
      bagKey: bagAnchor,
      child: PageBody(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to essentials'),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth > 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: ProductViewer360(key: viewerAnchor, product: p),
                      ),
                      const SizedBox(width: 48),
                      Expanded(flex: 5, child: details),
                    ],
                  )
                : Column(
                    children: [
                      ProductViewer360(key: viewerAnchor, product: p),
                      const SizedBox(height: 30),
                      details,
                    ],
                  ),
          ),
          const SizedBox(height: 25),
          Text(
            'Official Ateneo de Davao campus merchandise.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
