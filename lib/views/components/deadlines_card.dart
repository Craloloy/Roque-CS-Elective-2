import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../state/platform_settings.dart';
import '../../widgets/adaptive/adaptive_icon.dart';

class DeadlinesCard extends StatefulWidget {
  const DeadlinesCard({super.key});

  @override
  State<DeadlinesCard> createState() => _DeadlinesCardState();
}

class _DeadlinesCardState extends State<DeadlinesCard> {
  late List<bool> _completedStates;

  @override
  void initState() {
    super.initState();
    _completedStates =
        DashboardData.upcomingDeadlines.map((d) => d.isCompleted).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = PlatformSettings.of(context).isDarkMode;

    final cardBg = isDark ? const Color(0xFF181820) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF282834) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      AdaptiveIcon(
                        materialIcon: Icons.alarm_rounded,
                        cupertinoIcon: CupertinoIcons.bell_fill,
                        size: 18,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      const Flexible(
                        child: Text(
                          'Actionable Deadlines',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_completedStates.where((c) => !c).length} Pending',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Deadlines List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DashboardData.upcomingDeadlines.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final deadline = DashboardData.upcomingDeadlines[index];
              final isDone = _completedStates[index];

              return InkWell(
                onTap: () {
                  setState(() {
                    _completedStates[index] = !_completedStates[index];
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      // Checkbox
                      Icon(
                        isDone
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isDone
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white38 : Colors.black26),
                      ),
                      const SizedBox(width: 8),

                      // Course Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: deadline.badgeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          deadline.courseCode,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: deadline.badgeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Title & Due Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deadline.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isDone
                                    ? (isDark ? Colors.white38 : Colors.black38)
                                    : (isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A)),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              deadline.dueTime,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),

                      // Urgency Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : deadline.badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDone ? 'Done' : deadline.urgency,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isDone
                                ? const Color(0xFF10B981)
                                : deadline.badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
