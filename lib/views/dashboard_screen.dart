import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../constants/breakpoints.dart';
import '../state/platform_settings.dart';
import '../widgets/adaptive/adaptive_bottom_nav.dart';
import '../widgets/adaptive/adaptive_icon.dart';
import '../widgets/adaptive/adaptive_scaffold.dart';
import '../widgets/responsive/responsive_layout.dart';
import 'components/sidebar_nav.dart';
import 'desktop_layout.dart';
import 'mobile_layout.dart';
import 'tablet_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobileView = isMobile(context);
    final isTabletView = isTablet(context);
    final settings = PlatformSettings.of(context);

    return AdaptiveScaffold(
      title: const Text(
        'Lumina Study Hub',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      showDrawerButton: isTabletView, // Only show drawer on tablet, not on mobile
      drawer: isTabletView
          ? const Drawer(
              child: SafeArea(
                child: SidebarNav(isDrawer: true),
              ),
            )
          : null,
      bottomNavigationBar: isMobileView
          ? AdaptiveBottomNav(
              currentIndex: settings.selectedTabIndex,
              onTap: settings.setSelectedTabIndex,
            )
          : null,
      actions: [
        // Dark mode quick toggle
        IconButton(
          tooltip: 'Toggle Theme',
          icon: AdaptiveIcon(
            materialIcon: settings.isDarkMode
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            cupertinoIcon: settings.isDarkMode
                ? CupertinoIcons.sun_max
                : CupertinoIcons.moon,
            size: 20,
          ),
          onPressed: () => settings.toggleDarkMode(!settings.isDarkMode),
        ),
        const SizedBox(width: 8),
      ],
      body: ResponsiveLayout(
        mobile: (context, constraints) =>
            MobileDashboardLayout(constraints: constraints),
        tablet: (context, constraints) =>
            TabletDashboardLayout(constraints: constraints),
        desktop: (context, constraints) =>
            DesktopDashboardLayout(constraints: constraints),
      ),
    );
  }
}
