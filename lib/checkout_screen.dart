import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components.dart';
import 'store.dart';
import 'theme.dart';

class CartScreen extends StatelessWidget {
  final Store store;
  const CartScreen({super.key, required this.store});
  @override
  Widget build(BuildContext context) => AppFrame(
    store: store,
    child: PageBody(
      maxWidth: 1000,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Keep exploring'),
        ),
        const SizedBox(height: 20),
        SectionHeading(
          'Your bag',
          '${store.count} essentials for your Ateneo everyday.',
        ),
        if (store.cart.isEmpty)
          const EmptyState(
            title: 'A little empty in here',
            message: 'Find something that makes your campus day better.',
          )
        else ...[
          if (store.cart.first.reservation) ...[
            const InfoBox(
              'Reservation bag: these items are paid in advance and collected after restock. Available items use a separate checkout.',
            ),
            const SizedBox(height: 20),
          ],
          ...store.cart.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: LayoutBuilder(
                    builder: (context, box) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: box.maxWidth < 450 ? 65 : 110,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Brand.productSurface(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ProductImage(product: line.product),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.product.name,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                line.variant,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 7),
                              Text(
                                '${money(line.product.price)} each',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 16,
                                runSpacing: 10,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  QuantityControl(
                                    value: line.quantity,
                                    onChanged: (value) {
                                      final error = store.quantity(line, value);
                                      if (error != null) {
                                        toast(
                                          context,
                                          error,
                                          icon: Icons.error_outline_rounded,
                                        );
                                      }
                                    },
                                  ),
                                  Text(
                                    money(line.total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remove ${line.product.name}',
                          onPressed: () => store.quantity(line, 0),
                          icon: const Icon(Icons.close, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _sum('Subtotal', money(store.total)),
                  const SizedBox(height: 12),
                  _sum('Bookstore pickup', 'Free'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  _sum('Total', money(store.total), bold: true),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('checkout'),
                      onPressed: () => context.go('/checkout'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      iconAlignment: IconAlignment.end,
                      label: const Text('Choose pickup & checkout'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

Widget _sum(String title, String value, {bool bold = false}) => Row(
  children: [
    Expanded(
      child: Text(
        title,
        style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
      ),
    ),
    Text(
      value,
      style: TextStyle(fontSize: bold ? 22 : 14, fontWeight: FontWeight.w700),
    ),
  ],
);

class SlotPicker extends StatelessWidget {
  final Store store;
  final String location, selected;
  final ValueChanged<String> onChanged;
  const SlotPicker({
    super.key,
    required this.store,
    required this.location,
    required this.selected,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: slots.map((slot) {
      final available = store.slotOpen(location, slot);
      return ChoiceChip(
        label: Text(
          '$slot${available ? '' : ' · Full'}',
          style: const TextStyle(fontSize: 12),
        ),
        selected: selected == slot,
        onSelected: available ? (_) => onChanged(slot) : null,
      );
    }).toList(),
  );
}

class CheckoutScreen extends StatefulWidget {
  final Store store;
  const CheckoutScreen({super.key, required this.store});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String location = locations.first,
      slot = '',
      method = 'GCash',
      outcome = 'Success';
  @override
  void initState() {
    super.initState();
    outcome = widget.store.paymentOutcome;
  }

  bool busy = false, pending = false;
  String? error;
  Future<void> chooseLocation() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 5, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where will we see you?',
                style: Theme.of(c).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Choose a sample campus pickup point.'),
              const SizedBox(height: 20),
              ...locations.map(
                (l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(l),
                      subtitle: const Text(
                        'Web Order Express Window · Fast pickup',
                      ),
                      trailing: Icon(
                        l == location
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                      onTap: () => Navigator.pop(c, l),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && mounted) {
      setState(() {
        location = chosen;
        slot = '';
      });
    }
  }

  Future<void> pay({bool resolve = false}) async {
    if (busy) return;
    final invalid = widget.store.validate(location, slot);
    if (invalid != null) {
      setState(() => error = invalid);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (!resolve && outcome != 'Success') {
      setState(() {
        busy = false;
        pending = outcome == 'Pending';
        error = switch (outcome) {
          'Pending' =>
            'Payment is being verified. Check its status before trying again.',
          'Failed' => 'Payment failed. Your bag and pickup selections are saved. Try again.',
          'Offline' =>
            'Connection lost. No order was created. Reconnect and try again.',
          _ => 'Payment canceled. Your bag is unchanged.',
        };
      });
      return;
    }
    try {
      final order = widget.store.checkout(location, slot, method);
      if (mounted) context.go('/orders/${order.id}');
    } on StateError catch (e) {
      if (mounted) {
        setState(() {
          error = e.message;
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservation =
        widget.store.cart.isNotEmpty && widget.store.cart.first.reservation;
    if (widget.store.cart.isEmpty) {
      return AppFrame(
        store: widget.store,
        child: const EmptyState(
          title: 'Your bag is empty',
          message: 'Add at least one item before checking out.',
        ),
      );
    }
    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _block(
          '01',
          'Your pickup point',
          Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storefront_outlined),
                title: Text(location),
                subtitle: const Text('Bring your Ateneo ID'),
                trailing: TextButton(
                  onPressed: busy || pending ? null : chooseLocation,
                  child: const Text('Change'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _block(
          '02',
          reservation ? 'Pickup after restock' : 'Make time for a quick pickup',
          reservation
              ? const InfoBox(
                  'Your reservation ticket is issued after payment. We’ll unlock time-slot selection once your items have restocked. Estimated restock: 2–3 weeks.',
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next campus day · Sample 15-minute windows',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 15),
                    IgnorePointer(
                      ignoring: busy || pending,
                      child: SlotPicker(
                        store: widget.store,
                        location: location,
                        selected: slot,
                        onChanged: (v) => setState(() => slot = v),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        _block(
          '03',
          'Payment method',
          Column(
            children: [
              RadioGroup<String>(
                groupValue: method,
                onChanged: (v) {
                  if (!busy && !pending) setState(() => method = v!);
                },
                child: Column(
                  children: ['GCash', 'Maya', 'Bank transfer']
                      .map(
                        (m) => RadioListTile<String>(
                          enabled: !busy && !pending,
                          contentPadding: EdgeInsets.zero,
                          value: m,
                          title: Text(m),
                          secondary: Icon(
                            m == 'Bank transfer'
                                ? Icons.account_balance_outlined
                                : Icons.account_balance_wallet_outlined,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const InfoBox(
                'Your order and payment confirmation stay together in My orders.',
                icon: Icons.receipt_long_outlined,
              ),
            ],
          ),
        ),
      ],
    );
    final summary = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your essentials',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 22),
            ...widget.store.cart.map(
              (l) => Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      height: 55,
                      child: ProductImage(product: l.product),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.product.name,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${l.variant} × ${l.quantity}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      money(l.total),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: 12),
            _sum('Pickup', 'Free'),
            const SizedBox(height: 15),
            _sum('Total', money(widget.store.total), bold: true),
            const SizedBox(height: 24),
            if (error != null) ...[
              InfoBox(
                error!,
                icon: pending ? Icons.hourglass_top : Icons.error_outline,
              ),
              const SizedBox(height: 15),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('pay'),
                onPressed: busy ? null : () => pay(resolve: pending),
                child: busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        pending
                            ? 'Check payment status'
                            : 'Pay ${money(widget.store.total)}',
                      ),
              ),
            ),
            if (pending)
              TextButton(
                onPressed: () => setState(() {
                  pending = false;
                  error = 'Pending payment canceled. You can choose another method.';
                }),
                child: const Text('Cancel pending payment'),
              ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'YOUR NEXT STOP: EXPRESS PICKUP',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 1.5,
                  color: Brand.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return AppFrame(
      store: widget.store,
      child: PageBody(
        children: [
          TextButton.icon(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Back to bag'),
          ),
          const SizedBox(height: 20),
          const SectionHeading(
            'A few taps from done.',
            'Choose your pickup. We’ll save you a spot.',
          ),
          LayoutBuilder(
            builder: (context, box) => box.maxWidth > 800
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: form),
                      const SizedBox(width: 28),
                      Expanded(flex: 4, child: summary),
                    ],
                  )
                : Column(children: [form, const SizedBox(height: 20), summary]),
          ),
        ],
      ),
    );
  }

  Widget _block(String n, String title, Widget body) => Card(
    child: Padding(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(n, style: const TextStyle(color: Brand.muted, fontSize: 12)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          body,
        ],
      ),
    ),
  );
}
