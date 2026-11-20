import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shop.dart';
import '../providers/shop_providers.dart';
import '../services/shop_service.dart';
import 'common.dart';

class ProductForm extends ConsumerStatefulWidget {
  const ProductForm({this.item, super.key});
  final Item? item;
  @override
  ConsumerState<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends ConsumerState<ProductForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.item?.name),
      desc = TextEditingController(text: widget.item?.description),
      price = TextEditingController(
        text: widget.item == null
            ? ''
            : (widget.item!.price / 100).toStringAsFixed(2),
      ),
      stock = TextEditingController(text: widget.item?.stock.toString());
  late int? category = widget.item?.category.id;
  late String? image = widget.item?.image;
  Uint8List? bytes;
  String? mime, error;
  bool busy = false;
  @override
  void dispose() {
    for (final x in [name, desc, price, stock]) {
      x.dispose();
    }
    super.dispose();
  }

  Future<void> pick() async {
    try {
      const allowed = XTypeGroup(
        label: 'Product photos',
        extensions: ['jpg', 'jpeg', 'png', 'webp'],
        mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
        uniformTypeIdentifiers: [
          'public.jpeg',
          'public.png',
          'org.webmproject.webp',
        ],
      );
      final file = await openFile(acceptedTypeGroups: const [allowed]);
      if (file == null) return;
      if (await file.length() > 5242880) {
        throw const ShopIssue('Choose a photo under 5 MB.');
      }
      final b = await file.readAsBytes();
      final type = b.length < 12
          ? null
          : b[0] == 255 && b[1] == 216 && b[2] == 255
          ? 'image/jpeg'
          : b[0] == 137 && b[1] == 80 && b[2] == 78 && b[3] == 71
          ? 'image/png'
          : String.fromCharCodes(b.take(4)) == 'RIFF' &&
                String.fromCharCodes(b.skip(8).take(4)) == 'WEBP'
          ? 'image/webp'
          : null;
      if (type == null) {
        throw const ShopIssue('Choose a JPG, PNG or WebP image.');
      }
      if (mounted) {
        setState(() {
          bytes = b;
          mime = type;
          image = null;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = shopMessage(e));
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (bytes == null && image == null) {
      setState(() => error = 'Choose a product photo.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final admin = ref.read(managerProvider);
      // Keep a completed upload for retry if saving the product fails.
      image ??= await admin.upload(bytes!, mime!);
      if (!mounted) return;
      await admin.product(widget.item?.id, {
        'name': name.text.trim(),
        'description': desc.text.trim(),
        'price': price.text.trim(),
        'stock': int.parse(stock.text.trim()),
        'category_id': category,
        'image_url': image,
      });
      if (mounted) {
        toast(context, 'Product saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => error = shopMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) {
    if (!ref.watch(currentAccount).admin) {
      return const Scaffold(
        body: Center(child: Text('Admin access required.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add product' : 'Edit product'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Load(
                ref.watch(categoryProvider),
                retry: () => ref.invalidate(categoryProvider),
                data: (cats) => cats.isEmpty
                    ? const Empty(
                        Icons.category_outlined,
                        'Add a category first',
                        'Open Account → Manage categories.',
                      )
                    : Form(
                        key: form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (bytes != null)
                              Image.memory(
                                bytes!,
                                height: 150,
                                fit: BoxFit.contain,
                              )
                            else if (widget.item != null)
                              Photo(widget.item!, height: 150),
                            OutlinedButton.icon(
                              onPressed: busy ? null : pick,
                              icon: const Icon(
                                Icons.add_photo_alternate_outlined,
                              ),
                              label: Text(
                                image != null || bytes != null
                                    ? 'Change photo'
                                    : 'Choose product photo',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: name,
                              maxLength: 160,
                              decoration: const InputDecoration(
                                labelText: 'Product name',
                              ),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Enter a product name'
                                  : null,
                            ),
                            TextFormField(
                              controller: desc,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                              ),
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Enter a short description'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: cats.any((e) => e.id == category)
                                  ? category
                                  : null,
                              isExpanded: true,
                              items: cats
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e.id,
                                      child: Text(e.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: busy
                                  ? null
                                  : (v) => setState(() => category = v),
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              validator: (v) =>
                                  v == null ? 'Select a category' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: price,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Price (₱)',
                              ),
                              validator: (v) =>
                                  RegExp(
                                    r'^\d{1,10}(\.\d{1,2})?$',
                                  ).hasMatch(v!.trim())
                                  ? null
                                  : 'Enter a non-negative price with up to two decimals',
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: stock,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Units in stock',
                              ),
                              validator: (v) {
                                final n = int.tryParse(v!.trim());
                                return n == null || n < 0 || n > 2147483647
                                    ? 'Enter a non-negative whole stock quantity'
                                    : null;
                              },
                            ),
                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(c).colorScheme.error,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: busy ? null : save,
                              child: Text(busy ? 'Saving…' : 'Save product'),
                            ),
                          ],
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

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});
  Future<void> edit(BuildContext c, Category? cat) async {
    await showDialog<void>(context: c, builder: (_) => _CategoryDialog(cat));
  }

  @override
  Widget build(BuildContext c, WidgetRef ref) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Categories',
              style: Theme.of(c).textTheme.headlineMedium,
            ),
          ),
          FilledButton.icon(
            onPressed: () => edit(c, null),
            icon: const Icon(Icons.add),
            label: const Text('Add'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Load(
        ref.watch(categoryProvider),
        retry: () => ref.invalidate(categoryProvider),
        data: (list) => list.isEmpty
            ? const Empty(
                Icons.category_outlined,
                'No categories yet',
                'Add one to start organizing the catalog.',
              )
            : Column(
                children: [
                  for (final cat in list)
                    Card(
                      child: ListTile(
                        title: Text(cat.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Rename category',
                              onPressed: () => edit(c, cat),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Delete category',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                if (await confirm(
                                      c,
                                      'Delete ${cat.name}?',
                                      'Only empty categories can be deleted.',
                                    ) &&
                                    c.mounted) {
                                  await perform(
                                    c,
                                    () => ref
                                        .read(managerProvider)
                                        .removeCategory(cat.id),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog(this.cat);
  final Category? cat;
  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final name = TextEditingController(text: widget.cat?.name);
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      setState(() => error = 'Enter a category name.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(managerProvider).category(widget.cat?.id, name.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = shopMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext c) => AlertDialog(
    title: Text(widget.cat == null ? 'Add category' : 'Rename category'),
    content: TextField(
      autofocus: true,
      controller: name,
      maxLength: 80,
      decoration: InputDecoration(labelText: 'Category name', errorText: error),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(c),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: busy ? null : save, child: const Text('Save')),
    ],
  );
}
