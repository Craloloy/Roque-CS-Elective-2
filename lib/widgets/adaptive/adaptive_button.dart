import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

enum AdaptiveButtonType { filled, outlined, text }

class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final IconData? materialIcon;
  final IconData? cupertinoIcon;
  final AdaptiveButtonType type;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.materialIcon,
    this.cupertinoIcon,
    this.type = AdaptiveButtonType.filled,
    this.color,
    this.padding,
  });

  const AdaptiveButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.materialIcon,
    this.cupertinoIcon,
    this.color,
    this.padding,
  }) : type = AdaptiveButtonType.filled;

  const AdaptiveButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.materialIcon,
    this.cupertinoIcon,
    this.color,
    this.padding,
  }) : type = AdaptiveButtonType.outlined;

  const AdaptiveButton.text({
    super.key,
    required this.onPressed,
    required this.child,
    this.materialIcon,
    this.cupertinoIcon,
    this.color,
    this.padding,
  }) : type = AdaptiveButtonType.text;

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformSettings.of(context).isCupertinoActive(context);

    if (isCupertino) {
      final icon = cupertinoIcon != null
          ? Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(cupertinoIcon, size: 16),
            )
          : const SizedBox.shrink();

      final content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (cupertinoIcon != null) icon,
          Flexible(
            child: child,
          ),
        ],
      );

      switch (type) {
        case AdaptiveButtonType.filled:
          return CupertinoButton.filled(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            borderRadius: BorderRadius.circular(10),
            onPressed: onPressed,
            child: content,
          );
        case AdaptiveButtonType.outlined:
          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: color ?? CupertinoColors.activeBlue,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: CupertinoButton(
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: Colors.transparent,
              onPressed: onPressed,
              child: content,
            ),
          );
        case AdaptiveButtonType.text:
          return CupertinoButton(
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onPressed: onPressed,
            child: content,
          );
      }
    }

    // Material 3 Button styling
    final icon = materialIcon != null ? Icon(materialIcon, size: 18) : null;

    switch (type) {
      case AdaptiveButtonType.filled:
        if (icon != null) {
          return FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: color,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPressed,
            icon: icon,
            label: child,
          );
        }
        return FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: child,
        );
      case AdaptiveButtonType.outlined:
        if (icon != null) {
          return OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: color != null ? BorderSide(color: color!) : null,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onPressed,
            icon: icon,
            label: child,
          );
        }
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: color != null ? BorderSide(color: color!) : null,
            padding: padding ??
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onPressed,
          child: child,
        );
      case AdaptiveButtonType.text:
        if (icon != null) {
          return TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: padding,
            ),
            onPressed: onPressed,
            icon: icon,
            label: child,
          );
        }
        return TextButton(
          style: TextButton.styleFrom(
            foregroundColor: color,
            padding: padding,
          ),
          onPressed: onPressed,
          child: child,
        );
    }
  }
}
