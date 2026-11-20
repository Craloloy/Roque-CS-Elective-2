import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../services/shop_service.dart';

final serviceProvider = Provider<ShopService>(
  (_) => throw StateError('Missing MagiStore connection'),
);
final sessionProvider = StreamProvider<String?>(
  (ref) => ref.watch(serviceProvider).sessions(),
  retry: (_, _) => null,
);
const shopRequestWait = Duration(seconds: 20);
Future<T> _waitFor<T>(Future<T> request, String message) =>
    request.timeout(shopRequestWait, onTimeout: () => throw ShopIssue(message));
final profileProvider = FutureProvider.autoDispose.family<Account, String>(
  (ref, id) => _waitFor(
    ref.watch(serviceProvider).account(id),
    'You are signed in, but your shop profile took too long to load. Check your connection and retry.',
  ),
  retry: (_, _) => null,
);
final currentAccount = Provider<Account>(
  (_) => throw StateError('Sign in first'),
);
final categoryProvider = FutureProvider<List<Category>>(
  (ref) => _waitFor(
    ref.watch(serviceProvider).categories(),
    'Shop categories took too long to load. Please retry.',
  ),
  retry: (_, _) => null,
);
final pageProvider = FutureProvider.autoDispose
    .family<({List<Item> items, int count}), Filters>(
      (ref, f) => _waitFor(
        ref.watch(serviceProvider).catalog(f),
        'The product list took too long to load. Please retry.',
      ),
      retry: (_, _) => null,
    );
final relatedProvider = FutureProvider.autoDispose.family<List<Item>, Item>(
  (ref, p) => _waitFor(
    ref.watch(serviceProvider).related(p),
    'Related products took too long to load. Please try again.',
  ),
  retry: (_, _) => null,
);
final ordersProvider = FutureProvider.autoDispose<List<Purchase>>(
  (ref) => _waitFor(
    ref.watch(serviceProvider).orders(ref.watch(currentAccount)),
    'Orders took too long to load. Please try again.',
  ),
  retry: (_, _) => null,
);

final orderNotificationsProvider = FutureProvider.autoDispose<List<int>>(
  (ref) => _waitFor(
    ref.watch(serviceProvider).orderNotifications(ref.watch(currentAccount)),
    'Notifications took too long to load. Please try again.',
  ),
  retry: (_, _) => null,
);

final stockNotificationsProvider = FutureProvider.autoDispose<List<Item>>((
  ref,
) {
  final account = ref.watch(currentAccount);
  final tracked = account.admin
      ? <int>[]
      : <int>{
          ...ref.watch(savedProvider),
          ...ref.watch(bagProvider).keys.map((key) => key.id),
        }.toList(growable: false);
  if (!account.admin && tracked.isEmpty) return const <Item>[];
  return _waitFor(
    ref.watch(serviceProvider).stockNotifications(account, tracked),
    'Stock alerts took too long to load. Please try again.',
  );
}, retry: (_, _) => null);

final pickupProvider = Provider((ref) => PickupActions(ref));

class PickupActions {
  const PickupActions(this.ref);
  final Ref ref;

  Future<void> confirm(int orderId) async {
    await _waitFor(
      ref.read(serviceProvider).confirmPickup(orderId),
      'Pickup confirmation took too long. Refresh your orders or try again.',
    );
    if (ref.mounted) {
      ref.invalidate(ordersProvider);
      ref.invalidate(orderNotificationsProvider);
    }
  }
}

class Saved extends Notifier<Set<int>> {
  @override
  Set<int> build() => {};
  void toggle(int id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
}

final savedProvider = NotifierProvider<Saved, Set<int>>(Saved.new);

class Bag extends Notifier<Map<BagKey, BagLine>> {
  String? _key;
  bool _working = false;
  @override
  Map<BagKey, BagLine> build() => {};
  void _edit() {
    if (_working) throw const ShopIssue('Checkout is in progress.');
    _key = null;
  }

  void setQuantity(Item item, int qty, {String? size}) {
    final key = (id: item.id, size: size);
    if (qty > 0 &&
        (item.needsSize ? !uniformSizes.contains(size) : size != null)) {
      throw const ShopIssue('Select a valid size for this item.');
    }
    final previous = state[key]?.quantity ?? 0;
    if (ref.read(currentAccount).admin) {
      throw const ShopIssue('Only customers have a bag.');
    }
    if (qty < 0 ||
        (qty > previous &&
            bagQuantity(state, item.id) - previous + qty > item.stock)) {
      throw ShopIssue('Only ${item.stock} left for ${item.name}.');
    }
    if (qty > 9999999 ||
        (qty > 0 && !state.containsKey(key) && state.length >= 100)) {
      throw const ShopIssue('The bag has reached its checkout limit.');
    }
    _edit();
    final next = {...state};
    if (qty == 0) {
      next.remove(key);
    } else {
      next[key] = BagLine(item, qty, size);
    }
    state = next;
  }

