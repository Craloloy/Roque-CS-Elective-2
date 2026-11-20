import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme.dart';
import '../models/shop.dart';
import '../providers/shop_providers.dart';
import '../services/shop_service.dart';
import 'auth.dart';
import 'appearance.dart';
import 'catalog.dart';
import 'common.dart';
import 'management.dart';
import 'orders.dart';

Widget shell(Widget home, {Key? key}) => Builder(
  key: key,
  builder: (context) => MaterialApp(
    themeMode: ShopAppearance.of(context)?.value ?? ThemeMode.system,
    title: 'MagiStore',
    debugShowCheckedModeBanner: false,
    theme: Brand.theme(Brightness.light),
    darkTheme: Brand.theme(Brightness.dark),
    home: home,
  ),
);

class _Waiting extends StatelessWidget {
  const _Waiting(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    ),
  );
}

class SessionGate extends ConsumerStatefulWidget {
  const SessionGate({super.key});
  @override
  ConsumerState<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends ConsumerState<SessionGate> {
  String? previousEmail;
  @override
  Widget build(BuildContext c) {
    final session = ref.watch(sessionProvider);
    return session.when(
      loading: () => shell(const _Waiting('Checking your sign-in…')),
      error: (e, _) => shell(
        Scaffold(
          body: Center(
            child: Load<String?>(
              session,
              retry: () => ref.invalidate(sessionProvider),
              data: (_) => const SizedBox(),
            ),
          ),
        ),
      ),
      data: (id) => id == null
          ? shell(
              SignInPage(initialEmail: previousEmail),
              key: const ValueKey('sign-in'),
            )
          : _ProfileGate(
              key: ValueKey(id),
              id: id,
              rememberEmail: (address) =>
                  previousEmail = address.isEmpty ? null : address,
            ),
    );
  }
}

class _ProfileGate extends ConsumerWidget {
  const _ProfileGate({
    super.key,
    required this.id,
    required this.rememberEmail,
  });
  final String id;
  final ValueChanged<String> rememberEmail;
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    ref.listen(profileProvider(id), (_, next) {
      if (next is AsyncData<Account>) rememberEmail(next.value.email);
    });
    final state = ref.watch(profileProvider(id));
    return state.when(
      skipLoadingOnRefresh: false,
      data: (a) => _Visit(
        key: ValueKey((a.id, a.role)),
        account: a,
        service: ref.read(serviceProvider),
      ),
      loading: () =>
          shell(const _Waiting('Signed in. Opening your shop profile…')),
      error: (error, _) => shell(
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(shopMessage(error), textAlign: TextAlign.center),
                    TextButton(
                      onPressed: () => ref.invalidate(profileProvider(id)),
                      child: const Text('Retry profile'),
                    ),
                    TextButton(
                      onPressed: () =>
                          perform(context, ref.read(authActions).logout),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A separate container AND Navigator per signed-in account: cart, cached order data,
// filters and open admin routes all disappear on logout or account change.
class _Visit extends StatefulWidget {
  const _Visit({super.key, required this.account, required this.service});
  final Account account;
  final ShopService service;
  @override
  State<_Visit> createState() => _VisitState();
}

class _VisitState extends State<_Visit> {
  late final container = ProviderContainer(
    overrides: [
      currentAccount.overrideWithValue(widget.account),
      serviceProvider.overrideWithValue(widget.service),
    ],
  );
  @override
  void dispose() {
    container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) => UncontrolledProviderScope(
    container: container,
    child: shell(const ShopHome()),
  );
}

class ShopHome extends ConsumerStatefulWidget {
  const ShopHome({super.key});
  @override
  ConsumerState<ShopHome> createState() => _ShopHomeState();
}

enum _AccountAction { products, bag, orders, categories, logout }

class _ShopHomeState extends ConsumerState<ShopHome> {
  int tab = 0;
  bool bagHistory = false;
  int? selectedOrderId;
  Timer? notificationTimer;
  late final String readAlertsPreference;
  final readAlerts = <String>{};
  final search = TextEditingController();
  final details = <Item>[];

  @override
  void initState() {
    super.initState();
    readAlertsPreference =
        'magistore.readAlerts.${ref.read(currentAccount).id}';
    unawaited(restoreReadAlerts());
    notificationTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      if (!ref.read(orderNotificationsProvider).isLoading) {
        ref.invalidate(orderNotificationsProvider);
      }
      if (!ref.read(stockNotificationsProvider).isLoading) {
        ref.invalidate(stockNotificationsProvider);
      }
    });
  }

  @override
  void dispose() {
    notificationTimer?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<void> restoreReadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(readAlertsPreference);
      if (mounted && saved != null) setState(() => readAlerts.addAll(saved));
    } catch (_) {
      // Alerts can still be read when local storage is unavailable.
    }
  }

  void markAlertRead(String key) {
    if (readAlerts.contains(key)) return;
    setState(() => readAlerts.add(key));
    unawaited(saveReadAlerts());
  }

  Future<void> saveReadAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(readAlertsPreference, readAlerts.toList());
    } catch (_) {
      // Keep read alerts cleared for this session.
    }
  }

