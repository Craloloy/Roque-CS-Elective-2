import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

String money(num value) => '₱${value.toStringAsFixed(2)}';

class Product {
  final String id, name, category, detail, material, kind;
  final int price;
  final bool active;
  final Map<String, int> variants;
  const Product(
    this.id,
    this.name,
    this.category,
    this.price,
    this.kind,
    this.detail,
    this.material,
    this.variants, {
    this.active = true,
  });
  String get image => isStudyItem
      ? 'assets/products/study-$id.webp'
      : active
      ? 'assets/products/$id-reference.png'
      : 'assets/products/$id.png';
  String get backImage => 'assets/products/$id-back.png';
  List<String> get references => switch (id) {
    'uniform' => const ['assets/references/pe-round.png'],
    'polo' => const ['assets/references/pe-collared.png'],
    _ => const <String>[],
  };
  bool get isStudyItem => category == 'Books' || category == 'Study Supplies';
  int get stock => variants.values.fold(0, (a, b) => a + b);
}

const catalog = <Product>[
  Product(
    'pin',
    'Ateneo University Pin',
    'Pins & Ribbons',
    150,
    'pin',
    'A classic university pin: a scalloped gold edge, dark blue enamel ring, and Ateneo de Davao crest. A butterfly clutch secures the reverse.',
    'Gold-tone metal · Blue enamel · Butterfly clasp',
    {'Classic gold': 24},
  ),
  Product(
    'sling',
    'University ID Sling',
    'ID Accessories',
    120,
    'sling',
    'Keep your campus essentials close. A comfortable woven lanyard with a secure metal clasp.',
    'Navy woven strap · White university lettering · Black quick-release buckle · Silver hook',
    {'Ateneo blue': 18},
  ),
  Product(
    'uniform',
    'PE Uniform · Round Neck',
    'PE Uniforms',
    850,
    'pe_round',
    'A comfortable PE set for male and female students: a white round-neck shirt with blue sleeve edging, a small P.E. crest, and full-length navy pants.',
    'White round-neck shirt · Blue sleeve trim · Navy full-length pants · Vertical ATENEO leg print',
    {'XS': 4, 'S': 8, 'M': 12, 'L': 6, 'XL': 0},
  ),
  Product(
    'caduceus',
    'Nursing Caduceus Pin',
    'Course Pins',
    180,
    'caduceus',
    'A meaningful detail for your nursing journey. A sculpted gold-tone caduceus with a secure pin backing.',
    'Gold-tone alloy · Polished finish · Secure backing',
    {'Gold': 0},
  ),
  Product(
    'case',
    'Clear Landscape ID Case',
    'ID Accessories',
    95,
    'case',
    'A clean, durable home for your Ateneo ID. Designed to pair with your favorite university sling.',
    'Clear landscape holder · Silver-tone rivets · Upper attachment point',
    {'Clear landscape': 5},
  ),
  Product(
    'ribbon',
    'Plain Navy Ribbon',
    'Pins & Ribbons',
    65,
    'ribbon',
    'A simple navy ribbon for your campus essentials. A simple unprinted woven band, distinct from the university ID sling.',
    'Plain navy woven band · Unprinted finish · Flat ends',
    {'Navy blue': 30},
  ),
  Product(
    'cs',
    'Computer Studies Lanyard',
    'Course Pins',
    160,
    'sling',
    'For the builders, thinkers, and late-night debuggers. A course-inspired lanyard for everyday campus life.',
    'Woven polyester · Metal hook · Course print',
    {'CS blue': 7},
    active: false,
  ),
  Product(
    'shirt',
    'Everyday Ateneo Tee',
    'PE Uniforms',
    450,
    'shirt',
    'Your new campus staple. A soft, easy-to-wear tee for class days and everything after.',
    'Cotton blend · Regular fit · Printed wordmark',
    {'S': 5, 'M': 7, 'L': 5, 'XL': 3},
    active: false,
  ),
  Product(
    'polo',
    'PE Uniform · Collared',
    'PE Uniforms',
    900,
    'pe_polo',
    'A classic collared PE set for male and female students. A white polo with a blue collar and sleeve trim, paired with full-length navy Ateneo pants.',
    'Blue fold-over collar · Small chest P.E. crest · White shirt · Navy long pants',
    {'XS': 3, 'S': 6, 'M': 8, 'L': 5, 'XL': 0},
  ),
  Product(
    'dart-guide',
    'Dart Apprentice: Fundamentals',
    'Books',
    349,
    'book',
    'A beginner’s guide to Dart by Jonathan Sande and the Kodeco Tutorial Team.',
    'First edition · Dart programming',
    {'Paperback': 18},
  ),
  Product(
    'algorithms-guide',
    'Introduction to Algorithms',
    'Books',
    495,
    'book',
    'The fourth edition by Cormen, Leiserson, Rivest, and Stein covers algorithm design and analysis.',
    'Fourth edition · MIT Press',
    {'Hardcover': 14},
  ),
  Product(
    'discrete-guide',
    'Discrete Mathematics and Its Applications',
    'Books',
    395,
    'book',
    'Kenneth H. Rosen’s textbook covers logic, sets, counting, and graph theory.',
    'Eighth edition · McGraw Hill',
    {'Paperback': 12},
  ),
  Product(
    'research-guide',
    'The Craft of Research',
    'Books',
    325,
    'book',
    'A guide to developing research questions, working with sources, and making evidence-based arguments.',
    'Fifth edition · University of Chicago Press',
    {'Paperback': 15},
  ),
  Product(
    'grid-notebook',
    'MUJI A5 Grid Notebook',
    'Study Supplies',
    95,
    'notebook',
    'A grid notebook for diagrams, equations, and everyday lecture notes.',
    'A5 · Grid paper',
    {'Gray': 27},
  ),
  Product(
    'index-tabs',
    'Post-it Pastel Index Flags',
    'Study Supplies',
    55,
    'tabs',
    'Mark chapters and important sections without covering the text.',
    'Five colors · Repositionable tabs',
    {'Pastel set': 24},
  ),
  Product(
    'pen-set',
    'Staedtler Pigment Liner Set',
    'Study Supplies',
    119,
    'pens',
    'Three fine tip pens for annotations, diagrams, and margin notes.',
    'Black pigment ink · Three pens',
    {'Black ink': 22},
  ),
  Product(
    'study-cards',
    'Kokuyo Ring-Bound Flash Cards',
    'Study Supplies',
    79,
    'cards',
    'Make your own quizzes for formulas, definitions, and key terms.',
    'Blank study cards · Binder ring',
    {'Ruled cards': 20},
  ),
];
const categories = [
  'All items',
  'Books',
  'Study Supplies',
  'Pins & Ribbons',
  'PE Uniforms',
  'ID Accessories',
  'Course Pins',
];
const locations = [
  'Main Bookstore',
];
const slots = [
  '09:00–09:15',
  '09:15–09:30',
  '10:00–10:15',
  '10:15–10:30',
  '13:00–13:15',
  '13:15–13:30',
];

