import 'dart:async';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components.dart';
import 'store.dart';
import 'theme.dart';

class CatalogScreen extends StatefulWidget {
  final Store store;
  const CatalogScreen({super.key, required this.store});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String category = categories.first, search = '', sort = 'Featured';
  bool savedOnly = false;
  static const _pageSize = 8;
  int page = 0;
  RangeValues? priceRange;

  Future<void> _showPriceFilter() async {
    final maxPrice = catalog
        .where((product) => product.active)
        .map((product) => product.price)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    var draft = priceRange ?? RangeValues(0, maxPrice);
    final result = await showModalBottomSheet<RangeValues>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setDraft) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filter by price', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text('${money(draft.start)} – ${money(draft.end)}'),
                RangeSlider(
                  min: 0,
                  max: maxPrice,
                  divisions: maxPrice ~/ 5,
                  values: draft,
                  labels: RangeLabels(money(draft.start), money(draft.end)),
                  onChanged: (value) => setDraft(() => draft = value),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(draft),
                  child: const Text('Apply price filter'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(sheetContext).pop(RangeValues(0, maxPrice)),
                  child: const Text('Reset price range'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      priceRange = result == RangeValues(0, maxPrice) ? null : result;
      page = 0;
    });
  }

  int banner = 1;
  int benefitIndex = 0;
  late final PageController _benefitPageController;
  Timer? _benefitTimer;
  final searchController = TextEditingController();
  final _catalogStart = GlobalKey();

  void _goToPage(int index) {
    setState(() => page = index);
    final target = _catalogStart.currentContext;
    if (target != null) {
      unawaited(Scrollable.ensureVisible(target));
    }
  }

