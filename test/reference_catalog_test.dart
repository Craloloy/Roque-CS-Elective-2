import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_ecommerce_app/store.dart';

void main() {
  test('seven supplied products replace the invented catalog items', () {
    final active = catalog.where((p) => p.active).toList();
    expect(active.map((p) => p.id).toSet(), {
      'pin',
      'sling',
      'uniform',
      'caduceus',
      'case',
      'ribbon',
      'polo',
    });
    expect(
      active.where((p) => p.category == 'PE Uniforms').every((p) => p.references.isNotEmpty),
      isTrue,
    );
    expect(
      active.where((p) => p.category != 'PE Uniforms').every((p) => p.references.isEmpty),
      isTrue,
    );
    expect(
      active
          .where((p) => p.category == 'PE Uniforms')
          .map((p) => p.kind)
          .toSet(),
      {'pe_round', 'pe_polo'},
    );
    expect(
      active.firstWhere((p) => p.id == 'ribbon').material,
      contains('Unprinted'),
    );
    expect(
      active.firstWhere((p) => p.id == 'case').material,
      contains('landscape'),
    );
  });
  test('removed variants fail gracefully while historical products remain readable', () {
    final store = Store();
    expect(store.stock(catalog.first, 'Silver'), 0);
    expect(store.add(catalog.first, 'Silver', 1), isNotNull);
    final legacy = catalog.firstWhere((p) => p.id == 'cs');
    expect(store.add(legacy, 'CS blue', 1), isNotNull);
    expect(CartLine('cs', 'CS blue', 1, false).product.name, isNotEmpty);
    store.cart.add(CartLine('sling', 'White', 1, false));
    expect(store.validate(locations.first, slots.first), isNotNull);
  });
}
