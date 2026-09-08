import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'checkout_screen.dart';
import 'components.dart';
import 'store.dart';
import 'theme.dart';

class OrdersScreen extends StatelessWidget {
  final Store store;
  const OrdersScreen({super.key, required this.store});
  @override
  Widget build(BuildContext context) => AppFrame(
    store: store,
    active: 'My orders',
    child: PageBody(
      maxWidth: 1000,
      children: [
        const SectionHeading(
          'Your campus pickups',
          'Every essential, one step closer.',
        ),
        if (store.readyOrdersCount > 0)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.teal.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: Colors.teal.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${store.readyOrdersCount} order(s) ready for pickup now!',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Show your claim QR at the Main Bookstore Web Order Express Window.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/notifications'),
                  child: const Text('Alerts →'),
                ),
              ],
            ),
          ),
        if (store.orders.isEmpty)
          const EmptyState(
            title: 'Your first pickup is waiting to happen',
            message: 'Complete your checkout to find your claim ticket here.',
            icon: Icons.confirmation_number_outlined,
          ),
        ...store.orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Icon(
                  o.collected
                      ? Icons.task_alt
                      : o.reservation
                      ? Icons.bookmark_border
                      : Icons.qr_code_2,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                title: Text(
                  o.id,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${o.stages[o.stage]}\n${o.location} · ${money(o.total)}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => context.go('/orders/${o.id}'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderScreen extends StatefulWidget {
  final Store store;
  final Order order;
  const OrderScreen({super.key, required this.store, required this.order});
  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  bool reminder = true, scanMode = false;
  String slot = '';
  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final ticket = Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Text(
              'YOUR EXPRESS CLAIM TICKET',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Brand.muted,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              o.location,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Proceed to the Web Order Express Window.\nWhen ready, collect at Counter 2.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary
                    .withValues(alpha: .06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.door_front_door_outlined),
                  Icon(Icons.more_horiz),
                  Icon(Icons.storefront_outlined),
                  Icon(Icons.arrow_forward, size: 18),
                  Icon(Icons.qr_code_scanner),
                ],
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'ILLUSTRATIVE DIRECTIONS · VERIFY ON CAMPUS',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: .8,
                color: Brand.muted,
              ),
            ),
            const SizedBox(height: 22),
            if (!o.collected)
              Semantics(
                label: 'Claim QR for ${o.id}',
                child: Container(
                  padding: EdgeInsets.all(scanMode ? 24 : 12),
                  decoration: BoxDecoration(
                    color: Brand.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: QrImageView(
                    data: 'magisstore:claim:${o.claim}',
                    size: 220,
                    backgroundColor: Brand.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    gapless: true,
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.all(45),
                child: Icon(
                  Icons.check_circle_outline,
                  color: Brand.green,
                  size: 100,
                ),
              ),
            const SizedBox(height: 14),
            SelectableText(
              o.id,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: o.id));
                toast(
                  context,
                  'Order reference copied.',
                  icon: Icons.check_circle_outline_rounded,
                );
              },
              icon: const Icon(Icons.copy, size: 14),
              label: const Text('Copy order reference'),
            ),
            const SizedBox(height: 8),
            Text(
              o.slot,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (!o.collected)
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Scan-friendly display',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: const Text(
                  'White QR surround. Set device brightness manually.',
                  style: TextStyle(fontSize: 10),
                ),
                value: scanMode,
                onChanged: (v) => setState(() => scanMode = v),
              ),
            const Divider(),
            const SizedBox(height: 10),
            const Text(
              'PRESENT THIS CODE AT EXPRESS PICKUP',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color: Brand.purple,
              ),
            ),
          ],
        ),
      ),
    );
    final status = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your order, on its way',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                ...List.generate(
                  o.stages.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i <= o.stage
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .08),
                          ),
                          child: Icon(
                            i < o.stage
                                ? Icons.check
                                : i == o.stage
                                ? Icons.circle
                                : Icons.more_horiz,
                            size: i == o.stage ? 10 : 16,
                            color: i <= o.stage
                                ? Theme.of(context).colorScheme.onPrimary
                                : Brand.muted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            o.stages[i],
                            style: TextStyle(
                              fontWeight: i == o.stage
                                  ? FontWeight.w800
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (i == o.stage)
                          const Text(
                            'NOW',
                            style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 1,
                              color: Brand.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (o.collectedAt != null)
                  Text(
                    'Collected: ${DateTime.parse(o.collectedAt!).toLocal()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (o.reservation && o.stage == 2) ...[
                  const Text(
                    'Your reservation has restocked. Choose a pickup window:',
                  ),
                  const SizedBox(height: 12),
                  SlotPicker(
                    store: widget.store,
                    location: o.location,
                    selected: slot,
                    onChanged: (v) => setState(() => slot = v),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () {
                      final error = widget.store.schedule(o, slot);
                      toast(
                        context,
                        error ?? 'Pickup scheduled. Your ticket is ready.',
                        icon: error == null
                            ? Icons.check_circle_outline_rounded
                            : Icons.error_outline_rounded,
                      );
                    },
                    child: const Text('Confirm pickup window'),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ...o.lines.map(
                  (l) => Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                '${l.variant} · ${l.quantity} × ${money(l.product.price)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Text(money(l.total)),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 13),
                Row(
                  children: [
                    const Expanded(child: Text('Total paid')),
                    Text(
                      money(o.total),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Via ${o.method} · Payment confirmed',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        const InfoBox(
          'We’ll prepare your order for your selected window. Bring your Ateneo ID and this ticket to the express pickup desk.',
          icon: Icons.storefront_outlined,
        ),
      ],
    );
    return AppFrame(
      store: widget.store,
      active: 'My orders',
      child: PageBody(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/orders'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('All orders'),
          ),
          const SizedBox(height: 20),
          SectionHeading(
            o.collected
                ? 'All yours. See you on campus.'
                : (o.ready
                    ? 'Your order is ready for pickup!'
                    : (o.reservation
                        ? 'Your spot is secured.'
                        : 'You’re all set. Skip the line.')),
            'Your digital order slip and payment are complete. Go straight to express pickup when ready.',
          ),
          if (o.ready) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.teal.shade400, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: Colors.teal.shade700, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready for Pickup at ${o.location}!',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.teal.shade900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Proceed to Counter 2 (Web Order Express Window) with your claim QR below.',
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
          ] else if (!o.collected) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF64748B),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  onPressed: () {
                    widget.store.prepare(o);
                    toast(
                      context,
                      'Order status updated: Ready for pickup!',
                      icon: Icons.check_circle_outline_rounded,
                    );
                  },
                  icon: const Icon(
                    Icons.bolt_rounded,
                    size: 13,
                    color: Color(0xFF64748B),
                  ),
                  label: const Text(
                    'Staff preview: mark ready',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: .2,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (reminder && !o.collected) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text(
                  'Bring your Ateneo ID and this QR code.',
                  style: TextStyle(fontSize: 13),
                ),
                trailing: IconButton(
                  tooltip: 'Dismiss reminder',
                  onPressed: () => setState(() => reminder = false),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          LayoutBuilder(
            builder: (context, box) => box.maxWidth > 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ticket),
                      const SizedBox(width: 28),
                      Expanded(child: status),
                    ],
                  )
                : Column(
                    children: [ticket, const SizedBox(height: 20), status],
                  ),
          ),
        ],
      ),
    );
  }
}
