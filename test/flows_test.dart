import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ecommerce_app/main.dart';
import 'package:flutter_ecommerce_app/store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope.ttf'));
    await loader.load();
  });
  testWidgets('pending payment issues no ticket until explicitly confirmed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store(paymentOutcome: 'Pending')
      ..add(catalog.first, 'Classic gold', 1);
    await tester.pumpWidget(
      MagisApp(store: store, initialLocation: '/checkout'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(slots.first));
    await tester.tap(find.byKey(const Key('pay')));
    await tester.pumpAndSettle();
    expect(store.orders, isEmpty);
    expect(store.count, 1);
    expect(find.text('Check payment status'), findsOneWidget);
    await tester.tap(find.byKey(const Key('pay')));
    await tester.pumpAndSettle();
    expect(store.orders.length, 1);
    expect(store.cart, isEmpty);
    expect(find.text('YOUR EXPRESS CLAIM TICKET'), findsOneWidget);
    expect(find.text('₱150.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed demo payment preserves bag and selected pickup', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store(paymentOutcome: 'Failed')
      ..add(catalog.first, 'Classic gold', 1);
    await tester.pumpWidget(
      MagisApp(store: store, initialLocation: '/checkout'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(slots.first));
    await tester.tap(find.byKey(const Key('pay')));
    await tester.pumpAndSettle();
    expect(store.orders, isEmpty);
    expect(store.count, 1);
    final slot = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, slots.first),
    );
    expect(slot.selected, true);
    expect(find.textContaining('Payment failed.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('product checkout and ticket fit phone width', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store()..add(catalog.first, 'Classic gold', 1);
    final order = store.checkout(locations.first, slots.first, 'GCash');
    store.add(catalog.first, 'Classic gold', 1);
    for (final route in [
      '/product/uniform',
      '/cart',
      '/checkout',
      '/orders/${order.id}',
    ]) {
      await tester.pumpWidget(
        MagisApp(key: UniqueKey(), store: store, initialLocation: route),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Overflow or error at $route',
      );
    }
  });
}
