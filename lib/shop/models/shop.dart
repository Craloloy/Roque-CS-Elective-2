typedef Json = Map<String, dynamic>;
typedef Filters = ({
  String search,
  int? category,
  int? minCents,
  int? maxCents,
  String sort,
  int page,
  String savedIds,
  bool availableOnly,
});
const pageSize = 8;
const lowStockThreshold = 5;
int cents(Object? value) => ((num.parse(value.toString())) * 100).round();
String pesos(int value) => '₱${(value / 100).toStringAsFixed(2)}';

class Account {
  const Account(this.id, this.email, this.role);
  final String id, email, role;
  bool get admin => role == 'admin';
}

class Category {
  const Category(this.id, this.name);
  Category.from(Json j) : this(j['id'] as int, j['name'] as String);
  final int id;
  final String name;
}

const uniformSizes = ['XS', 'S', 'M', 'L', 'XL'];
typedef BagKey = ({int id, String? size});

int bagQuantity(Map<BagKey, BagLine> bag, int id) => bag.values
    .where((line) => line.item.id == id)
    .fold(0, (total, line) => total + line.quantity);

class Item {
  const Item(
    this.id,
    this.name,
    this.description,
    this.price,
    this.stock,
    this.image,
    this.category,
  );
  Item.from(Json j)
    : this(
        j['id'],
        j['name'],
        j['description'],
        cents(j['price']),
        j['stock'],
        j['image_url'],
        Category.from(j['categories']),
      );
  final int id, price, stock;
  final String name, description, image;
  final Category category;
  bool get needsSize => category.name.trim().toLowerCase() == 'pe uniforms';
}

class Receipt {
  Receipt.from(Json j) : id = j['id'], total = cents(j['total']);
  final int id, total;
}

class OrderCustomer {
  OrderCustomer.from(Json j)
    : name = [
        (j['firstname'] as String?)?.trim() ?? '',
        (j['lastname'] as String?)?.trim() ?? '',
      ].where((part) => part.isNotEmpty).join(' '),
      email = (j['email'] as String?)?.trim() ?? '';

  final String name, email;

  String get displayName => name.isNotEmpty
      ? name
      : email.isNotEmpty
      ? email
      : 'Unknown student';
}

class Purchase {
  Purchase.from(Json j, {this.customer})
    : id = j['id'],
      status = j['status'],
      total = cents(j['total']),
      date = DateTime.parse(j['created_at']).toLocal(),
      userId = j['user_id'],
      lines = (j['order_items'] as List)
          .map(
            (e) => (
              name: e['product_name'] as String,
              size: e['size'] as String?,
              quantity: e['quantity'] as int,
              price: cents(e['unit_price']),
            ),
          )
          .toList();
  final int id, total;
  final String status, userId;
  final OrderCustomer? customer;
  final DateTime date;
  final List<({String name, String? size, int quantity, int price})> lines;
}

class BagLine {
  const BagLine(this.item, this.quantity, this.size);
  final String? size;
  final Item item;
  final int quantity;
}

class ShopIssue implements Exception {
  const ShopIssue(this.message);
  final String message;
  @override
  String toString() => message;
}