String _currentVariant(String id, String variant) => switch ((id, variant)) {
  ('algorithms-guide', 'Paperback') => 'Hardcover',
  ('grid-notebook', 'Navy') => 'Gray',
  _ => variant,
};

class CartLine {
  final String productId, variant;
  final bool reservation;
  int quantity;
  CartLine(this.productId, this.variant, this.quantity, this.reservation);
  Product get product => catalog.firstWhere((p) => p.id == productId);
  String get key => '$productId|$variant|$reservation';
  int get total => product.price * quantity;
  Map<String, dynamic> toJson() => {
    'product': productId,
    'variant': variant,
    'quantity': quantity,
    'reservation': reservation,
  };
  factory CartLine.fromJson(Map<String, dynamic> j) {
    final id = j['product'] as String;
    final variant = _currentVariant(id, j['variant'] as String);
    return CartLine(id, variant, j['quantity'], j['reservation']);
  }
  CartLine copy() => CartLine(productId, variant, quantity, reservation);
}

class Order {
  final String id, claim, location, method, created;
  final List<CartLine> lines;
  String slot;
  int stage;
  String? collectedAt;
  Order({
    required this.id,
    required this.claim,
    required this.location,
    required this.method,
    required this.lines,
    required this.slot,
    required this.created,
    this.stage = 0,
    this.collectedAt,
  });
  int get total => lines.fold(0, (a, b) => a + b.total);
  bool get reservation => lines.any((l) => l.reservation);
  List<String> get stages => reservation
      ? [
          'Payment confirmed',
          'Awaiting restock',
          'Ready to schedule',
          'Ready for pickup',
          'Collected',
        ]
      : [
          'Payment confirmed',
          'Preparing order',
          'Ready for pickup',
          'Collected',
        ];
  bool get ready => stage == stages.length - 2;
  bool get collected => stage == stages.length - 1;
  Map<String, dynamic> toJson() => {
    'id': id,
    'claim': claim,
    'location': location,
    'method': method,
    'lines': lines.map((l) => l.toJson()).toList(),
    'slot': slot,
    'created': created,
    'stage': stage,
    'collectedAt': collectedAt,
  };
  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    claim: j['claim'],
    location: j['location'],
    method: j['method'],
    lines: (j['lines'] as List).map((e) => CartLine.fromJson(e)).toList(),
    slot: j['slot'],
    created: j['created'],
    stage: j['stage'],
    collectedAt: j['collectedAt'],
  );
}

