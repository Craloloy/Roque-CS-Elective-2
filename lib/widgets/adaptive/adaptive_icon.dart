import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

class AdaptiveIcon extends StatelessWidget {
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final double? size;
  final Color? color;

  const AdaptiveIcon({
    super.key,
    required this.materialIcon,
    required this.cupertinoIcon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformSettings.of(context).isCupertinoActive(context);
    return Icon(
      isCupertino ? cupertinoIcon : materialIcon,
      size: size,
      color: color,
    );
  }
}
