import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../providers/shop_providers.dart';
import '../services/shop_service.dart';
import 'common.dart';

const _statusLabels = {
  'done': 'Processing',
  'ready': 'To claim',
  'collected': 'Collected',
};

class BagHub extends StatelessWidget {
  const BagHub({
    super.key,
    required this.shop,
    required this.history,
    required this.onHistoryChanged,
    this.orderId,
    this.hasPickupUpdate = false,
  });
  final VoidCallback shop;
  final bool history;
  final int? orderId;
  final bool hasPickupUpdate;
  final ValueChanged<bool> onHistoryChanged;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: shop,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to shopping'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                const ButtonSegment(
                  value: false,
                  label: Text('Bag'),
                  icon: Icon(Icons.shopping_bag_outlined),
                ),
                ButtonSegment(
                  value: true,
                  label: const Text('My orders'),
                  icon: Badge(
                    isLabelVisible: hasPickupUpdate,
                    label: const Semantics(
                      label: 'Order ready for pickup',
                      excludeSemantics: true,
                      child: Text('!'),
                    ),
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                ),
              ],
              selected: {history},
              onSelectionChanged: (selection) =>
                  onHistoryChanged(selection.single),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: history ? 1 : 0,
              children: [
                BagPage(history: () => onHistoryChanged(true)),
                history
                    ? OrdersPage(
                        key: ValueKey(orderId),
                        initialOrderId: orderId,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class BagPage extends ConsumerStatefulWidget {
  const BagPage({required this.history, super.key});
  final VoidCallback history;
  @override
  ConsumerState<BagPage> createState() => _BagPageState();
}

class _BagPageState extends ConsumerState<BagPage> {
  bool busy = false;
  String? error;
  Receipt? receipt;
  Future<void> checkout() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await ref.read(bagProvider.notifier).place();
      if (mounted) setState(() => receipt = r);
    } catch (e) {
      if (mounted) setState(() => error = shopMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    ref.listen(bagProvider, (old, next) {
      if (next.isNotEmpty && receipt != null) {
        setState(() {
          receipt = null;
          error = null;
        });
      }
    });
    return ShopPullToRefresh(
      onRefresh: () async {
        if (!busy) await perform(c, ref.read(bagProvider.notifier).refresh);
      },
      child: _content(c),
    );
  }

  Widget _content(BuildContext c) {
    final bag = ref.watch(bagProvider), edit = ref.read(bagProvider.notifier);
    if (receipt != null && bag.isEmpty) {
      final r = receipt!;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Empty(
            Icons.check_circle_outline,
            'Order confirmed',
            'Your order has been saved.',
          ),
          Card(
            child: ListTile(
              title: Text('Order #${r.id}'),
              subtitle: const Text('Processing · We’re preparing your order.'),
              trailing: Text(pesos(r.total)),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.history,
            child: const Text('View my orders'),
          ),
        ],
      );
    }
    if (bag.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const Empty(
            Icons.shopping_bag_outlined,
            'Your bag is empty',
            'Find something for your next class.',
          ),
        ],
      );
    }
    final total = bag.values.fold(0, (s, l) => s + l.quantity * l.item.price),
        count = bag.values.fold(0, (s, l) => s + l.quantity);
    final unavailable = bag.values.any(
      (e) => bagQuantity(bag, e.item.id) > e.item.stock,
    );
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text('Your bag', style: Theme.of(c).textTheme.headlineMedium),
        for (final l in bag.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(width: 72, child: Photo(l.item, height: 72)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.item.name,
                            style: Theme.of(c).textTheme.titleMedium,
                          ),
                          if (l.size != null) Text('Size: ${l.size}'),
                          Text(
                            '${pesos(l.item.price)} each  ·  ${pesos(l.item.price * l.quantity)}',
                          ),
                          if (bagQuantity(bag, l.item.id) > l.item.stock)
                            Text(
                              'Only ${l.item.stock} available. Adjust or remove this item.',
                              style: TextStyle(
                                color: Theme.of(c).colorScheme.error,
                              ),
                            ),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              IconButton(
                                tooltip: 'Decrease quantity',
                                onPressed: busy
                                    ? null
                                    : () => edit.setQuantity(
                                        l.item,
                                        l.quantity - 1,
                                        size: l.size,
                                      ),
                                icon: const Icon(Icons.remove_circle_outline),
                              ),
                              Text('${l.quantity}'),
                              IconButton(
                                tooltip: 'Increase quantity',
                                onPressed:
                                    busy ||
                                        bagQuantity(bag, l.item.id) >=
                                            l.item.stock
                                    ? null
                                    : () => perform(
                                        c,
                                        () async =>
                                            edit.add(l.item, size: l.size),
                                      ),
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Remove item',
                                onPressed: busy
                                    ? null
                                    : () => edit.setQuantity(
                                        l.item,
                                        0,
                                        size: l.size,
                                      ),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          '$count items  ·  Estimated total ${pesos(total)}',
          style: Theme.of(c).textTheme.titleLarge,
        ),
        const Text('Checkout uses the current store price and stock.'),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: busy || unavailable ? null : checkout,
          child: Text(busy ? 'Placing order…' : 'Place order'),
        ),
      ],
    );
  }
}

