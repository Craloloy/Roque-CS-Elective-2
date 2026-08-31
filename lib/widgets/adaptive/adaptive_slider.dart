import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

class AdaptiveSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;

  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformSettings.of(context).isCupertinoActive(context);

    if (isCupertino) {
      return CupertinoSlider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor,
        onChanged: onChanged,
      );
    }

    return Slider(
      value: value.clamp(min, max),
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
      onChanged: onChanged,
    );
  }
}
