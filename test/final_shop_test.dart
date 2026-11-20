import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ecommerce_app/shop/pages/appearance.dart';
import 'package:flutter_ecommerce_app/shop/models/shop.dart';
import 'package:flutter_ecommerce_app/shop/providers/shop_providers.dart';
import 'package:flutter_ecommerce_app/shop/services/shop_service.dart';
import 'package:flutter_ecommerce_app/shop/pages/app.dart';

const notebook = Item(
  7,
  'MUJI A5 Grid Notebook',
  'Grid paper',
  9500,
  2,
  'assets/products/study-grid-notebook.webp',
  Category(2, 'Study Supplies'),
);

class ShopFixture extends Fake implements ShopService {
  bool loseResponse = true;
  int productCount = 1;
  bool loggedOut = false;
  bool pickupConfirmed = false;

  @override
  Future<void> logout() async {
    loggedOut = true;
  }

  final keys = <String>[];
  final queries = <Filters>[];
  @override
  Future<List<Category>> categories() async => [notebook.category];
  @override
  Future<({List<Item> items, int count})> catalog(Filters f) async {
    queries.add(f);
    return (items: [notebook], count: productCount);
  }

  @override
  Future<List<int>> orderNotifications(Account account) async =>
      account.admin ? [41] : (pickupConfirmed ? [] : [42]);

  @override
  Future<List<Item>> stockNotifications(
    Account account,
    List<int> tracked,
  ) async => account.admin || tracked.contains(notebook.id) ? [notebook] : [];

  @override
  Future<void> confirmPickup(int id) async {
    expect(id, 42);
    pickupConfirmed = true;
  }

  @override
  Future<List<Purchase>> orders(Account account) async => [
    for (final (id, status) in [
      (42, pickupConfirmed ? 'collected' : 'ready'),
      (41, 'done'),
    ])
      Purchase.from(
        {
          'id': id,
          'status': status,
          'created_at': '2026-11-20T00:00:00Z',
          'total': '95.00',
          'user_id': account.admin ? 'student-$id' : account.id,
          'order_items': [
            {
              'product_name': notebook.name,
              'quantity': 1,
              'unit_price': '95.00',
            },
          ],
        },
        customer: account.admin
            ? OrderCustomer.from({
                if (id == 41) ...{
                  'firstname': ' Alex ',
                  'lastname': ' Santos ',
                },
                'email': 'student$id@example.test',
              })
            : null,
      ),
  ];

