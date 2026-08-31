import 'package:flutter/material.dart';
import '../../constants/breakpoints.dart';

typedef ResponsiveWidgetBuilder = Widget Function(
    BuildContext context, BoxConstraints constraints);

class ResponsiveLayout extends StatelessWidget {
  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kDesktopBreakpoint) {
          return desktop(context, constraints);
        } else if (constraints.maxWidth >= kMobileBreakpoint) {
          return tablet != null
              ? tablet!(context, constraints)
              : desktop(context, constraints);
        } else {
          return mobile(context, constraints);
        }
      },
    );
  }
}
