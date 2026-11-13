import 'package:flutter/material.dart';

import 'store.dart';

/// Illustrated covers and packaging for the sample study catalog.
class StudyProductArt extends StatelessWidget {
  const StudyProductArt({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (product.id) {
      'dart-guide' => (const Color(0xFF123B66), Icons.code_rounded),
      'algorithms-guide' => (const Color(0xFF28534F), Icons.account_tree_outlined),
      'discrete-guide' => (const Color(0xFF473A65), Icons.calculate_outlined),
      'research-guide' => (const Color(0xFF703D50), Icons.edit_note_rounded),
      'grid-notebook' => (const Color(0xFF234264), Icons.grid_on_rounded),
      'index-tabs' => (const Color(0xFF5A4470), Icons.bookmarks_outlined),
      'pen-set' => (const Color(0xFF334C5B), Icons.edit_outlined),
      _ => (const Color(0xFF2E6158), Icons.style_outlined),
    };
    return Semantics(
      image: true,
      label: '${product.name} illustration',
      child: ExcludeSemantics(
        child: MediaQuery.withNoTextScaling(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 126,
                height: 158,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, Color.lerp(color, Colors.black, .25)!],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0x33000000)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 12, 9, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.kind == 'book' ? 'STUDY SERIES' : 'DESK ESSENTIALS',
                          style: const TextStyle(color: Color(0xFFFFD675), fontSize: 8,
                            fontWeight: FontWeight.w800, letterSpacing: 1.1),
                        ),
                        const SizedBox(height: 10),
                        Icon(icon, color: Colors.white, size: 26),
                        const Spacer(),
                        Text(
                          product.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 14, height: 1.12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('MAGISTORE', style: TextStyle(
                          fontSize: 8, color: Color(0xFFD9DDE4), letterSpacing: 1.1,
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
