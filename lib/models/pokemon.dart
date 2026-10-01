class Pokemon {
  const Pokemon({required this.id, required this.name, required this.imageUrl,
    this.types = const [], this.heightCm, this.weightKg});

  final int id;
  final String name;

  final String? imageUrl;
  final List<String> types;
  final int? heightCm;
  final double? weightKg;

  factory Pokemon.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    final id = json['id'];
    final sprites = json['sprites'];
    if (name is! String || name.isEmpty || id is! int || id <= 0 ||
        sprites is! Map<String, dynamic>) {
      throw const FormatException('Invalid Pokémon data.');
    }

    final other = sprites['other'];
    final artwork = other is Map ? other['official-artwork'] : null;
    final officialImage = artwork is Map ? artwork['front_default'] : null;
    final spriteImage = sprites['front_default'];
    final image = officialImage is String && officialImage.isNotEmpty
        ? officialImage
        : spriteImage;
    if (image != null && image is! String) {
      throw const FormatException('Invalid Pokémon image.');
    }

    final rawTypes = json['types'];
    final types = rawTypes is List
        ? rawTypes.map((entry) => entry['type']['name'] as String).toList()
        : <String>[];
    final height = json['height'];
    final weight = json['weight'];
    return Pokemon(id: id, name: name, imageUrl: image as String?, types: types,
      heightCm: height is int ? height * 10 : null,
      weightKg: weight is num ? weight / 10 : null);
  }
}