String orderAlertKey(int id) => 'order:$id';
String stockAlertKey(Item item) => 'stock:${item.id}:${item.stock}';

class ShopNotifications extends PopupMenuEntry<Object> {
  const ShopNotifications({super.key, required this.readAlerts});
  final Set<String> readAlerts;

  @override
  double get height => 48;

  @override
  bool represents(Object? value) => false;

  @override
  State<ShopNotifications> createState() => _ShopNotificationsState();
}

class _ShopNotificationsState extends State<ShopNotifications> {
  @override
  Widget build(BuildContext context) => Consumer(builder: _buildPanel);

  Widget _buildPanel(BuildContext context, WidgetRef ref, Widget? child) {
    final admin = ref.watch(currentAccount).admin;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Notifications',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
          const Divider(height: 12),
          Text(
            admin ? 'New orders' : 'Ready for pickup',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          Load(
            ref.watch(orderNotificationsProvider),
            retry: () => ref.invalidate(orderNotificationsProvider),
            data: (ids) {
              final unread = ids
                  .where((id) => !widget.readAlerts.contains(orderAlertKey(id)))
                  .toList();
              return unread.isEmpty
                  ? Text(
                      ids.isNotEmpty
                          ? 'No unread order alerts.'
                          : admin
                          ? 'No orders are waiting to be processed.'
                          : 'No orders are ready for pickup yet.',
                    )
                  : Column(
                      children: [
                        for (final id in unread)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              admin
                                  ? Icons.receipt_long_outlined
                                  : Icons.storefront_outlined,
                            ),
                            title: Text(
                              admin
                                  ? 'New order #$id'
                                  : 'Order #$id is ready to claim',
                            ),
                            subtitle: Text(
                              admin
                                  ? 'Waiting to be processed'
                                  : 'Tap to view your order',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, id),
                          ),
                      ],
                    );
            },
          ),
          const Divider(height: 28),
          Text('Stock alerts', style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          Load(
            ref.watch(stockNotificationsProvider),
            retry: () => ref.invalidate(stockNotificationsProvider),
            data: (items) {
              final unread = items
                  .where(
                    (item) => !widget.readAlerts.contains(stockAlertKey(item)),
                  )
                  .toList();
              return unread.isEmpty
                  ? Text(
                      items.isNotEmpty
                          ? 'No unread stock alerts.'
                          : admin
                          ? 'No low or out-of-stock products.'
                          : 'No stock alerts for saved items or items in your bag.',
                    )
                  : Column(
                      children: [
                        for (final item in unread)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              item.stock == 0
                                  ? Icons.remove_shopping_cart_outlined
                                  : Icons.inventory_2_outlined,
                              color: item.stock == 0
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.primary,
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              item.stock == 0
                                  ? 'Out of stock'
                                  : 'Low stock · ${item.stock} left',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.pop(context, item),
                          ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }
}

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key, this.initialOrderId});
  final int? initialOrderId;

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  String? status;
  final updating = <int>{};

  Future<void> updateStatus(Purchase order, String? next) async {
    if (next == null || next == order.status || updating.contains(order.id)) {
      return;
    }
    setState(() => updating.add(order.id));
    try {
      await perform(
        context,
        () => ref.read(managerProvider).status(order.id, next),
      );
    } finally {
      if (mounted) setState(() => updating.remove(order.id));
    }
  }

  Future<void> confirmOrderPickup(Purchase order) async {
    if (updating.contains(order.id)) return;
    final approved = await confirm(
      context,
      'Confirm pickup for order #${order.id}?',
      'Only confirm after you have received all the items in this order.',
      actionLabel: 'Mark as collected',
    );
    if (!mounted || !approved || updating.contains(order.id)) return;
    setState(() => updating.add(order.id));
    try {
      await perform(context, () async {
        await ref.read(pickupProvider).confirm(order.id);
        if (mounted) toast(context, 'Order #${order.id} marked as collected.');
      });
    } finally {
      if (mounted) setState(() => updating.remove(order.id));
    }
  }

  @override
  Widget build(BuildContext c) {
    final admin = ref.watch(currentAccount).admin;
    final theme = Theme.of(c);
    final colors = theme.colorScheme;
    final list = ShopPullToRefresh(
      onRefresh: () async {
        try {
          await ref.refresh(ordersProvider.future).then<void>((_) {});
        } catch (_) {
          // The order list renders the provider error and retry action.
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            admin ? 'All orders' : 'Order history',
            style: theme.textTheme.headlineMedium,
          ),
          if (admin) ...[
            const SizedBox(height: 4),
            Text(
              'Review student orders and manage pickups.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Load(
            ref.watch(ordersProvider),
            retry: () => ref.invalidate(ordersProvider),
            data: (orders) {
              final counts = <String, int>{};
              if (admin) {
                for (final order in orders) {
                  counts.update(order.status, (n) => n + 1, ifAbsent: () => 1);
                }
              }
              final visible = orders
                  .where((order) => status == null || order.status == status)
                  .toList();
              final selected = visible.indexWhere(
                (order) => order.id == widget.initialOrderId,
              );
              if (selected > 0) {
                visible.insert(0, visible.removeAt(selected));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (orders.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ChoiceChip(
                          label: Text(admin ? 'All · ${orders.length}' : 'All'),
                          selected: status == null,
                          onSelected: (_) => setState(() => status = null),
                        ),
                        for (final entry in _statusLabels.entries)
                          ChoiceChip(
                            label: Text(
                              admin
                                  ? '${entry.value} · ${counts[entry.key] ?? 0}'
                                  : entry.value,
                            ),
                            selected: status == entry.key,
                            onSelected: (_) =>
                                setState(() => status = entry.key),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (visible.isEmpty)
                    Empty(
                      Icons.receipt_long_outlined,
                      orders.isEmpty
                          ? 'No orders yet'
                          : 'No orders with this status',
                      orders.isNotEmpty
                          ? 'Try another status to see more orders.'
                          : admin
                          ? 'New student orders will appear here.'
                          : 'Your first order will appear here after checkout.',
                    ),
                  for (final order in visible)
                    Card(
                      margin: admin ? const EdgeInsets.only(bottom: 12) : null,
                      elevation: admin ? 0 : null,
                      color: admin ? colors.surface : null,
                      shape: admin
                          ? RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: order.id == widget.initialOrderId
                                    ? colors.primary
                                    : colors.outlineVariant,
                              ),
                            )
                          : null,
                      clipBehavior: admin ? Clip.antiAlias : null,
                      child: ExpansionTile(
                        key: ValueKey(order.id),
                        initiallyExpanded: order.id == widget.initialOrderId,
                        shape: admin ? const Border() : null,
                        collapsedShape: admin ? const Border() : null,
                        title: Text(
                          'Order #${order.id}  ·  ${pesos(order.total)}',
                          style: admin
                              ? theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                )
                              : null,
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (admin)
                              Text(
                                order.customer?.displayName ??
                                    'Unknown student',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Wrap(
                              spacing: 10,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  MaterialLocalizations.of(
                                    c,
                                  ).formatMediumDate(order.date),
                                ),
                                _OrderStatusBadge(order.status),
                              ],
                            ),
                          ],
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          12,
                        ),
                        children: [
                          if (admin) ...[
                            Divider(height: 16, color: colors.outlineVariant),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.person_outline),
                              title: const Text('Student account'),
                              subtitle: SelectableText(
                                (order.customer?.email.isNotEmpty ?? false)
                                    ? order.customer!.email
                                    : 'Account ID: ${order.userId}',
                              ),
                            ),
                            Divider(height: 16, color: colors.outlineVariant),
                          ],
                          if (!admin && order.status == 'ready')
                            const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.storefront_outlined),
                              title: Text('Ready for pickup'),
                              subtitle: Text(
                                'Show your order number when you claim it.',
                              ),
                            ),
                          for (final l in order.lines)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l.size == null
                                    ? l.name
                                    : '${l.name} · Size ${l.size}',
                              ),
                              subtitle: Text(
                                '${l.quantity} × ${pesos(l.price)}',
                              ),
                              trailing: Text(pesos(l.quantity * l.price)),
                            ),
                          if (!admin && order.status == 'ready')
                            FilledButton.icon(
                              onPressed: updating.contains(order.id)
                                  ? null
                                  : () => confirmOrderPickup(order),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Confirm pickup'),
                            ),
                          if (admin) ...[
                            Divider(height: 20, color: colors.outlineVariant),
                            InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Order status',
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _statusLabels.containsKey(order.status)
                                      ? order.status
                                      : null,
                                  isExpanded: true,
                                  isDense: true,
                                  items: [
                                    for (final entry in _statusLabels.entries)
                                      DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ),
                                  ],
                                  onChanged: updating.contains(order.id)
                                      ? null
                                      : (value) => updateStatus(order, value),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
    return admin
        ? Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: list,
            ),
          )
        : list;
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (status) {
      'ready' => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.storefront_outlined,
      ),
      'collected' => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.check_circle_outline,
      ),
      _ => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
        Icons.schedule_outlined,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 4),
            Text(
              _statusLabels[status] ?? status,
              style: TextStyle(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}
