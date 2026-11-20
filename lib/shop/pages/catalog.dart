import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../product_viewer.dart';
import '../../store.dart' as demo show catalog;
import '../models/shop.dart';
import '../providers/shop_providers.dart';
import 'common.dart';
import 'management.dart';

class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({
    super.key,
    required this.search,
    required this.onOpenItem,
  });
  final ValueChanged<Item> onOpenItem;
  final TextEditingController search;
  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  final scroll = ScrollController();
  final minPrice = TextEditingController(), maxPrice = TextEditingController();
  Timer? debounce;
  String query = '', typed = '', sort = 'Featured';
  String? priceError;
  int? category, low, high;
  int page = 0;
  bool savedOnly = false;
  bool filtersOpen = false;
  bool availableOnly = false;

  @override
  void initState() {
    super.initState();
    query = typed = widget.search.text.trim();
    widget.search.addListener(updateSearch);
  }

  void updateSearch() {
    final text = widget.search.text.trim();
    if (text == typed) return;
    typed = text;
    debounce?.cancel();
    if (text.length <= 1) {
      applySearch(text);
    } else {
      debounce = Timer(const Duration(milliseconds: 250), () {
        if (mounted) applySearch(text);
      });
    }
  }

  void applySearch(String text) {
    if (query == text) return;
    change(() => query = text);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  void dispose() {
    widget.search.removeListener(updateSearch);
    debounce?.cancel();
    minPrice.dispose();
    maxPrice.dispose();
    scroll.dispose();
    super.dispose();
  }

  void change(VoidCallback edit) => setState(() {
    edit();
    page = 0;
  });
  Filters filter(String ids) => (
    search: query,
    category: query.isEmpty ? category : null,
    minCents: query.isEmpty ? low : null,
    maxCents: query.isEmpty ? high : null,
    sort: query.isEmpty ? sort : 'Featured',
    page: page,
    savedIds: query.isEmpty && savedOnly ? ids : '*',
    availableOnly: query.isEmpty && availableOnly,
  );
  void turn(int next) {
    setState(() => page = next);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  String amount(int? value) {
    if (value == null) return '';
    return (value / 100).toStringAsFixed(value % 100 == 0 ? 0 : 2);
  }

  void choosePrice(int? from, int? to) {
    minPrice.text = amount(from);
    maxPrice.text = amount(to);
    change(() {
      priceError = null;
      low = from;
      high = to;
    });
  }

  void applyPrice() {
    final from = minPrice.text.trim(), to = maxPrice.text.trim();
    final valid = RegExp(r'^\d{1,9}(\.\d{1,2})?$');
    if ([from, to].any((v) => v.isNotEmpty && !valid.hasMatch(v))) {
      setState(() => priceError = 'Enter a price like 500 or 499.50.');
      return;
    }
    final min = from.isEmpty ? null : cents(from);
    final max = to.isEmpty ? null : cents(to);
    if (min != null && max != null && min > max) {
      setState(() => priceError = 'Maximum must be at least the minimum.');
      return;
    }
    FocusScope.of(context).unfocus();
    choosePrice(min, max);
  }

  void clear() {
    minPrice.clear();
    maxPrice.clear();
    change(() {
      sort = 'Featured';
      category = null;
      low = null;
      high = null;
      priceError = null;
      savedOnly = false;
      availableOnly = false;
    });
  }

  Widget priceField(TextEditingController controller, String label) =>
      TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => priceError = null),
        onSubmitted: (_) => applyPrice(),
        decoration: InputDecoration(
          labelText: label,
          prefixText: '₱ ',
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 14,
          ),
        ),
      );

  @override
  Widget build(BuildContext c) {
    final admin = ref.watch(currentAccount).admin,
        saved = ref.watch(savedProvider);
    final f = filter((saved.toList()..sort()).join(','));
    final cats = ref.watch(categoryProvider),
        batch = ref.watch(pageProvider(f));
    final theme = Theme.of(c), colors = theme.colorScheme;
    final priceActive = low != null || high != null;
    final activeCount = [
      category != null,
      sort != 'Featured',
      priceActive,
      savedOnly,
      availableOnly,
    ].where((active) => active).length;
    final editedPrice =
        minPrice.text.trim() != amount(low) ||
        maxPrice.text.trim() != amount(high);
    final under500 = low == null && high == 49999,
        from500 = low == 50000 && high == null;
    Widget heading(String title) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
    Widget chips(List<Widget> choices) =>
        Wrap(spacing: 6, runSpacing: 2, children: choices);
    Widget choice(String label, bool selected, VoidCallback onTap) =>
        ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          selectedColor: colors.primaryContainer,
          labelStyle: TextStyle(
            color: selected ? colors.onPrimaryContainer : colors.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
          onSelected: (_) => onTap(),
        );

    final controls = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Available only'),
          value: availableOnly,
          onChanged: (value) => change(() => availableOnly = value),
        ),
        const Divider(height: 26),
        heading('Category'),
        Load(
          cats,
          retry: () => ref.invalidate(categoryProvider),
          data: (list) => chips([
            choice(
              'All',
              category == null,
              () => change(() => category = null),
            ),
            for (final cat in list)
              choice(
                cat.name,
                category == cat.id,
                () => change(() => category = cat.id),
              ),
          ]),
        ),
        const Divider(height: 26),
        heading('Sort by'),
        chips([
          for (final entry in {
            'Featured': 'Featured',
            'Lowest price': 'Price: low to high',
            'Highest price': 'Price: high to low',
          }.entries)
            choice(
              entry.value,
              sort == entry.key,
              () => change(() => sort = entry.key),
            ),
        ]),
        const Divider(height: 26),
        heading('Price range'),
        chips([
          choice('Any price', !priceActive, () => choosePrice(null, null)),
          choice('Under ₱500', under500, () => choosePrice(null, 49999)),
          choice('₱500 & up', from500, () => choosePrice(50000, null)),
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: priceField(minPrice, 'Min')),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 7),
              child: Text('–'),
            ),
            Expanded(child: priceField(maxPrice, 'Max')),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          priceError ?? 'Leave either field blank for no limit.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: priceError == null ? null : colors.error,
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: editedPrice ? applyPrice : null,
          child: const Text('Apply price'),
        ),
        if (!admin) ...[
          const Divider(height: 26),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Saved only'),
            secondary: const Icon(Icons.bookmark_outline),
            value: savedOnly,
            onChanged: (v) => change(() => savedOnly = v),
          ),
        ],
        if (activeCount > 0 || editedPrice)
          TextButton(onPressed: clear, child: const Text('Reset filters')),
      ],
    );
    Widget panel() => Card(
      child: Padding(padding: const EdgeInsets.all(14), child: controls),
    );
    Widget filterButton({required bool compact}) => OutlinedButton.icon(
      onPressed: () => setState(() => filtersOpen = !filtersOpen),
      icon: Icon(filtersOpen ? Icons.close : Icons.tune, size: 16),
      label: Text(
        filtersOpen
            ? 'Hide filters'
            : compact
            ? (activeCount == 0 ? 'Filter' : 'Filter ($activeCount)')
            : activeCount == 0
            ? 'Filters'
            : 'Filters ($activeCount)',
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        visualDensity: VisualDensity.compact,
      ),
    );
    final categories = cats.value ?? const <Category>[];
    bool isBooks(Category cat) => cat.name.trim().toLowerCase() == 'books';
    Widget quick(String label, bool selected, VoidCallback toggle) =>
        ChoiceChip(
          label: Text(label),
          selected: selected,
          showCheckmark: false,
          onSelected: (_) => toggle(),
          shape: const StadiumBorder(),
          side: BorderSide.none,
          backgroundColor: colors.inverseSurface,
          selectedColor: colors.primaryContainer,
          labelStyle: TextStyle(
            fontSize: 12,
            color: selected
                ? colors.onPrimaryContainer
                : colors.onInverseSurface,
          ),
        );
    Widget quickSort(String label, String value) => quick(
      label,
      sort == value,
      () => change(() {
        sort = sort == value ? 'Featured' : value;
      }),
    );
    Widget quickCategory(Category cat) => quick(
      cat.name,
      category == cat.id,
      () => change(() => category = category == cat.id ? null : cat.id),
    );
    Widget quickFilters() => Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            scrollBehavior: ScrollConfiguration.of(c).copyWith(
              dragDevices: {
                ...ScrollConfiguration.of(c).dragDevices,
                PointerDeviceKind.mouse,
              },
            ),
            child: Row(
              spacing: 6,
              children: [
                quick(
                  'Available',
                  availableOnly,
                  () => change(() {
                    availableOnly = !availableOnly;
                  }),
                ),
                for (final cat in categories.where(isBooks)) quickCategory(cat),
                quickSort('Price: High', 'Highest price'),
                quickSort('Price: Low', 'Lowest price'),
                if (!admin)
                  quick(
                    'Saved',
                    savedOnly,
                    () => change(() {
                      savedOnly = !savedOnly;
                    }),
                  ),
                for (final cat in categories.where((cat) => !isBooks(cat)))
                  quickCategory(cat),
                quick(
                  'Under ₱500',
                  under500,
                  () => choosePrice(null, under500 ? null : 49999),
                ),
                quick(
                  '₱500 & up',
                  from500,
                  () => choosePrice(from500 ? null : 50000, null),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 6),
        filterButton(compact: true),
      ],
    );

    final rows = Load(
      batch,
      retry: () => ref.invalidate(pageProvider(f)),
      data: (result) {
        final pages = math.max(1, (result.count / pageSize).ceil());
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!admin)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      query.isNotEmpty
                          ? 'Search results'
                          : 'Shop the collection',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Text(
                    '${result.count} ${result.count == 1 ? 'item' : 'items'}',
                  ),
                ],
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  '${result.count} ${result.count == 1 ? 'item' : 'items'}',
                ),
              ),
            const SizedBox(height: 12),
            if (result.items.isEmpty)
              Empty(
                Icons.search_off,
                'No products here',
                page > 0
                    ? 'Return to the previous page.'
                    : query.isNotEmpty
                    ? 'Try the first few letters of another product name.'
                    : 'Change your filters or try another name.',
              ),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 760
                    ? 3
                    : box.maxWidth >= 480
                    ? 2
                    : 1;
                final width = (box.maxWidth - 12 * (columns - 1)) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final item in result.items)
                      SizedBox(
                        width: width,
                        child: ItemCard(item, onOpenItem: widget.onOpenItem),
                      ),
                  ],
                );
              },
            ),
            if (pages > 1 || page > 0)
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: _CatalogPagination(
                  page: page,
                  pages: pages,
                  onPage: turn,
                ),
              ),
          ],
        );
      },
    );
    final results = batch.hasError && page > 0
        ? Column(
            children: [
              rows,
              TextButton(
                onPressed: () => turn(0),
                child: const Text('Return to first page'),
              ),
            ],
          )
        : rows;
    return ShopPullToRefresh(
      onRefresh: () async {
        ref.invalidate(relatedProvider);
        await Future.wait([
          ref.refresh(categoryProvider.future),
          ref.refresh(pageProvider(f).future),
        ]).then<void>(
          (_) {},
          onError: (Object _) {
            // The catalog and category panels render provider errors.
          },
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(
          shopHorizontalPadding,
          8,
          shopHorizontalPadding,
          36,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: shopContentMaxWidth),
            child: Column(
              children: [
                _CatalogBanner(admin: admin),
                const SizedBox(height: 18),
                if (admin) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          query.isNotEmpty
                              ? 'Search results'
                              : 'Product catalog',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 12),
                      FloatingActionButton.extended(
                        heroTag: null,
                        onPressed: () => open(c, const ProductForm()),
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (query.isNotEmpty)
                  results
                else
                  LayoutBuilder(
                    builder: (_, box) {
                      final wide = box.maxWidth >= 840;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (wide || filtersOpen)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: filterButton(compact: false),
                            )
                          else
                            quickFilters(),
                          const SizedBox(height: 12),
                          if (wide && filtersOpen)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 280, child: panel()),
                                const SizedBox(width: 18),
                                Expanded(child: results),
                              ],
                            )
                          else ...[
                            if (filtersOpen) panel(),
                            results,
                          ],
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogBanner extends StatelessWidget {
  const _CatalogBanner({required this.admin});
  final bool admin;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? Colors.white : const Color(0xff24276e);
    return LayoutBuilder(
      builder: (context, box) {
        final compact = box.maxWidth < 540;
        final pad = compact ? 20.0 : 36.0;
        final sealWidth = (box.maxWidth * .45).clamp(142.0, 336.0).toDouble();
        return DecoratedBox(
          decoration: BoxDecoration(
            color: dark ? const Color(0xff111e2e) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? Colors.white12 : const Color(0xffdfe1ee),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Positioned(
                  right: -sealWidth * .06,
                  bottom: -sealWidth * .23,
                  child: Image.asset(
                    'assets/branding/seal-${dark ? "White" : "Blue"}.webp',
                    width: sealWidth,
                    height: sealWidth,
                    fit: BoxFit.contain,
                    excludeFromSemantics: true,
                    opacity: AlwaysStoppedAnimation<double>(
                      compact ? .13 : .23,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(pad, pad, pad, pad),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: compact ? .79 : .65,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            admin ? 'MAGISTORE  /  STAFF' : 'MAGISTORE',
                            style: TextStyle(
                              color: ink,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 9),
                          Semantics(
                            header: true,
                            child: Text(
                              admin ? 'Catalog desk' : 'Campus essentials',
                              style: TextStyle(
                                fontFamily: 'Cinzel',
                                fontWeight: FontWeight.w600,
                                color: ink,
                                height: 1.14,
                                fontSize: compact ? 25 : 39,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: 34,
                            height: 2,
                            color: dark ? Colors.white54 : ink,
                          ),
                          const SizedBox(height: 9),
                          Text(
                            admin
                                ? 'Inventory & student orders'
                                : 'Ateneo Book Store',
                            style: TextStyle(
                              color: ink,
                              fontSize: compact ? 12 : 14,
                              fontWeight: FontWeight.w500,
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
      },
    );
  }
}

class _CatalogPagination extends StatelessWidget {
  const _CatalogPagination({
    required this.page,
    required this.pages,
    required this.onPage,
  });
  final int page, pages;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        const target = 44.0;
        const gap = 4.0;
        final slots = ((box.maxWidth + gap) / (target + gap)).floor() - 2;
        final visible = math.min(pages, math.max(1, math.min(7, slots)));
        final first = (page - (visible - 1) ~/ 2)
            .clamp(0, pages - visible)
            .toInt();

        Widget arrow(String label, IconData icon, bool enabled, int next) =>
            SizedBox.square(
              dimension: target,
              child: IconButton(
                tooltip: label,
                onPressed: enabled ? () => onPage(next) : null,
                icon: Icon(icon, size: 18),
              ),
            );

        return Semantics(
          container: true,
          label: 'Page ${page + 1} of $pages',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: gap,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              arrow('Previous page', Icons.chevron_left, page > 0, page - 1),
              for (var i = first; i < first + visible; i++)
                Semantics(
                  selected: i == page,
                  child: SizedBox.square(
                    dimension: target,
                    child: TextButton(
                      onPressed: () {
                        if (i != page) onPage(i);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: i == page
                            ? colors.onPrimary
                            : colors.onSurface,
                        backgroundColor: i == page
                            ? colors.primary
                            : colors.surface,
                        side: BorderSide(
                          color: i == page
                              ? colors.primary
                              : colors.outlineVariant,
                        ),
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        minimumSize: const Size(36, 34),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text('${i + 1}'),
                    ),
                  ),
                ),
              arrow(
                'Next page',
                Icons.chevron_right,
                page + 1 < pages,
                page + 1,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ItemCard extends ConsumerWidget {
  const ItemCard(this.item, {super.key, required this.onOpenItem});
  final ValueChanged<Item> onOpenItem;
  final Item item;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final admin = ref.watch(currentAccount).admin,
        saved = ref.watch(savedProvider).contains(item.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                InkWell(onTap: () => onOpenItem(item), child: Photo(item)),
                if (!admin)
                  PositionedDirectional(
                    end: 8,
                    top: 8,
                    child: IconButton.filledTonal(
                      iconSize: 18,
                      tooltip: saved ? 'Unsave product' : 'Save product',
                      onPressed: () =>
                          ref.read(savedProvider.notifier).toggle(item.id),
                      icon: Icon(
                        saved ? Icons.bookmark : Icons.bookmark_border,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.category.name, style: Theme.of(c).textTheme.bodySmall),
            InkWell(
              onTap: () => onOpenItem(item),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(c).textTheme.titleMedium,
              ),
            ),
            Text(
              '${pesos(item.price)}  ·  ${item.stock == 0 ? 'Out of stock' : '${item.stock} left'}',
            ),
            const SizedBox(height: 8),
            if (admin)
              Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: () => open(c, ProductForm(item: item)),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      if (await confirm(
                            c,
                            'Delete ${item.name}?',
                            'Past orders will keep the name and price paid.',
                          ) &&
                          c.mounted) {
                        await perform(
                          c,
                          () =>
                              ref.read(managerProvider).removeProduct(item.id),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              )
            else
              AddButton(item),
          ],
        ),
      ),
    );
  }
}

class AddButton extends ConsumerWidget {
  const AddButton(
    this.item, {
    super.key,
    this.onCheckout,
    this.secondary = false,
  });
  final VoidCallback? onCheckout;
  final bool secondary;
  final Item item;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final qty = bagQuantity(ref.watch(bagProvider), item.id);
    final checkout = onCheckout;
    final VoidCallback? action = qty >= item.stock
        ? (item.stock > 0 ? checkout : null)
        : () => perform(c, () async {
            final size = item.needsSize
                ? await showDialog<String>(
                    context: c,
                    builder: (context) => AlertDialog(
                      title: const Text('Choose a size'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final size in uniformSizes)
                                OutlinedButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(size),
                                  child: Text(size),
                                ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  )
                : null;
            if (!c.mounted || (item.needsSize && size == null)) return;
            ref.read(bagProvider.notifier).add(item, size: size);
            if (checkout != null) {
              checkout();
            } else {
              toast(
                c,
                size == null
                    ? 'Added ${item.name} to your bag'
                    : 'Added ${item.name} (size $size) to your bag',
              );
            }
          });
    final label = Text(
      item.stock == 0
          ? (checkout == null ? 'Out of stock' : 'Buy now')
          : checkout != null
          ? 'Buy now'
          : qty >= item.stock
          ? 'All in bag'
          : item.needsSize && !secondary
          ? 'Choose size'
          : 'Add to bag',
      textAlign: TextAlign.center,
    );
    if (secondary) {
      return OutlinedButton(onPressed: action, child: label);
    }
    if (checkout != null) {
      return FilledButton(onPressed: action, child: label);
    }
    return FilledButton.icon(
      onPressed: action,
      icon: const Icon(Icons.shopping_bag_outlined, size: 17),
      label: label,
    );
  }
}

class ItemDetail extends ConsumerWidget {
  const ItemDetail(
    this.item, {
    super.key,
    required this.onBack,
    required this.onCheckout,
    required this.onOpenItem,
  });
  final Item item;
  final VoidCallback onBack;
  final VoidCallback onCheckout;
  final ValueChanged<Item> onOpenItem;

  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final p = item;
    final theme = Theme.of(c);
    final canBuy = !ref.watch(currentAccount).admin;
    final original = demo.catalog
        .where((v) => v.active && !v.isStudyItem && v.image == p.image)
        .firstOrNull;
    final media = original != null
        ? ProductViewer360(product: original)
        : Photo(p, height: 360);
    return LayoutBuilder(
      builder: (_, constraints) {
        final wide = constraints.maxWidth >= 760 + 2 * shopHorizontalPadding;
        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(p.category.name, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(p.name, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(pesos(p.price), style: theme.textTheme.titleLarge),
            const SizedBox(height: 18),
            Text(p.description),
            const SizedBox(height: 16),
            Text(p.stock == 0 ? 'Out of stock' : '${p.stock} in stock'),
            if (canBuy && wide) ...[const SizedBox(height: 8), AddButton(p)],
            const Divider(height: 36),
            Text('Related products', style: theme.textTheme.titleLarge),
            Load(
              ref.watch(relatedProvider(p)),
              retry: () => ref.invalidate(relatedProvider(p)),
              data: (items) => items.isEmpty
                  ? const Text('No other products in this category yet.')
                  : Column(
                      children: [
                        for (final x in items)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: SizedBox(
                              width: 58,
                              child: Photo(x, height: 56),
                            ),
                            title: Text(x.name),
                            subtitle: Text(pesos(x.price)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => onOpenItem(x),
                          ),
                      ],
                    ),
            ),
          ],
        );
        final content = ListView(
          primary: false,
          padding: const EdgeInsets.fromLTRB(
            shopHorizontalPadding,
            8,
            shopHorizontalPadding,
            36,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: shopContentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: onBack,
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: media),
                          const SizedBox(width: 32),
                          Expanded(child: info),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [media, const SizedBox(height: 20), info],
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
        if (wide || !canBuy) return content;
        return Column(
          children: [
            Expanded(child: content),
            Material(
              color: theme.colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  shopHorizontalPadding,
                  8,
                  shopHorizontalPadding,
                  8,
                ),
                child: Row(
                  children: [
                    Expanded(child: AddButton(p, secondary: true)),
                    const SizedBox(width: 12),
                    Expanded(child: AddButton(p, onCheckout: onCheckout)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
