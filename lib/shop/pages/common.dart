import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/shop_service.dart';
import '../models/shop.dart';
import '../../theme.dart';

const shopContentMaxWidth = 1250.0;
const shopHorizontalPadding = 16.0;

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> perform(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) toast(context, shopMessage(e));
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String body, {
  String actionLabel = 'Delete',
}) async =>
    true ==
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

class Load<T> extends StatelessWidget {
  const Load(this.value, {required this.retry, required this.data, super.key});
  final AsyncValue<T> value;
  final VoidCallback retry;
  final Widget Function(T) data;
  @override
  Widget build(BuildContext context) => value.when(
    data: data,
    loading: () => const Padding(
      padding: EdgeInsets.all(30),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (e, _) => Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(shopMessage(e), textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class Empty extends StatelessWidget {
  const Empty(this.icon, this.title, this.hint, {super.key});
  final IconData icon;
  final String title, hint;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 14),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 34, color: Brand.blue),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        Text(hint, textAlign: TextAlign.center),
      ],
    ),
  );
}

class Photo extends StatelessWidget {
  const Photo(this.item, {this.height = 150, super.key});
  final Item item;
  final double height;
  @override
  Widget build(BuildContext context) {
    Widget missing(BuildContext _, Object e, StackTrace? st) =>
        const Center(child: Icon(Icons.image_not_supported_outlined));
    final src = item.image;
    final img = src.startsWith('assets/products/')
        ? Image.asset(
            src,
            fit: BoxFit.contain,
            semanticLabel: item.name,
            errorBuilder: missing,
          )
        : Image.network(
            src,
            fit: BoxFit.contain,
            semanticLabel: item.name,
            errorBuilder: missing,
          );
    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Brand.productSurface(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: img,
    );
  }
}

void open(BuildContext c, Widget page) =>
    Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => page));

class ShopPullToRefresh extends StatelessWidget {
  const ShopPullToRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return ScrollConfiguration(
      behavior: behavior.copyWith(
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: RefreshIndicator(onRefresh: onRefresh, child: child),
    );
  }
}