  void openProducts() {
    FocusScope.of(context).unfocus();
    if (tab != 0 || details.isNotEmpty) {
      setState(() {
        tab = 0;
        details.clear();
      });
    }
  }

  void openDetail(Item item) {
    FocusScope.of(context).unfocus();
    setState(() {
      tab = 0;
      details.add(item);
    });
  }

  void backFromDetail() {
    if (details.isNotEmpty) setState(details.removeLast);
  }

  void openBag({bool history = false, int? orderId}) {
    FocusScope.of(context).unfocus();
    setState(() {
      tab = 1;
      bagHistory = history;
      selectedOrderId = orderId;
    });
  }

  void openStaffOrders({int? orderId}) {
    FocusScope.of(context).unfocus();
    setState(() {
      tab = 2;
      selectedOrderId = orderId;
    });
  }

  Future<void> openNotifications(BuildContext bellContext) async {
    ref.invalidate(orderNotificationsProvider);
    ref.invalidate(stockNotificationsProvider);
    final overlay =
        Navigator.of(bellContext).overlay!.context.findRenderObject()!
            as RenderBox;
    final bell = bellContext.findRenderObject()! as RenderBox;
    RelativeRect anchor() => RelativeRect.fromRect(
      Rect.fromPoints(
        bell.localToGlobal(Offset(0, bell.size.height + 6), ancestor: overlay),
        bell.localToGlobal(
          Offset(bell.size.width, bell.size.height + 6),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    var position = anchor();
    final width = math.min(390.0, overlay.size.width - 24);
    final selection = await showMenu<Object>(
      context: bellContext,
      positionBuilder: (_, _) {
        if (bell.attached && overlay.attached) position = anchor();
        return position;
      },
      constraints: BoxConstraints.tightFor(width: width),
      menuPadding: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      semanticLabel: 'Notifications',
      items: [ShopNotifications(readAlerts: Set.unmodifiable(readAlerts))],
    );
    if (!mounted) return;
    if (selection is Item) {
      markAlertRead(stockAlertKey(selection));
      // Enter the selected product from the catalog, even from another tab.
      details.clear();
      openDetail(selection);
    } else if (selection is int) {
      markAlertRead(orderAlertKey(selection));
      ref.invalidate(ordersProvider);
      if (ref.read(currentAccount).admin) {
        openStaffOrders(orderId: selection);
      } else {
        openBag(history: true, orderId: selection);
      }
    }
  }

  void accountAction(_AccountAction action, Account account) {
    switch (action) {
      case _AccountAction.products:
        openProducts();
      case _AccountAction.bag:
        openBag();
      case _AccountAction.orders:
        if (account.admin) {
          openStaffOrders();
        } else {
          openBag(history: true);
        }
      case _AccountAction.categories:
        setState(() => tab = 1);
      case _AccountAction.logout:
        perform(context, ref.read(authActions).logout);
    }
  }

  Widget searchBar() => SizedBox(
    height: 44,
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: search,
      builder: (_, value, _) => TextField(
        controller: search,
        textInputAction: TextInputAction.search,
        onChanged: (value) {
          if (details.isNotEmpty && value.trim().isNotEmpty) {
            setState(details.clear);
          }
        },
        onSubmitted: (_) => openProducts(),
        decoration: InputDecoration(
          hintText: 'Search products',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  onPressed: search.clear,
                  icon: const Icon(Icons.close, size: 18),
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext c) {
    final account = ref.watch(currentAccount), bag = ref.watch(bagProvider);
    final admin = account.admin;
    final orderAlerts =
        ref.watch(orderNotificationsProvider).value ?? const <int>[];
    final stockAlerts =
        ref.watch(stockNotificationsProvider).value ?? const <Item>[];
    final alerts =
        orderAlerts
            .where((id) => !readAlerts.contains(orderAlertKey(id)))
            .length +
        stockAlerts
            .where((item) => !readAlerts.contains(stockAlertKey(item)))
            .length;
    final pickupCount = admin ? 0 : orderAlerts.length;
    final viewport = MediaQuery.sizeOf(c).width;
    final safePadding = MediaQuery.paddingOf(c);
    final usableWidth = viewport - safePadding.horizontal;
    final wide = usableWidth >= 700;
    final headerInset = math.max(
      shopHorizontalPadding,
      (usableWidth - shopContentMaxWidth) / 2,
    );
    final count = bag.values.fold(0, (s, e) => s + e.quantity);
    final bagBadgeCount = pickupCount > 0 ? pickupCount : count;
    final viewingDetail = tab == 0 && details.isNotEmpty;
    return PopScope(
      canPop: !viewingDetail,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && viewingDetail) backFromDetail();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 64,
          titleSpacing: headerInset,
          title: Row(
            children: [
              if (!admin && usableWidth < 360)
                IconButton(
                  tooltip: 'MagiStore',
                  onPressed: openProducts,
                  icon: Image.asset(
                    'assets/branding/magistore.png',
                    width: 32,
                    height: 32,
                    excludeFromSemantics: true,
                  ),
                )
              else
                Flexible(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(c).colorScheme.onSurface,
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: openProducts,
                    icon: Image.asset(
                      'assets/branding/magistore.png',
                      width: 32,
                      height: 32,
                      excludeFromSemantics: true,
                    ),
                    label: const Text(
                      'MagiStore',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              if (tab == 0 && wide) ...[
                const SizedBox(width: 24),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 410),
                      child: searchBar(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          bottom: tab == 0 && !wide
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      shopHorizontalPadding,
                      0,
                      shopHorizontalPadding,
                      12,
                    ),
                    child: searchBar(),
                  ),
                )
              : null,
          actions: [
            const ShopThemeToggle(),
            Builder(
              builder: (bellContext) {
                void open() => openNotifications(bellContext);
                final bell = Badge(
                  isLabelVisible: alerts > 0,
                  label: Text(alerts > 99 ? '99+' : '$alerts'),
                  child: Icon(
                    admin && alerts > 0
                        ? Icons.notifications
                        : Icons.notifications_outlined,
                    size: 22,
                  ),
                );
                if (admin && usableWidth >= 1000) {
                  return Tooltip(
                    message: 'Notifications',
                    child: FilledButton.tonalIcon(
                      onPressed: open,
                      icon: bell,
                      label: const Text('Notifications'),
                    ),
                  );
                }
                if (admin) {
                  return IconButton.filledTonal(
                    tooltip: 'Notifications',
                    onPressed: open,
                    icon: bell,
                  );
                }
                return IconButton(
                  tooltip: 'Notifications',
                  onPressed: open,
                  icon: bell,
                );
              },
            ),
            if (!admin)
              IconButton(
                tooltip: 'Bag',
                onPressed: () =>
                    openBag(history: count == 0 && pickupCount > 0),
                isSelected: tab == 1,
                icon: Badge(
                  backgroundColor: pickupCount > 0
                      ? Theme.of(c).colorScheme.primary
                      : null,
                  textColor: pickupCount > 0
                      ? Theme.of(c).colorScheme.onPrimary
                      : null,
                  isLabelVisible: bagBadgeCount > 0,
                  label: Semantics(
                    label: pickupCount > 0
                        ? '$pickupCount orders ready for pickup'
                        : '$count items in the bag',
                    excludeSemantics: true,
                    child: Text('$bagBadgeCount'),
                  ),
                  child: Icon(
                    tab == 1 ? Icons.shopping_bag : Icons.shopping_bag_outlined,
                  ),
                ),
              ),
            _AccountMenu(
              account: account,
              showLabel: wide,
              onSelected: (action) => accountAction(action, account),
            ),
            SizedBox(width: headerInset),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(
            index: tab,
            children: [
              IndexedStack(
                index: details.isEmpty ? 0 : 1,
                children: [
                  CatalogPage(search: search, onOpenItem: openDetail),
                  if (details.isNotEmpty)
                    ItemDetail(
                      details.last,
                      key: ValueKey(details.last.id),
                      onBack: backFromDetail,
                      onCheckout: () => openBag(),
                      onOpenItem: openDetail,
                    ),
                ],
              ),
              if (admin)
                const CategoriesPage()
              else
                BagHub(
                  shop: openProducts,
                  history: bagHistory,
                  orderId: selectedOrderId,
                  hasPickupUpdate: pickupCount > 0,
                  onHistoryChanged: (history) => setState(() {
                    bagHistory = history;
                    selectedOrderId = null;
                  }),
                ),
              if (admin)
                tab == 2
                    ? OrdersPage(
                        key: ValueKey(selectedOrderId),
                        initialOrderId: selectedOrderId,
                      )
                    : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({
    required this.account,
    required this.showLabel,
    required this.onSelected,
  });

  final Account account;
  final bool showLabel;
  final ValueChanged<_AccountAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final email = account.email.trim();
    PopupMenuItem<_AccountAction> item(
      _AccountAction value,
      IconData icon,
      String label,
    ) => PopupMenuItem<_AccountAction>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: value == _AccountAction.logout
                ? colors.error
                : colors.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: value == _AccountAction.logout
                    ? colors.error
                    : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
    return PopupMenuButton<_AccountAction>(
      tooltip: 'Account menu',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: 216, maxWidth: 300),
      onSelected: onSelected,
      icon: showLabel ? null : const Icon(Icons.account_circle_outlined),
      child: showLabel
          ? const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_circle_outlined, size: 22),
                  SizedBox(width: 6),
                  Text('Account'),
                  Icon(Icons.expand_more, size: 18),
                ],
              ),
            )
          : null,
      itemBuilder: (_) => [
        PopupMenuItem<_AccountAction>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Signed in as',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email.isEmpty ? 'No email on this account' : email,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                account.admin ? 'Admin Account' : 'Student Account',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        if (account.admin)
          item(_AccountAction.products, Icons.storefront_outlined, 'Products')
        else
          item(_AccountAction.bag, Icons.shopping_bag_outlined, 'Shopping bag'),
        item(
          _AccountAction.orders,
          Icons.receipt_long_outlined,
          account.admin ? 'Manage orders' : 'Purchase history',
        ),
        if (account.admin)
          item(
            _AccountAction.categories,
            Icons.category_outlined,
            'Manage categories',
          ),
        const PopupMenuDivider(),
        item(_AccountAction.logout, Icons.logout_outlined, 'Log out'),
      ],
    );
  }
}
