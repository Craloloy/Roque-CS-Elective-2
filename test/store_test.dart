import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecommerce_app/store.dart';

void main() {
  late Store store;
  setUp(() => store = Store());
  test(
    'cart merges variants and calculates totals without exceeding stock',
    () {
      final p = catalog.first;
      expect(store.add(p, 'Classic gold', 2), isNull);
      expect(store.add(p, 'Classic gold', 3), isNull);
      expect(store.cart.length, 1);
      expect(store.count, 5);
      expect(store.total, 750);
      expect(store.add(p, 'Classic gold', 20), isNotNull);
      expect(store.count, 5);
      store.quantity(store.cart.first, 2);
      expect(store.total, 300);
      store.quantity(store.cart.first, 0);
      expect(store.cart, isEmpty);
    },
  );
  test('reservations and available items require separate checkouts', () {
    store.add(catalog.first, 'Classic gold', 1);
    expect(
      store.add(catalog[3], 'Gold', 1, reserve: true),
      contains('separately'),
    );
    expect(store.count, 1);
  });
  test('checkout rejects an empty bag, invalid location and full slot', () {
    expect(
      () => store.checkout(locations.first, slots.first, 'GCash'),
      throwsStateError,
    );
    store.add(catalog.first, 'Classic gold', 1);
    expect(store.validate('Closed Desk', slots.first), isNotNull);
    expect(store.validate(locations.first, slots[1]), isNotNull);
    expect(store.validate(locations.first, ''), isNotNull);
  });
  test('paid order preserves its own line snapshot and deducts stock once', () {
    store.add(catalog.first, 'Classic gold', 2);
    final order = store.checkout(locations.first, slots.first, 'GCash');
    expect(store.cart, isEmpty);
    expect(order.total, 300);
    expect(store.stock(catalog.first, 'Classic gold'), 22);
    store.add(catalog.first, 'Classic gold', 1);
    expect(order.lines.first.quantity, 2);
    expect(order.total, 300);
    expect(store.lookup('magisstore:claim:${order.claim}'), order);
  });
  test(
    'handover validates readiness, desk and ID and refuses duplicate claims',
    () {
      store.add(catalog.first, 'Classic gold', 1);
      final order = store.checkout(locations.first, slots.first, 'Maya');
      expect(
        store.handover(order, locations.first, true),
        contains('not ready'),
      );
      store.prepare(order);
      expect(store.handover(order, 'Different Desk', true), contains('Wrong'));
      expect(store.handover(order, locations.first, false), contains('ID'));
      expect(store.handover(order, locations.first, true), isNull);
      expect(order.collectedAt, isNotNull);
      expect(store.handover(order, locations.first, true), contains('already'));
    },
  );
  test('reservation unlocks scheduling after restock, then handover', () {
    store.add(catalog[3], 'Gold', 1, reserve: true);
    final order = store.checkout(locations.first, '', 'GCash');
    expect(order.slot, 'Schedule after restock');
    expect(store.schedule(order, slots.first), isNotNull);
    store.prepare(order);
    expect(order.ready, false);
    expect(store.schedule(order, slots[1]), isNotNull);
    expect(store.schedule(order, slots.first), isNull);
    expect(order.ready, true);
    expect(store.handover(order, locations.first, true), isNull);
  });
  test('slot capacity is checked again at checkout', () {
    for (var i = 0; i < 3; i++) {
      store.add(catalog.first, 'Classic gold', 1);
      store.checkout(locations.first, slots.first, 'GCash');
    }
    store.add(catalog.first, 'Classic gold', 1);
    expect(store.slotOpen(locations.first, slots.first), false);
    expect(
      () => store.checkout(locations.first, slots.first, 'GCash'),
      throwsStateError,
    );
    expect(store.count, 1);
  });
  test('orders, cart and theme survive repository reload', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final persistent = Store(prefs: prefs);
    persistent.add(catalog.first, 'Classic gold', 1);
    final order = persistent.checkout(locations.first, slots.first, 'GCash');
    persistent.add(catalog[1], 'Ateneo blue', 2);
    persistent.toggleTheme();
    await persistent.changed();
    final restored = Store(prefs: prefs);
    expect(restored.dark, true);
    expect(restored.count, 2);
    expect(restored.order(order.id)?.total, 150);
    expect(restored.stock(catalog.first, 'Classic gold'), 23);
  });
}
