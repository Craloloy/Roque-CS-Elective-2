import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../state/platform_settings.dart';
import '../../widgets/adaptive/adaptive_icon.dart';

class MetricCard extends StatefulWidget {
  final MetricStat metric;
  const MetricCard({super.key, required this.metric});

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettings.of(context);
    final isCupertino = settings.isCupertinoActive(context);
    final isDark = settings.isDarkMode;

    final bgColor = isDark
        ? const Color(0xFF1E2230)
        : (isCupertino ? CupertinoColors.systemBackground : Colors.white);
    final borderColor = _isHovered
        ? widget.metric.color.withValues(alpha: 0.5)
        : (isDark
            ? const Color(0xFF2E3547)
            : (isCupertino
                ? CupertinoColors.systemGrey5
                : const Color(0xFFE2E8F0)));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform:
            Matrix4.translationValues(0.0, _isHovered ? -2.5 : 0.0, 0.0),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: _isHovered ? 8 : 4,
              offset: Offset(0, _isHovered ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Icon + Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.metric.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AdaptiveIcon(
                    materialIcon: widget.metric.materialIcon,
                    cupertinoIcon: widget.metric.cupertinoIcon,
                    color: widget.metric.color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: widget.metric.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: widget.metric.color.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      widget.metric.badgeText,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: widget.metric.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Value & Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.metric.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.metric.title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),

                // Mini Visual Indicator (Progress bar)
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: widget.metric.progressValue,
                    minHeight: 3.5,
                    backgroundColor: isDark
                        ? const Color(0xFF282F42)
                        : const Color(0xFFF1F5F9),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.metric.color),
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
