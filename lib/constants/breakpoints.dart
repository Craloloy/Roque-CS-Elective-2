import 'package:flutter/material.dart';

const double kMobileBreakpoint = 600.0;
const double kDesktopBreakpoint = 1024.0;

enum DeviceType { mobile, tablet, desktop }

DeviceType getDeviceType(double width) {
  if (width < kMobileBreakpoint) {
    return DeviceType.mobile;
  } else if (width < kDesktopBreakpoint) {
    return DeviceType.tablet;
  } else {
    return DeviceType.desktop;
  }
}

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < kMobileBreakpoint;

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= kMobileBreakpoint && width < kDesktopBreakpoint;
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= kDesktopBreakpoint;
