import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components.dart';
import 'store.dart';
import 'theme.dart';

class NotificationsScreen extends StatelessWidget {
  final Store store;
  const NotificationsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final readyOrders = store.orders.where((o) => o.ready).toList();
    final preparingOrders =
        store.orders.where((o) => !o.ready && !o.collected).toList();
    final collectedOrders = store.orders.where((o) => o.collected).toList();

    return AppFrame(
      store: store,
      active: 'Alerts',
      child: PageBody(
        maxWidth: 900,
        children: [
          const SectionHeading(
            'Order Notifications',
            'Real-time updates on your bookstore orders and pickup readiness.',
          ),
          if (store.orders.isEmpty)
            const EmptyState(
              title: 'No order updates yet',
              message:
                  'Place an order at MagiStore to receive instant alerts when your items are ready for pickup.',
              icon: Icons.notifications_none_outlined,
            ),
          if (readyOrders.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${readyOrders.length} Order${readyOrders.length > 1 ? 's' : ''} Ready for Pickup!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Proceed to Main Bookstore · Web Order Express Window.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'READY FOR COLLECTION',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Brand.blue,
                  ),
            ),
            const SizedBox(height: 12),
            ...readyOrders.map((o) => _buildReadyCard(context, o)),
            const SizedBox(height: 24),
          ],
          if (preparingOrders.isNotEmpty) ...[
            Text(
              'IN PREPARATION',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Brand.muted,
                  ),
            ),
            const SizedBox(height: 12),
            ...preparingOrders.map((o) => _buildPreparingCard(context, o)),
            const SizedBox(height: 24),
          ],
          if (collectedOrders.isNotEmpty) ...[
            Text(
              'COMPLETED PICKUPS',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: Brand.muted,
                  ),
            ),
            const SizedBox(height: 12),
            ...collectedOrders.map((o) => _buildCollectedCard(context, o)),
          ],
        ],
      ),
    );
  }

  Widget _buildReadyCard(BuildContext context, Order o) {
    final itemCount = o.lines.fold(0, (sum, l) => sum + l.quantity);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Brand.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Ready for Pickup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  o.id,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Brand.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Your order is packed and waiting at ${o.location}!',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pickup Counter: Web Order Express Window (Counter 2)\nPickup Window: ${o.slot}',
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: Brand.muted,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Brand.productSurface(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined,
                      size: 16, color: Brand.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$itemCount item${itemCount > 1 ? 's' : ''} · ${o.lines.map((l) => '${l.product.name} (${l.variant})').join(', ')}',
                      style: const TextStyle(fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    money(o.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Brand.navy,
                  foregroundColor: Brand.white,
                ),
                onPressed: () => context.go('/orders/${o.id}'),
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text(
                  'View Claim Ticket & QR',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreparingCard(BuildContext context, Order o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Brand.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Brand.blue.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_top_rounded,
                          size: 13, color: Brand.blue),
                      const SizedBox(width: 5),
                      Text(
                        o.stages[o.stage],
                        style: const TextStyle(
                          color: Brand.blue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  o.id,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Brand.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              o.reservation
                  ? 'Reservation queued · Awaiting stock replenishment'
                  : 'The bookstore team is assembling your order.',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Selected Location: ${o.location}',
              style: const TextStyle(fontSize: 11.5, color: Brand.muted),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => context.go('/orders/${o.id}'),
                  child: const Text('View details →'),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF64748B),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () {
                    store.prepare(o);
                    toast(
                      context,
                      'Order ${o.id} marked ready for pickup!',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  },
                  icon: const Icon(Icons.bolt_rounded,
                      size: 14, color: Color(0xFF64748B)),
                  label: const Text(
                    'Simulate: Staff Marks Ready',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectedCard(BuildContext context, Order o) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Brand.productSurface(context).withValues(alpha: .5),
      child: ListTile(
        leading: const Icon(Icons.task_alt, color: Colors.teal, size: 24),
        title: Text(
          'Order ${o.id}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        subtitle: Text(
          'Collected at ${o.location} · ${money(o.total)}',
          style: const TextStyle(fontSize: 11.5),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 13),
        onTap: () => context.go('/orders/${o.id}'),
      ),
    );
  }
}
