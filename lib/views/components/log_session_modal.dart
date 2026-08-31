import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../models/dashboard_data.dart';
import '../../state/platform_settings.dart';
import '../../widgets/adaptive/adaptive_button.dart';
import '../../widgets/adaptive/adaptive_slider.dart';

class LogSessionModal extends StatefulWidget {
  const LogSessionModal({super.key});

  static void show(BuildContext context) {
    final isCupertino =
        PlatformSettings.of(context).isCupertinoActive(context);
    final isDark = PlatformSettings.of(context).isDarkMode;

    if (isCupertino) {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 480,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const SafeArea(top: false, child: LogSessionModal()),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF181820) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: const SafeArea(child: LogSessionModal()),
        ),
      );
    }
  }

  @override
  State<LogSessionModal> createState() => _LogSessionModalState();
}

class _LogSessionModalState extends State<LogSessionModal> {
  double _hours = 2.0;
  String _selectedCourse = DashboardData.enrolledCourses.first.code;

  @override
  Widget build(BuildContext context) {
    final isDark = PlatformSettings.of(context).isDarkMode;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Study Session',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Course Picker Chips
          Text(
            'SELECT COURSE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DashboardData.enrolledCourses.map((c) {
              final isSelected = _selectedCourse == c.code;
              return ChoiceChip(
                label: Text(c.code),
                selected: isSelected,
                selectedColor: c.color.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? c.color : (isDark ? Colors.white70 : Colors.black87),
                ),
                onSelected: (val) {
                  if (val) setState(() => _selectedCourse = c.code);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Duration Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'STUDY DURATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                ),
              ),
              Text(
                '${_hours.toStringAsFixed(1)} Hours',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AdaptiveSlider(
            value: _hours,
            min: 0.5,
            max: 8.0,
            divisions: 15,
            activeColor: const Color(0xFF6366F1),
            onChanged: (v) => setState(() => _hours = v),
          ),
          const SizedBox(height: 24),

          // Submit button
          AdaptiveButton.filled(
            color: const Color(0xFF6366F1),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Logged ${_hours.toStringAsFixed(1)} hours for $_selectedCourse!',
                  ),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save Study Session'),
          ),
        ],
      ),
    );
  }
}
