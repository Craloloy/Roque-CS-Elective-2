import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../state/platform_settings.dart';
import '../../widgets/adaptive/adaptive_dialog.dart';
import '../../widgets/adaptive/adaptive_icon.dart';

class SidebarNav extends StatelessWidget {
  final bool isDrawer;
  const SidebarNav({super.key, this.isDrawer = false});

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettings.of(context);
    final isCupertino = settings.isCupertinoActive(context);
    final isDark = settings.isDarkMode;

    final bgColor = isDark
        ? const Color(0xFF181820)
        : (isCupertino ? CupertinoColors.systemBackground : Colors.white);
    final borderColor = isDark
        ? const Color(0xFF282834)
        : (isCupertino ? CupertinoColors.systemGrey5 : const Color(0xFFE2E8F0));

    final items = [
      (
        'Study Hub',
        Icons.dashboard_rounded,
        CupertinoIcons.square_grid_2x2,
      ),
      (
        'My Courses',
        Icons.menu_book_rounded,
        CupertinoIcons.book,
      ),
      (
        'Schedule & Exams',
        Icons.calendar_month_rounded,
        CupertinoIcons.calendar,
      ),
      (
        'Grades & Analytics',
        Icons.insights_rounded,
        CupertinoIcons.chart_bar_alt_fill,
      ),
      (
        'Campus Library',
        Icons.account_balance_rounded,
        CupertinoIcons.building_2_fill,
      ),
    ];

    return Container(
      width: isDrawer ? null : 240,
      decoration: BoxDecoration(
        color: bgColor,
        border: isDrawer
            ? null
            : Border(right: BorderSide(color: borderColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header / Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: AdaptiveIcon(
                    materialIcon: Icons.auto_stories_rounded,
                    cupertinoIcon: CupertinoIcons.sparkles,
                    color: const Color(0xFF6366F1),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LUMINA',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Student Study Hub',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Nav Items
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = settings.selectedSection == item.$1 ||
                    (settings.selectedSection == 'Dashboard' &&
                        item.$1 == 'Study Hub');

                final activeColor = const Color(0xFF6366F1);
                final selectedBg = activeColor.withValues(alpha: 0.12);

                return InkWell(
                  onTap: () {
                    settings.setSelectedSection(item.$1);
                    if (isDrawer) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(
                              color: activeColor.withValues(alpha: 0.3), width: 1)
                          : null,
                    ),
                    child: Row(
                      children: [
                        AdaptiveIcon(
                          materialIcon: item.$2,
                          cupertinoIcon: item.$3,
                          size: 20,
                          color: isSelected
                              ? activeColor
                              : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? activeColor
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF334155)),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer / Student Profile & Logout
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFF6366F1),
                  child: const Text(
                    'CR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carl Roque',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'BS Computer Science',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Logout',
                  icon: const AdaptiveIcon(
                    materialIcon: Icons.logout_rounded,
                    cupertinoIcon: CupertinoIcons.square_arrow_right,
                    size: 20,
                  ),
                  onPressed: () async {
                    final confirmed = await AdaptiveDialog.showConfirmation(
                      context: context,
                      title: 'Sign Out',
                      message: 'Are you sure you want to exit your study hub?',
                      confirmText: 'Sign Out',
                      isDestructive: true,
                    );
                    if (confirmed == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signed out of Lumina (Demo)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
