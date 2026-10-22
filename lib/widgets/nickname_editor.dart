import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/pokedex_controller.dart';

class NicknameEditor extends ConsumerStatefulWidget {
  const NicknameEditor({super.key, required this.pokemonId});
  final int pokemonId;

  @override
  ConsumerState<NicknameEditor> createState() => _NicknameEditorState();
}

class _NicknameEditorState extends ConsumerState<NicknameEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: ref.read(pokedexProvider).nicknameFor(widget.pokemonId) ?? '',
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final error = ref
        .read(pokedexProvider.notifier)
        .saveNickname(widget.pokemonId, _textController.text);
    if (error == null) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pokedexProvider);
    final pokemon = state.pokemonById(widget.pokemonId);
    return AlertDialog(
      title: const Text('A name just for them'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Original name: ${pokemon?.name.toUpperCase() ?? "Pokémon"}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('nickname-input'),
                controller: _textController,
                autofocus: true,
                maxLength: 24,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nickname',
                  hintText: 'e.g. Leafy',
                  helperText: 'Leave blank to remove the nickname.',
                ),
                validator: (text) => (text ?? '').trim().runes.length > 24
                    ? 'Use 24 characters or fewer.'
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (state.nicknameFor(widget.pokemonId) != null)
          TextButton(
            key: const ValueKey('remove-nickname'),
            onPressed: () {
              ref
                  .read(pokedexProvider.notifier)
                  .removeNickname(widget.pokemonId);
              Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const ValueKey('save-nickname'),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