/// Local demo repository. Production payment and handover validation belongs on a server.
class Store extends ChangeNotifier {
  final SharedPreferences? prefs;
  // Test fixture / local payment adapter; no gateway requests are made.
  final String paymentOutcome;
  final String storageKey;
  final Future<void> Function()? onSignOut;
  Store({
    this.prefs,
    this.paymentOutcome = 'Success',
    this.storageKey = 'magisstore.v1',
    this.onSignOut,
  }) {
    _restore();
  }
  bool dark = false;
  final List<CartLine> cart = [];
  final List<Order> orders = [];
  final Set<String> favorites = {};
  final Map<String, int> sold = {};
  String? persistenceError;
  int get count => cart.fold(0, (a, b) => a + b.quantity);
  int get total => cart.fold(0, (a, b) => a + b.total);
  int get readyOrdersCount => orders.where((o) => o.ready).length;
  List<Order> get readyOrders => orders.where((o) => o.ready).toList();
  int stock(Product p, String variant) =>
      ((p.variants[variant] ?? 0) - (sold['${p.id}|$variant'] ?? 0)).clamp(
        0,
        999,
      );
  int available(Product p) =>
      p.variants.keys.fold(0, (a, v) => a + stock(p, v));
  void _restore() {
    try {
      final raw = prefs?.getString(storageKey);
      if (raw == null) return;
      final j = jsonDecode(raw);
      dark = j['dark'] ?? false;
      cart.addAll((j['cart'] as List).map((e) => CartLine.fromJson(e)));
      orders.addAll((j['orders'] as List).map((e) => Order.fromJson(e)));
      favorites.addAll((j['favorites'] as List).cast<String>());
      for (final entry in (j['sold'] as Map).entries) {
        final key = entry.key.toString();
        final separator = key.indexOf('|');
        final String currentKey;
        if (separator < 0) {
          currentKey = key;
        } else {
          final id = key.substring(0, separator);
          currentKey = '$id|${_currentVariant(id, key.substring(separator + 1))}';
        }
        sold.update(currentKey, (count) => count + (entry.value as int),
            ifAbsent: () => entry.value as int);
      }
    } catch (_) {
      persistenceError =
          'Saved data could not be restored. This session starts fresh.';
    }
  }

  Future<void> changed() async {
    notifyListeners();
    try {
      await prefs?.setString(
        storageKey,
        jsonEncode({
          'dark': dark,
          'cart': cart.map((l) => l.toJson()).toList(),
          'orders': orders.map((o) => o.toJson()).toList(),
          'favorites': favorites.toList(),
          'sold': sold,
        }),
      );
    } catch (_) {
      persistenceError = 'Local storage is unavailable. Keep this tab open to retain your order.';
      notifyListeners();
    }
  }

  void toggleTheme() {
    dark = !dark;
    changed();
  }

