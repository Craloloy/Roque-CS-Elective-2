import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';

class AdaptiveBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AdaptiveBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettings.of(context);
    final isCupertino = settings.isCupertinoActive(context);
    final isDark = settings.isDarkMode;

    if (isCupertino) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: isDark
            ? const Color(0xFF1E1B2E).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        activeColor: const Color(0xFF6366F1),
        inactiveColor: isDark ? Colors.white38 : const Color(0xFF94A3B8),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
            label: 'Hub',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.book),
            activeIcon: Icon(CupertinoIcons.book_fill),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.bell),
            activeIcon: Icon(CupertinoIcons.bell_fill),
            label: 'Deadlines',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.calendar_today),
            activeIcon: Icon(CupertinoIcons.calendar),
            label: 'Activity',
          ),
        ],
      );
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      backgroundColor: isDark ? const Color(0xFF181820) : Colors.white,
      indicatorColor: const Color(0xFF6366F1).withValues(alpha: 0.18),
      elevation: 3,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded, color: Color(0xFF6366F1)),
          label: 'Hub',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded, color: Color(0xFF6366F1)),
          label: 'Courses',
        ),
        NavigationDestination(
          icon: Icon(Icons.alarm_outlined),
          selectedIcon: Icon(Icons.alarm_rounded, color: Color(0xFF6366F1)),
          label: 'Deadlines',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_edu_outlined),
          selectedIcon:
              Icon(Icons.history_edu_rounded, color: Color(0xFF6366F1)),
          label: 'Activity',
        ),
      ],
    );
  }
}
