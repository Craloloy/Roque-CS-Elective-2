import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../state/platform_settings.dart';
import '../../widgets/adaptive/adaptive_icon.dart';

class CourseCard extends StatefulWidget {
  final CourseItem course;
  const CourseCard({super.key, required this.course});

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = PlatformSettings.of(context).isDarkMode;

    final cardBg = isDark ? const Color(0xFF181820) : Colors.white;
    final borderColor = _isHovered
        ? widget.course.color.withValues(alpha: 0.6)
        : (isDark ? const Color(0xFF282834) : const Color(0xFFE2E8F0));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: _isHovered ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? widget.course.color.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: _isHovered ? 12 : 6,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Course Code Pill + Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.course.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.course.code,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: widget.course.color,
                    ),
                  ),
                ),
                AdaptiveIcon(
                  materialIcon: widget.course.materialIcon,
                  cupertinoIcon: widget.course.cupertinoIcon,
                  size: 20,
                  color: widget.course.color,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Course Name
            Text(
              widget.course.name,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Professor & Schedule
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 14,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.course.professor} • ${widget.course.room}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Syllabus Coverage',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      '${(widget.course.progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.course.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: widget.course.progress,
                    minHeight: 5,
                    backgroundColor:
                        widget.course.color.withValues(alpha: 0.15),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.course.color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