  @override
  void initState() {
    super.initState();
    _benefitPageController = PageController();
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _benefitTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted) return;
        final next = (benefitIndex + 1) % 3;
        if (_benefitPageController.hasClients) {
          _benefitPageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _benefitTimer?.cancel();
    _benefitPageController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = catalog
        .where(
          (p) =>
              p.active &&
              (category == categories.first || category == p.category) &&
              '${p.name} ${p.category}'.toLowerCase().contains(
                search.toLowerCase(),
              ) &&
              (!savedOnly || widget.store.favorites.contains(p.id)) &&
              (priceRange == null ||
                  (p.price >= priceRange!.start && p.price <= priceRange!.end)),
        )
        .toList();
    if (sort == 'Price: low to high') {
      products.sort((a, b) => a.price.compareTo(b.price));
    }
    if (sort == 'Price: high to low') {
      products.sort((a, b) => b.price.compareTo(a.price));
    }
    final pageCount = (products.length / _pageSize).ceil();
    final currentPage = pageCount == 0 ? 0 : page.clamp(0, pageCount - 1).toInt();
    final visibleProducts = products.skip(currentPage * _pageSize).take(_pageSize).toList();
    return AppFrame(
      store: widget.store,
      child: PageBody(
        children: [
          _hero(context),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, box) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final isMobile = box.maxWidth < 700;
              final items = [
                _benefit(
                  Icons.qr_code_2,
                  'Express Counter Pickup',
                  'Skip paper slips and cashier queues.',
                ),
                _benefit(
                  Icons.inventory_2_outlined,
                  'Pre-Order Reservations',
                  'Reserve upcoming restocks for out-of-stock items.',
                ),
                _benefit(
                  Icons.verified_outlined,
                  'Official Campus Items',
                  'Authentic Ateneo de Davao merchandise.',
                ),
              ];
              return Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 14 : 20,
                  horizontal: isMobile ? 18 : 22,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? Brand.white.withValues(alpha: .08)
                        : Brand.navy.withValues(alpha: .06),
                  ),
                ),
                child: isMobile
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 52,
                            child: ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(context).copyWith(
                                dragDevices: {
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.mouse,
                                },
                              ),
                              child: PageView.builder(
                                controller: _benefitPageController,
                                physics: const BouncingScrollPhysics(),
                                onPageChanged: (i) =>
                                    setState(() => benefitIndex = i),
                                itemCount: items.length,
                                itemBuilder: (context, i) => items[i],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              items.length,
                              (i) => Semantics(
                                label: 'Benefit ${i + 1}',
                                button: true,
                                child: InkWell(
                                  onTap: () {
                                    _benefitPageController.animateToPage(
                                      i,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                      vertical: 2,
                                    ),
                                    child: Container(
                                      width: i == benefitIndex ? 18 : 6,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: i == benefitIndex
                                            ? Brand.gold
                                            : (isDark
                                                ? Brand.white
                                                    .withValues(alpha: .22)
                                                : Brand.navy
                                                    .withValues(alpha: .15)),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: items.map((e) => Expanded(child: e)).toList(),
                      ),
              );
            },
          ),
          const SizedBox(height: 40),
          SectionHeading(
            'Campus Shop',
            'Books, study supplies, uniforms, and campus essentials.',
            key: _catalogStart,
            trailing: MediaQuery.sizeOf(context).width > 650
                ? SizedBox(width: 260, child: _search())
                : null,
          ),
          if (MediaQuery.sizeOf(context).width <= 650) ...[
            _search(),
            const SizedBox(height: 16),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: ChoiceChip(
                        label: Text(
                          c,
                          style: TextStyle(
                            fontSize: 12,
                            color: category == c
                                ? Brand.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        selected: category == c,
                        selectedColor: Brand.blue,
                        showCheckmark: false,
                        onSelected: (_) => setState(() {
                          category = c;
                          page = 0;
                        }),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                '${products.length} products',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: savedOnly
                    ? 'Show all products'
                    : 'Show saved products',
                onPressed: () => setState(() {
                  savedOnly = !savedOnly;
                  page = 0;
                }),
                icon: Icon(
                  savedOnly ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 150,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: sort,
                  underline: const SizedBox(),
                  style: Theme.of(context).textTheme.bodySmall,
                  items:
                      ['Featured', 'Price: low to high', 'Price: high to low']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() {
                    sort = v!;
                    page = 0;
                  }),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _showPriceFilter,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: Text(priceRange == null
                  ? 'Filter by price'
                  : '${money(priceRange!.start)} – ${money(priceRange!.end)}'),
            ),
          ),
          const SizedBox(height: 15),
          if (products.isEmpty)
            EmptyState(
              title: 'No essentials found',
              message: 'Try another search or explore a different category.',
              icon: Icons.search_off,
              action: 'Clear filters',
              onAction: () => setState(() {
                category = categories.first;
                search = '';
                searchController.clear();
                savedOnly = false;
                priceRange = null;
                page = 0;
              }),
            ),
          LayoutBuilder(
            builder: (context, box) => GridView.builder(
              key: const Key('productGrid'),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: box.maxWidth >= 1050
                    ? 4
                    : box.maxWidth >= 650
                    ? 3
                    : 2,
                crossAxisSpacing: box.maxWidth < 500 ? 12 : 20,
                mainAxisSpacing: 22,
                mainAxisExtent: box.maxWidth < 500 ? 280 : 340,
              ),
              itemBuilder: (_, i) => _productCard(context, visibleProducts[i]),
            ),
          ),
          if (pageCount > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Previous products',
                  onPressed: currentPage == 0 ? null : () => _goToPage(currentPage - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text('Page ${currentPage + 1} of $pageCount'),
                IconButton(
                  tooltip: 'Next products',
                  onPressed: currentPage + 1 >= pageCount ? null : () => _goToPage(currentPage + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          const SizedBox(height: 36),
          const SizedBox(height: 44),
          const Divider(),
          const SizedBox(height: 28),
          _bookstoreInfoSection(context),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          _footerSection(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _bookstoreInfoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNarrow = MediaQuery.sizeOf(context).width < 750;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Brand.blue.withValues(alpha: isDark ? .2 : .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 24,
                color: Brand.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Express Order & Claim System',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Brand.white : Brand.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Order official campus merchandise online to bypass paper order slips and cashier queues.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: isDark
                          ? const Color(0xFFB0C4DE)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (!isNarrow)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isDark
                        ? const Color(0xFF2E4B6E)
                        : Brand.blue.withValues(alpha: .3),
                  ),
                ),
                onPressed: () => context.go('/orders'),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                label: const Text('View Claim Tickets'),
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 24,
          runSpacing: 16,
          children: [
            _infoItem(
              context,
              icon: Icons.location_on_outlined,
              title: 'Pickup Location',
              detail:
                  'Main Bookstore · Ground Floor, Finster Hall\nWeb Order Express Window (Counter 2)',
            ),
            _infoItem(
              context,
              icon: Icons.schedule_rounded,
              title: 'Operating Hours',
              detail:
                  'Mon – Fri: 8:00 AM – 5:00 PM\nSat: 8:00 AM – 12:00 PM (Closed Sundays)',
            ),
            _infoItem(
              context,
              icon: Icons.badge_outlined,
              title: 'What to Bring',
              detail:
                  'Valid Ateneo Student / Faculty ID\nDigital Claim QR on your mobile screen',
            ),
          ],
        ),
        if (isNarrow) ...[
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF2E4B6E)
                      : Brand.blue.withValues(alpha: .3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => context.go('/orders'),
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text('View My Orders & Claim Tickets'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String detail,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: 250,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? Brand.gold : Brand.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Brand.white : Brand.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'MagiStore · Ateneo de Davao University Official Merchandise',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          'Order online · Pay in-app · Express pickup at the bookstore',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _search() => TextField(
    controller: searchController,
    onChanged: (v) => setState(() {
      search = v;
      page = 0;
    }),
    decoration: const InputDecoration(
      hintText: 'Search merchandise, uniforms, pins…',
      prefixIcon: Icon(Icons.search, size: 20),
    ),
    style: const TextStyle(fontSize: 12),
  );
  Widget _benefit(IconData icon, String title, String subtitle) => Row(
    children: [
      Icon(icon, size: 26, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    ],
  );
  Widget _hero(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final mobile = box.maxWidth < 650;
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: mobile
              ? (banner == 1 ? 250 : 355)
              : (banner == 1 ? 360 : 360),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Brand.navy, Brand.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: mobile ? -80 : -20,
                top: mobile ? 185 : -85,
                child: Container(
                  width: 490,
                  height: 490,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Brand.white.withValues(alpha: .07),
                      width: 65,
                    ),
                  ),
                ),
              ),
              if (banner == 0)
                Positioned(
                  right: mobile ? -20 : 15,
                  top: mobile ? 225 : 5,
                  bottom: mobile ? -20 : 0,
                  width: mobile ? 235 : box.maxWidth * .48,
                  child: Image.asset(
                    'assets/products/hero-reference.png',
                    fit: BoxFit.contain,
                    semanticLabel: 'Ateneo uniform, university ID sling and gold crest pin',
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(mobile ? 26 : 39),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner == 0
                          ? 'Official Ateneo\nMerchandise.'
                          : 'New semester.\nReady, set, Ateneo.',
                      style: TextStyle(
                        fontSize: mobile ? 33 : 42,
                        height: 1.15,
                        letterSpacing: -1.2,
                        fontWeight: FontWeight.w800,
                        color: Brand.white,
                      ),
                    ),
                    SizedBox(height: mobile ? 12 : 15),
                    Text(
                      banner == 0
                          ? (mobile
                                ? 'Order online. Pick up at the bookstore.'
                                : 'Order your campus items online and claim directly at the Bookstore express window.')
                          : (mobile
                                ? 'Books, study supplies, and campus essentials.'
                                : 'Find your fit for the semester ahead.\nBooks, study supplies, and campus essentials ready for pickup.'),
                      style: TextStyle(
                        fontSize: mobile ? 15 : 14,
                        height: 1.45,
                        color: Brand.white.withValues(alpha: .88),
                      ),
                    ),
                    if (!mobile) ...[
                      const SizedBox(height: 21),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Brand.gold,
                          foregroundColor: Brand.navy,
                          minimumSize: const Size(0, 44),
                        ),
                        onPressed: () {
                          setState(() {
                            category = banner == 0 ? 'PE Uniforms' : 'Books';
                            page = 0;
                          });
                          final target = _catalogStart.currentContext;
                          if (target != null) {
                            unawaited(Scrollable.ensureVisible(target));
                          }
                        },
                        label: Text(banner == 0 ? 'Shop uniforms' : 'Browse books'),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        iconAlignment: IconAlignment.end,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: List.generate(
                        2,
                        (i) => Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: Semantics(
                            label: 'Announcement ${i + 1}',
                            button: true,
                            child: InkWell(
                              onTap: () => setState(() => banner = i),
                              child: Container(
                                width: i == banner ? 25 : 8,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == banner
                                      ? Brand.gold
                                      : Brand.white.withValues(alpha: .3),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
  Widget _productCard(BuildContext context, Product p) {
    final saved = widget.store.favorites.contains(p.id);
    final isDark = widget.store.dark || Theme.of(context).brightness == Brightness.dark;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/product/${p.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const RadialGradient(
                          center: Alignment.center,
                          radius: 0.85,
                          colors: [
                            Color(0xFF22354A),
                            Color(0xFF142131),
                          ],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFF7F8FA),
                            Color(0xFFECEEF2),
                          ],
                        ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: Hero(
                        tag: p.id,
                        child: ProductImage(product: p),
                      ),
                    ),
                    if (!p.isStudyItem)
                      Positioned(
                      top: 10,
                      left: 10,
                      child: Tooltip(
                        message: 'Explore ${p.name} in 360° 3D Studio',
                        child: Material(
                          color: isDark ? const Color(0xFF182839) : Brand.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: isDark ? .35 : .18),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => context.go('/product/${p.id}'),
                            hoverColor: (isDark ? Brand.gold : Brand.blue).withValues(alpha: .12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2B4058) : Brand.border,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.view_in_ar_rounded,
                                    size: 13,
                                    color: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '360°',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? const Color(0xFF9DCBFA) : Brand.blue,
                                      letterSpacing: .3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Material(
                        color: isDark
                            ? const Color(0xFF182839).withValues(alpha: .92)
                            : Brand.white.withValues(alpha: .92),
                        shape: const CircleBorder(),
                        elevation: 2,
                        shadowColor: Colors.black.withValues(alpha: isDark ? .35 : .16),
                        child: IconButton(
                          tooltip: saved ? 'Unsave ${p.name}' : 'Save ${p.name}',
                          onPressed: () => widget.store.favorite(p.id),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: const EdgeInsets.all(6),
                          icon: Icon(
                            saved ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: saved
                                ? Colors.redAccent
                                : (isDark ? const Color(0xFF9DCBFA) : Brand.blue),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.category.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8,
                      letterSpacing: 1.2,
                      color: Brand.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    money(p.price),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: StockBadge(stock: widget.store.available(p)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_outward,
                        size: 16,
                        color: Brand.muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
