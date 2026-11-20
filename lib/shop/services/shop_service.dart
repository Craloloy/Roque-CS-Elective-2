import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../product_browser/supabase_config.dart';
import '../models/shop.dart';

class EmailConfirmationNeeded extends ShopIssue {
  const EmailConfirmationNeeded()
    : super('Confirm your email before signing in.');
}

class EmailAlreadyRegistered extends ShopIssue {
  const EmailAlreadyRegistered() : super('This email is already registered.');
}

String shopMessage(Object e) {
  if (e is ShopIssue) return e.message;
  if (e is AuthException) return e.message;
  if (e is StorageException) return 'Photo: ${e.message}';
  if (e is PostgrestException) {
    if (e.code == '42501') {
      return 'Your account does not have permission for this action.';
    }
    if (e.code == '23503' || e.code == '23001') {
      return 'This category still has products. Move them to another category first.';
    }
    if (e.code == '23505') return 'That name is already in use.';
    if (e.code == 'PGRST106') {
      return 'Add magistore to the exposed schemas in Supabase Data API settings.';
    }
    if (e.code == 'P0001') return e.message;
    return 'Database: ${e.message}';
  }
  return 'Could not reach MagiStore. Check your connection and try again.';
}

String requestId() {
  final r = Random.secure();
  final b = List.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final h = b.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

bool _missingOrderSize(PostgrestException error) =>
    error.code == '42703' && RegExp(r'\bsize\b').hasMatch(error.message);

class ShopService {
  ShopService(this._client);
  final SupabaseClient _client;
  static Future<ShopService> connect() async {
    const url = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: SupabaseConfig.url,
    );
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: SupabaseConfig.anonKey,
    );
    if (!url.startsWith('https://') ||
        url.contains('YOUR-PROJECT') ||
        key.isEmpty ||
        key.startsWith('YOUR-')) {
      throw const ShopIssue(
        'Set the project URL and publishable key in lib/product_browser/supabase_config.dart.',
      );
    }
    await Supabase.initialize(url: url, publishableKey: key).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw const ShopIssue(
        'MagiStore could not connect to Supabase in time. Check your connection and try again.',
      ),
    );
    return ShopService(Supabase.instance.client);
  }

  String? get redirect => kIsWeb
      ? '${Uri.base.origin}/'
      : (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS
            ? 'com.craloloy.apexcomputing://auth-callback/'
            : null);
  Stream<String?> sessions() => Stream<String?>.multi((events) {
    final auth = _client.auth;
    final sub = auth.onAuthStateChange.listen(
      (_) => events.add(auth.currentSession?.user.id),
      onError: events.addError,
      onDone: events.close,
    );
    events.onCancel = sub.cancel;
    events.add(auth.currentSession?.user.id);
  }).distinct();
  Future<void> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') {
        throw const EmailConfirmationNeeded();
      }
      rethrow;
    }
  }

  Future<bool> signup(
    String email,
    String password,
    String first,
    String last,
  ) async {
    try {
      final r = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirect,
        data: {'firstname': first, 'lastname': last},
      );
      return r.session == null;
    } on AuthException catch (e) {
      if (e.code == 'user_already_exists' || e.code == 'email_exists') {
        throw const EmailAlreadyRegistered();
      }
      rethrow;
    }
  }

  Future<void> resendConfirmation(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: redirect,
    );
  }

  Future<void> google() async {
    if (!await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirect,
    )) {
      throw const ShopIssue('Could not open Google sign-in. Try again.');
    }
  }

  Future<void> logout() => _client.auth.signOut(scope: SignOutScope.local);
  SupabaseQuerySchema get _db => _client.schema('magistore');
  Future<Account> account(String id) async {
    final r = await _db
        .from('profiles')
        .select('id,email,roles(role)')
        .eq('id', id)
        .maybeSingle();
    if (r == null) {
      throw const ShopIssue(
        'No MagiStore profile was found. Check that the setup SQL ran in this project.',
      );
    }
    final role = r['roles']?['role'];
    if (role != 'customer' && role != 'admin') {
      throw const ShopIssue('Your shop role is missing.');
    }
    return Account(id, r['email'] ?? '', role);
  }

  Future<List<Category>> categories() async =>
      (await _db
              .from('categories')
              .select('id,name')
              .order('name', ascending: true))
          .map(Category.from)
          .toList();
  static const fields =
      'id,name,description,price,stock,image_url,categories(id,name)';
  Future<({List<Item> items, int count})> catalog(Filters f) async {
    if (f.savedIds.isEmpty) return (items: <Item>[], count: 0);
    var q = _db.from('products').select(fields);
    if (f.availableOnly) q = q.gt('stock', 0);
    if (f.category != null) q = q.eq('category_id', f.category!);
    if (f.minCents != null) q = q.gte('price', f.minCents! / 100);
    if (f.maxCents != null) q = q.lte('price', f.maxCents! / 100);
    if (f.savedIds != '*') {
      q = q.inFilter('id', f.savedIds.split(',').map(int.parse).toList());
    }
    final query = f.search
        .trim()
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    if (query.isNotEmpty) q = q.ilike('name', '$query%');
    final ordered = f.sort == 'Featured'
        ? q.order('id', ascending: true)
        : q
              .order('price', ascending: f.sort == 'Lowest price')
              .order('id', ascending: true);
    final r = await ordered
        .range(f.page * pageSize, (f.page + 1) * pageSize - 1)
        .count(CountOption.exact);
    return (items: r.data.map(Item.from).toList(), count: r.count);
  }

  Future<List<Item>> related(Item i) async =>
      (await _db
              .from('products')
              .select(fields)
              .eq('category_id', i.category.id)
              .neq('id', i.id)
              .order('id', ascending: true)
              .limit(4))
          .map(Item.from)
          .toList();
  Future<List<Item>> bagItems(List<int> ids) async => ids.isEmpty
      ? <Item>[]
      : (await _db.from('products').select(fields).inFilter('id', ids))
            .map(Item.from)
            .toList();
  Future<Receipt> checkout(Map<BagKey, BagLine> bag, String key) async {
    if (bag.keys.any((line) => line.size != null)) {
      try {
        await _db.from('order_items').select('size').limit(0);
      } on PostgrestException catch (e) {
        if (!_missingOrderSize(e)) rethrow;
        throw const ShopIssue(
          'Uniform orders are temporarily unavailable. Please contact the store.',
        );
      }
    }
    return Receipt.from(
      await _db.rpc(
        'checkout',
        params: {
          'p_request_id': key,
          'p_items': bag.entries
              .map(
                (e) => {
                  'product_id': e.key.id,
                  'quantity': e.value.quantity,
                  if (e.key.size != null) 'size': e.key.size,
                },
              )
              .toList(),
        },
      ),
    );
  }

  Future<List<Purchase>> orders(Account account) async {
    try {
      return await _orders(account, includeSize: true);
    } on PostgrestException catch (e) {
      if (!_missingOrderSize(e)) rethrow;
      return _orders(account, includeSize: false);
    }
  }

  Future<List<Purchase>> _orders(
    Account account, {
    required bool includeSize,
  }) async {
    final size = includeSize ? ',size' : '';
    final out = <Purchase>[];
    for (var start = 0; ; start += 100) {
      var q = _db
          .from('orders')
          .select(
            'id,user_id,created_at,status,total,order_items(product_name,unit_price,quantity$size)',
          );
      if (!account.admin) q = q.eq('user_id', account.id);
      final rows = await q
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .range(start, start + 99);
      final customers = <String, OrderCustomer>{};
      if (account.admin && rows.isNotEmpty) {
        // Orders and profiles both refer to auth.users. Use the existing
        // profile policy and fetch all customers on this page together.
        final ids = rows.map((row) => row['user_id'] as String).toSet();
        final profiles = await _db
            .from('profiles')
            .select('id,firstname,lastname,email')
            .inFilter('id', ids.toList());
        for (final profile in profiles) {
          customers[profile['id'] as String] = OrderCustomer.from(profile);
        }
      }
      out.addAll(
        rows.map(
          (row) => Purchase.from(row, customer: customers[row['user_id']]),
        ),
      );
      if (rows.length < 100) return out;
    }
  }

  Future<List<int>> orderNotifications(Account account) async {
    var query = _db
        .from('orders')
        .select('id')
        .eq('status', account.admin ? 'done' : 'ready');
    if (!account.admin) query = query.eq('user_id', account.id);
    final rows = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map((row) => row['id'] as int).toList();
  }

  Future<List<Item>> stockNotifications(
    Account account,
    List<int> tracked,
  ) async {
    if (!account.admin && tracked.isEmpty) return [];
    var query = _db
        .from('products')
        .select(fields)
        .lte('stock', lowStockThreshold);
    if (!account.admin) query = query.inFilter('id', tracked);
    final rows = await query.order('stock', ascending: true).order('name');
    return rows.map(Item.from).toList();
  }

  Future<void> confirmPickup(int id) async {
    try {
      await _db.rpc('confirm_pickup', params: {'p_order_id': id});
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        throw const ShopIssue(
          'Pickup confirmation is not available yet. Please ask the store for help.',
        );
      }
      rethrow;
    }
  }

  Future<void> status(int id, String status) async {
    await _db
        .from('orders')
        .update({'status': status})
        .eq('id', id)
        .select('id')
        .single();
  }

  Future<void> saveCategory(int? id, String name) async {
    final table = _db.from('categories');
    if (id == null) {
      await table.insert({'name': name});
    } else {
      await table.update({'name': name}).eq('id', id).select('id').single();
    }
  }

  Future<void> deleteCategory(int id) async {
    await _db.from('categories').delete().eq('id', id).select('id').single();
  }

  Future<void> deleteItem(int id) async {
    await _db.from('products').delete().eq('id', id).select('id').single();
  }

  Future<void> saveItem(int? id, Json fields) async {
    final table = _db.from('products');
    if (id == null) {
      await table.insert(fields);
    } else {
      await table.update(fields).eq('id', id).select('id').single();
    }
  }

  Future<String> upload(Uint8List bytes, String mime) async {
    final ext = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
    }[mime];
    if (ext == null || bytes.isEmpty || bytes.length > 5242880) {
      throw const ShopIssue('Choose a JPG, PNG or WebP photo under 5 MB.');
    }
    final bucket = _client.storage.from('magistore-products');
    final path = '${requestId()}.$ext';
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: mime),
    );
    return bucket.getPublicUrl(path);
  }
}
