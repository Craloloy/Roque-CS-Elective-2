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
  testWidgets('storefront adapts grid and toggles the app theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store();
    await tester.pumpWidget(MagisApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('MagiStore'), findsOneWidget);
    expect(find.text('360°'), findsWidgets);
    var grid = tester.widget<GridView>(find.byKey(const Key('productGrid')));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Toggle light / dark mode'));
    await tester.pumpAndSettle();
    expect(store.dark, true);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    tester.view.physicalSize = const Size(1024, 900);
    await tester.pumpAndSettle();
    grid = tester.widget<GridView>(find.byKey(const Key('productGrid')));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      greaterThanOrEqualTo(3),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('product add updates bag and cart total live', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store();
    await tester.pumpWidget(
      MagisApp(store: store, initialLocation: '/product/pin'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Classic gold'));
    await tester.tap(find.byKey(const Key('addToCart')));
    await tester.pumpAndSettle();
    expect(store.count, 1);
    expect(find.text('View bag (1) →'), findsOneWidget);
    await tester.tap(find.text('View bag (1) →'));
    await tester.pumpAndSettle();
    expect(find.text('Your bag'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase quantity'));
    await tester.pumpAndSettle();
    expect(store.total, 300);
    expect(find.text('₱300.00'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
  testWidgets('empty bag cannot reach payment controls', (tester) async {
    await tester.pumpWidget(
      MagisApp(store: Store(), initialLocation: '/checkout'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your bag is empty'), findsOneWidget);
    expect(find.byKey(const Key('pay')), findsNothing);
  });
  testWidgets(
    'verifies Add to Cart text, formal snackbar, and bookstore-only pickup',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = Store();
      await tester.pumpWidget(
        MagisApp(store: store, initialLocation: '/product/pin'),
      );
      await tester.pumpAndSettle();

      // 1. Photo 1: Check Add to Cart button label
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('Add to Cart & Pay'), findsNothing);

      // Select variant and add to cart
      await tester.tap(find.text('Classic gold'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('addToCart')));
      await tester.pumpAndSettle();

      // 2. Photo 2: Check formal alert with View bag action
      expect(find.text('Item added to your bag.'), findsOneWidget);
      expect(find.text('View bag'), findsOneWidget);

      // Navigate to checkout
      await tester.tap(find.text('View bag'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('checkout')), findsOneWidget);
      await tester.tap(find.byKey(const Key('checkout')));
      await tester.pumpAndSettle();

      // 3. Photo 3: Open location selector, ensure only Main Bookstore exists
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.text('Where will we see you?'), findsOneWidget);
      expect(find.text('Main Bookstore'), findsNWidgets(2));
      expect(find.text('CSSEC IT Week Booth'), findsNothing);
      expect(find.text('Annex Pickup Desk'), findsNothing);
    },
  );
  testWidgets('PE Uniform renders size guide, set details, and on-model view', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = Store();
    await tester.pumpWidget(
      MagisApp(store: store, initialLocation: '/product/uniform'),
    );
    await tester.pumpAndSettle();

    // 1. Verify 2-piece set information banner
    expect(find.text('Complete 2-Piece Uniform Set'), findsOneWidget);
    expect(find.text('Choose your size'), findsOneWidget);
    expect(find.text('Size Guide'), findsOneWidget);

    // 2. Open Size Guide dialog
    await tester.tap(find.text('Size Guide'));
    await tester.pumpAndSettle();
    expect(find.text('PE Uniform Size Guide'), findsOneWidget);
    expect(find.text('Top Length'), findsOneWidget);
    expect(find.text('Pants Length'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // 3. Select size and verify stock status line
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Size M is in stock'), findsOneWidget);

    // 4. Switch to Gallery mode and check On-Model segment
    await tester.tap(find.text('Gallery'));
    await tester.pumpAndSettle();
    expect(find.text('On Model'), findsOneWidget);
    await tester.tap(find.text('On Model'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('notifications screen displays order readiness and navigates to claim ticket', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = Store();
    final testOrder = Order(
      id: 'ADDU-8912',
      claim: 'claim-addu-8912',
      location: 'Main Bookstore (Counter 2)',
      slot: 'Today · Express Window',
      method: 'Pay Online',
      lines: [CartLine('pin', 'Classic gold', 1, false)],
      created: DateTime.now().toIso8601String(),
      stage: 1,
    );
    store.orders.add(testOrder);

    await tester.pumpWidget(
      MagisApp(store: store, initialLocation: '/notifications'),
    );
    await tester.pumpAndSettle();

    // Verify notifications screen title and in-prep order
    expect(find.text('Order Notifications'), findsOneWidget);
    expect(find.text('IN PREPARATION'), findsOneWidget);
    expect(find.text('ADDU-8912'), findsWidgets);

    // Simulate staff marking ready
    final simulateBtn = find.text('Simulate: Staff Marks Ready');
    expect(simulateBtn, findsOneWidget);
    await tester.tap(simulateBtn);
    await tester.pumpAndSettle();

    // Now it should be in Ready for Collection
    expect(store.readyOrdersCount, 1);
    expect(find.text('READY FOR COLLECTION'), findsOneWidget);
    expect(find.text('Ready for Pickup'), findsWidgets);
    expect(find.text('Proceed to Main Bookstore · Web Order Express Window.'), findsOneWidget);

    // Tap View Claim Ticket & QR
    final claimTicketBtn = find.text('View Claim Ticket & QR');
    expect(claimTicketBtn, findsOneWidget);
    await tester.tap(claimTicketBtn);
    await tester.pumpAndSettle();

    // Verify navigated to order claim ticket page
    expect(find.text('YOUR EXPRESS CLAIM TICKET'), findsOneWidget);
    expect(find.text('Your order is ready for pickup!'), findsOneWidget);
    expect(find.textContaining('Proceed to Counter 2'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

