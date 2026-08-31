import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

class AdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isCupertino = PlatformSettings.of(context).isCupertinoActive(context);

    if (isCupertino) {
      return CupertinoSwitch(
        value: value,
        activeTrackColor: activeColor,
        onChanged: onChanged,
      );
    }

    return Switch(
      value: value,
      activeTrackColor: activeColor,
      onChanged: onChanged,
    );
  }
}
