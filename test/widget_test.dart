import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/pokemon.dart';

void main() {
  test('Reads trading-card types, height, and weight from the API', () {
    final pokemon = Pokemon.fromJson({
      'name': 'bulbasaur', 'id': 1,
      'sprites': {'front_default': null},
      'types': [
        {'type': {'name': 'grass'}},
        {'type': {'name': 'poison'}},
      ],
      'height': 7, 'weight': 69,
    });
    expect(pokemon.types, ['grass', 'poison']);
    expect(pokemon.heightCm, 70);
    expect(pokemon.weightKg, 6.9);
  });

  test('Uses the official artwork URL supplied by PokéAPI', () {
    final pokemon = Pokemon.fromJson({
      'name': 'bulbasaur',
      'id': 1,
      'sprites': {
        'front_default': 'https://example.com/sprite.png',
        'other': {
          'official-artwork': {'front_default': 'https://example.com/artwork.png'},
        },
      },
    });

    expect(pokemon.id, 1);
    expect(pokemon.name, 'bulbasaur');
    expect(pokemon.imageUrl, 'https://example.com/artwork.png');
  });

  test('Rejects an invalid Pokémon ID', () {
    expect(
      () => Pokemon.fromJson({
        'name': 'bulbasaur',
        'id': 'invalid',
        'sprites': {},
      }),
      throwsFormatException,
    );
  });
  test('Falls back to the API sprite when official artwork is missing', () {
    final pokemon = Pokemon.fromJson({
      'name': 'bulbasaur', 'id': 1,
      'sprites': {'front_default': 'https://example.com/sprite.png'},
    });
    expect(pokemon.imageUrl, 'https://example.com/sprite.png');
  });

  test('Allows missing images without inventing a URL', () {
    final pokemon = Pokemon.fromJson({
      'name': 'bulbasaur', 'id': 1, 'sprites': {'front_default': null},
    });
    expect(pokemon.imageUrl, isNull);
  });
}