  @override
  Future<Receipt> checkout(Map<BagKey, BagLine> bag, String key) async {
    keys.add(key);
    if (loseResponse) {
      loseResponse = false;
      throw const ShopIssue('Response lost');
    }
    return Receipt.from({'id': 41, 'total': '190.00'});
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'stock cap, retry with the same checkout reference, clear only after success',
    () async {
      final service = ShopFixture();
      final container = ProviderContainer(
        overrides: [
          serviceProvider.overrideWithValue(service),
          currentAccount.overrideWithValue(
            const Account('customer', 'a@example.test', 'customer'),
          ),
        ],
      );
      addTearDown(container.dispose);
      final cart = container.read(bagProvider.notifier);
      cart.add(notebook);
      cart.add(notebook);
      expect(() => cart.add(notebook), throwsA(isA<ShopIssue>()));
      await expectLater(cart.place(), throwsA(isA<ShopIssue>()));
      expect(container.read(bagProvider)[(id: 7, size: null)]!.quantity, 2);
      final receipt = await cart.place();
      expect(receipt.total, 19000);
      expect(service.keys[0], service.keys[1]);
      expect(container.read(bagProvider), isEmpty);
    },
  );
  testWidgets('phone filter panel replaces quick shortcuts', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final service = ShopFixture();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('user', 'a@example.test', 'customer'),
          ),
          serviceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: ShopHome()),
      ),
    );
    await t.pumpAndSettle();

    final available = find.widgetWithText(ChoiceChip, 'Available');
    expect(find.widgetWithText(ChoiceChip, 'Saved'), findsOneWidget);
    await t.tap(available);
    await t.pumpAndSettle();
    expect(service.queries.last.availableOnly, isTrue);

    await t.tap(find.text('Filter (1)'));
    await t.pumpAndSettle();
    expect(available, findsNothing);
    final availableSwitch = find.widgetWithText(
      SwitchListTile,
      'Available only',
    );
    expect(t.widget<SwitchListTile>(availableSwitch).value, isTrue);

    await t.tap(find.text('Hide filters'));
    await t.pumpAndSettle();
    expect(availableSwitch, findsNothing);
    expect(t.widget<ChoiceChip>(available).selected, isTrue);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('header search, price filters and theme work together', (
    t,
  ) async {
    t.view.physicalSize = const Size(1100, 1050);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({'magistore.appearance': 'light'});
    final service = ShopFixture();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('user', 'a@example.test', 'customer'),
          ),
          serviceProvider.overrideWithValue(service),
        ],
        child: ShopAppearance(child: shell(const ShopHome())),
      ),
    );
    await t.pumpAndSettle();

    final header = find.byType(AppBar);
    final search = find.descendant(
      of: header,
      matching: find.byType(TextField),
    );
    expect(search, findsOneWidget);
    await t.tap(find.text('Filters'));
    await t.pumpAndSettle();
    await t.tap(find.text('Under ₱500'));
    await t.pumpAndSettle();
    expect(service.queries.last.maxCents, 49999);

    final maximum = find.widgetWithText(TextField, 'Max');
    await t.enterText(maximum, '125.50');
    await t.pumpAndSettle();
    final apply = find.widgetWithText(OutlinedButton, 'Apply price');
    await t.ensureVisible(apply);
    await t.pumpAndSettle();
    expect(apply.hitTestable(), findsOneWidget);
    await t.tap(apply);
    await t.pumpAndSettle();
    expect(service.queries.last.maxCents, 12550);

    await t.enterText(search, 'D');
    await t.pumpAndSettle();
    expect(service.queries.last.search, 'D');
    expect(service.queries.last.maxCents, isNull);
    expect(find.text('Search results'), findsOneWidget);

    await t.tap(find.byTooltip('Switch to dark mode'));
    await t.pumpAndSettle();
    expect(Theme.of(t.element(header)).brightness, Brightness.dark);
    expect(t.widget<TextField>(search).controller!.text, 'D');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('magistore.appearance'), 'dark');
  });
  testWidgets('pull refreshes the catalog and the logo returns from Bag', (
    t,
  ) async {
    final service = ShopFixture();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('user', 'a@example.test', 'customer'),
          ),
          serviceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: ShopHome()),
      ),
    );
    await t.pumpAndSettle();
    final before = service.queries.length;
    expect(find.byTooltip('Refresh catalog'), findsNothing);
    await t.drag(find.text('Campus essentials'), const Offset(0, 350));
    await t.pumpAndSettle();
    expect(service.queries.length, greaterThan(before));

    await t.tap(find.byTooltip('Bag'));
    await t.pumpAndSettle();
    await t.tap(find.text('MagiStore'));
    await t.pumpAndSettle();
    expect(find.text(notebook.name), findsOneWidget);
  });
  testWidgets('number buttons jump to pages and the arrows stop at the ends', (
    t,
  ) async {
    t.view.physicalSize = const Size(1100, 1050);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final service = ShopFixture()..productCount = 7 * pageSize;
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('user', 'a@example.test', 'customer'),
          ),
          serviceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: ShopHome()),
      ),
    );
    await t.pumpAndSettle();
    final previous = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Previous page',
    );
    final next = find.byWidgetPredicate(
      (widget) => widget is IconButton && widget.tooltip == 'Next page',
    );
    expect(t.widget<IconButton>(previous).onPressed, isNull);
    for (var i = 1; i <= 7; i++) {
      expect(find.widgetWithText(TextButton, i.toString()), findsOneWidget);
    }
    await t.tap(find.widgetWithText(TextButton, '7'));
    await t.pumpAndSettle();
    expect(service.queries.last.page, 6);
    expect(t.widget<IconButton>(next).onPressed, isNull);
    await t.tap(previous);
    await t.pumpAndSettle();
    expect(service.queries.last.page, 5);
  });
  testWidgets('notification opens a ready order and student confirms pickup', (
    t,
  ) async {
    t.view.physicalSize = const Size(520, 940);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final service = ShopFixture();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('student', 'a@example.test', 'customer'),
          ),
          serviceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: ShopHome()),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Notifications'));
    await t.pumpAndSettle();
    await t.tap(find.text('Order #42 is ready to claim'));
    await t.pumpAndSettle();
    Badge badge(String tooltip) => t.widget<Badge>(
      find.descendant(
        of: find.byTooltip(tooltip),
        matching: find.byType(Badge),
      ),
    );
    expect(badge('Notifications').isLabelVisible, isFalse);
    expect(badge('Bag').isLabelVisible, isTrue);
    expect(find.text('!'), findsOneWidget);
    await t.tap(find.byTooltip('Notifications'));
    await t.pumpAndSettle();
    expect(find.text('Order #42 is ready to claim'), findsNothing);
    expect(find.text('No unread order alerts.'), findsOneWidget);
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    await t.tap(find.text('Confirm pickup'));
    await t.pumpAndSettle();
    await t.tap(find.text('Mark as collected'));
    await t.pumpAndSettle();
    expect(service.pickupConfirmed, isTrue);
    expect(badge('Bag').isLabelVisible, isFalse);
    expect(find.text('!'), findsNothing);
    expect(find.text('Confirm pickup'), findsNothing);
    await t.tap(find.byTooltip('Notifications'));
    await t.pumpAndSettle();
    expect(find.text('No orders are ready for pickup yet.'), findsOneWidget);
    expect(
      find.text('No stock alerts for saved items or items in your bag.'),
      findsOneWidget,
    );
    await t.tap(find.text('Close'));
    await t.pumpAndSettle();
    await t.tap(find.text('Back to shopping'));
    await t.pumpAndSettle();
    final save = find.byTooltip('Save product');
    await t.ensureVisible(save);
    await t.pumpAndSettle();
    await t.tap(save);
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Notifications'));
    await t.pumpAndSettle();
    expect(find.text('Low stock · 2 left'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('admin alerts open the order and staff can filter orders', (
    t,
  ) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          currentAccount.overrideWithValue(
            const Account('admin', 'admin@example.test', 'admin'),
          ),
          serviceProvider.overrideWithValue(ShopFixture()),
        ],
        child: const MaterialApp(home: ShopHome()),
      ),
    );
    await t.pumpAndSettle();
    final bell = find.byTooltip('Notifications');
    final bellBottom = t.getBottomLeft(bell).dy;
    await t.tap(bell);
    await t.pumpAndSettle();
    expect(
      t.getTopLeft(find.text('Notifications')).dy,
      greaterThan(bellBottom),
    );
    expect(find.text('New order #41'), findsOneWidget);
    expect(find.text('Stock alerts'), findsOneWidget);
    expect(find.text('Low stock · 2 left'), findsOneWidget);
    await t.tap(find.text('New order #41'));
    await t.pumpAndSettle();
    expect(find.text('All orders'), findsOneWidget);
    expect(find.text('Order status'), findsOneWidget);
    expect(find.textContaining('Order #41'), findsOneWidget);
    expect(find.text('Alex Santos'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText && widget.data == 'student41@example.test',
      ),
      findsOneWidget,
    );
    expect(find.text('student42@example.test'), findsOneWidget);
    await t.tap(find.widgetWithText(ChoiceChip, 'To claim · 1'));
    await t.pumpAndSettle();
    expect(find.textContaining('Order #41'), findsNothing);
    expect(find.textContaining('Order #42'), findsOneWidget);
    await t.pumpWidget(const SizedBox.shrink());
  });

  for (final role in ['admin', 'customer']) {
    testWidgets('$role sees only the right shopping actions', (t) async {
      t.view.physicalSize = const Size(1050, 850);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final service = ShopFixture();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            currentAccount.overrideWithValue(
              Account('user', 'a@example.test', role),
            ),
            serviceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(home: ShopHome()),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(notebook.name), findsOneWidget);
      for (final label in ['Edit', 'Delete', 'Add product']) {
        expect(
          find.text(label),
          role == 'admin' ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.text('Add to bag'),
        role == 'customer' ? findsOneWidget : findsNothing,
      );
      if (role == 'customer') {
        await t.tap(find.text('Add to bag'));
        await t.pumpAndSettle();
        await t.tap(find.byTooltip('Bag'));
        await t.pumpAndSettle();
        expect(find.textContaining('Estimated total ₱95.00'), findsOneWidget);
        await t.tap(find.byTooltip('Account menu'));
        await t.pumpAndSettle();
        expect(find.text('a@example.test'), findsOneWidget);
        expect(find.text('Student Account'), findsOneWidget);
        await t.tap(find.text('Purchase history'));
        await t.pumpAndSettle();
        expect(find.textContaining('Order #42'), findsOneWidget);
        expect(find.textContaining('Order #41'), findsOneWidget);
        await t.tap(find.widgetWithText(ChoiceChip, 'To claim'));
        await t.pumpAndSettle();
        expect(find.textContaining('Order #41'), findsNothing);
        await t.tap(find.textContaining('Order #42'));
        await t.pumpAndSettle();
        expect(find.text('Ready for pickup'), findsOneWidget);
        expect(find.text(notebook.name), findsOneWidget);
      }
      await t.tap(find.byTooltip('Account menu'));
      await t.pumpAndSettle();
      expect(find.text('a@example.test'), findsOneWidget);
      if (role == 'admin') {
        expect(find.text('Admin Account'), findsOneWidget);
        expect(find.text('Manage orders'), findsOneWidget);
        expect(find.text('Purchase history'), findsNothing);
      }
      await t.tap(find.text('Log out'));
      await t.pumpAndSettle();
      expect(service.loggedOut, isTrue);
      expect(t.takeException(), isNull);
    });
  }
}