  void favorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    changed();
  }

  String? add(Product p, String variant, int quantity, {bool reserve = false}) {
    if (!p.active) return 'This placeholder product is no longer offered.';
    if (!p.variants.containsKey(variant) || quantity < 1) {
      return 'Select a valid variant and quantity.';
    }
    if (cart.isNotEmpty && cart.first.reservation != reserve) {
      return 'Please check out your current bag first. Reservations are collected separately.';
    }
    final key = '${p.id}|$variant|$reserve';
    final index = cart.indexWhere((l) => l.key == key);
    final requested = quantity + (index < 0 ? 0 : cart[index].quantity);
    if (requested > (reserve ? 5 : stock(p, variant))) {
      return reserve
          ? 'Reserve up to 5 per variant.'
          : 'Only ${stock(p, variant)} available in this variant.';
    }
    if (index < 0) {
      cart.add(CartLine(p.id, variant, quantity, reserve));
    } else {
      cart[index].quantity = requested;
    }
    changed();
    return null;
  }

  String? quantity(CartLine line, int value) {
    if (value < 1) {
      cart.remove(line);
      changed();
      return null;
    }
    if (value > (line.reservation ? 5 : stock(line.product, line.variant))) {
      return 'You have reached the available quantity.';
    }
    line.quantity = value;
    changed();
    return null;
  }

  bool slotOpen(String location, String slot) =>
      locations.contains(location) &&
      slot != slots[1] &&
      orders
              .where(
                (o) => !o.collected && o.location == location && o.slot == slot,
              )
              .length <
          3;
  String? validate(String location, String slot) {
    if (cart.isEmpty) return 'Your bag is empty.';
    if (!locations.contains(location)) {
      return 'Choose an open pickup location.';
    }
    if (!cart.first.reservation &&
        (!slots.contains(slot) || !slotOpen(location, slot))) {
      return 'This pickup window is unavailable. Choose another.';
    }
    for (final l in cart) {
      if (!l.product.active || !l.product.variants.containsKey(l.variant)) {
        return 'Update your bag: this product or variant is no longer offered.';
      }
      if (!l.reservation && l.quantity > stock(l.product, l.variant)) {
        return '${l.product.name} stock changed. Update your bag.';
      }
    }
    return null;
  }

  Order checkout(String location, String slot, String method) {
    final error = validate(location, slot);
    if (error != null) throw StateError(error);
    final random = Random.secure();
    final claim = List.generate(
      20,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final order = Order(
      id: 'MG-${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      claim: claim,
      location: location,
      slot: cart.first.reservation ? 'Schedule after restock' : slot,
      method: method,
      lines: cart.map((l) => l.copy()).toList(),
      created: DateTime.now().toIso8601String(),
      stage: 1,
    );
    for (final l in cart.where((l) => !l.reservation)) {
      final k = '${l.productId}|${l.variant}';
      sold[k] = (sold[k] ?? 0) + l.quantity;
    }
    orders.insert(0, order);
    cart.clear();
    changed();
    return order;
  }

  Order? order(String id) {
    final clean = Uri.decodeComponent(id).trim().toLowerCase();
    for (final o in orders) {
      if (o.id.trim().toLowerCase() == clean) return o;
    }
    return null;
  }

  Order? lookup(String value) {
    final raw = value.trim().replaceFirst('magisstore:claim:', '');
    for (final o in orders) {
      if (o.claim == raw || o.id.toLowerCase() == raw.toLowerCase()) return o;
    }
    return null;
  }

  void prepare(Order order) {
    if (order.reservation) {
      if (order.stage == 1) {
        order.stage = 2;
        changed();
      } else if (order.stage == 2) {
        order.stage = 3;
        changed();
      }
    } else {
      if (order.stage == 1) {
        order.stage = 2;
        changed();
      }
    }
  }

  void markReady(String orderId) {
    final o = order(orderId);
    if (o != null) prepare(o);
  }

  String? schedule(Order order, String slot) {
    if (!order.reservation || order.stage != 2) {
      return 'This reservation is not ready to schedule.';
    }
    if (!slots.contains(slot) || !slotOpen(order.location, slot)) {
      return 'Choose an available pickup window.';
    }
    order.slot = slot;
    order.stage = 3;
    changed();
    return null;
  }

  String? handover(Order o, String location, bool idVerified) {
    if (o.collected) return 'This order has already been collected.';
    if (o.location != location) {
      return 'Wrong pickup location. Proceed to ${o.location}.';
    }
    if (!o.ready) return 'This order is not ready for collection.';
    if (!idVerified) return 'Verify the student’s Ateneo ID before handover.';
    o.stage = o.stages.length - 1;
    o.collectedAt = DateTime.now().toIso8601String();
    changed();
    return null;
  }
}