  void add(Item item, {String? size}) => setQuantity(
    item,
    (state[(id: item.id, size: size)]?.quantity ?? 0) + 1,
    size: size,
  );
  Future<void> refresh() async {
    final ids = state.keys.map((key) => key.id).toSet().toList();
    final items = await _waitFor(
      ref.read(serviceProvider).bagItems(ids),
      'Could not refresh your bag in time. Please try again.',
    );
    if (!ref.mounted || _working) return;
    final found = {for (final i in items) i.id: i};
    state = {
      for (final e in state.entries)
        e.key: !ids.contains(e.key.id)
            ? e.value
            : BagLine(
                found[e.key.id] ??
                    Item(
                      e.key.id,
                      e.value.item.name,
                      e.value.item.description,
                      e.value.item.price,
                      0,
                      e.value.item.image,
                      e.value.item.category,
                    ),
                e.value.quantity,
                e.value.size,
              ),
    };
  }

  Future<Receipt> place() async {
    if (_working || state.isEmpty) {
      throw const ShopIssue('Your bag is empty or checkout is in progress.');
    }
    _working = true;
    _key ??= requestId();
    try {
      final receipt = await _waitFor(
        ref.read(serviceProvider).checkout(state, _key!),
        'Checkout confirmation took too long. Check My orders, or retry with the same bag.',
      );
      if (ref.mounted) {
        state = {};
        _key = null;
        ref.invalidate(pageProvider);
        ref.invalidate(ordersProvider);
        ref.invalidate(relatedProvider);
        ref.invalidate(stockNotificationsProvider);
      }
      return receipt;
    } finally {
      _working = false;
    }
  }
}

final bagProvider = NotifierProvider<Bag, Map<BagKey, BagLine>>(Bag.new);
final authActions = Provider((ref) => AuthActions(ref.watch(serviceProvider)));

class AuthActions {
  const AuthActions(this._s);
  final ShopService _s;
  Future<void> login(String email, String password) => _waitFor(
    _s.login(email, password),
    'Sign-in took too long. Check your connection, then try again.',
  );
  Future<bool> signup(
    String email,
    String password,
    String first,
    String last,
  ) => _waitFor(
    _s.signup(email, password, first, last),
    'Signup took too long. Check your inbox before trying again.',
  );
  Future<void> resendConfirmation(String email) => _waitFor(
    _s.resendConfirmation(email),
    'The email request timed out. Check your inbox and try again later.',
  );
  Future<void> google() =>
      _waitFor(_s.google(), 'Google sign-in did not open. Try again.');
  Future<void> logout() => _waitFor(
    _s.logout(),
    'Sign-out took too long. Check your connection and try again.',
  );
}

final managerProvider = Provider((ref) => Manager(ref));

class Manager {
  Manager(this.ref);
  final Ref ref;
  ShopService get _s => ref.read(serviceProvider);
  void refreshCatalog() {
    ref.invalidate(categoryProvider);
    ref.invalidate(pageProvider);
    ref.invalidate(relatedProvider);
    ref.invalidate(stockNotificationsProvider);
  }

  Future<void> category(int? id, String name) async {
    await _s.saveCategory(id, name.trim());
    if (ref.mounted) refreshCatalog();
  }

  Future<void> removeCategory(int id) async {
    await _s.deleteCategory(id);
    if (ref.mounted) refreshCatalog();
  }

  Future<void> product(int? id, Json data) async {
    await _s.saveItem(id, data);
    if (ref.mounted) refreshCatalog();
  }

  Future<void> removeProduct(int id) async {
    await _s.deleteItem(id);
    if (ref.mounted) refreshCatalog();
  }

  Future<String> upload(Uint8List bytes, String mime) => _s.upload(bytes, mime);
  Future<void> status(int id, String status) async {
    await _s.status(id, status);
    if (ref.mounted) {
      ref.invalidate(ordersProvider);
      ref.invalidate(orderNotificationsProvider);
    }
  }
}
