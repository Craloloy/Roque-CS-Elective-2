import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import 'components/activity_list.dart';
import 'components/course_card.dart';
import 'components/deadlines_card.dart';
import 'components/hero_banner.dart';
import 'components/metric_card.dart';
import 'components/sidebar_nav.dart';

class DesktopDashboardLayout extends StatelessWidget {
  final BoxConstraints constraints;
  const DesktopDashboardLayout({super.key, required this.constraints});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Column 1: Left Navigation Sidebar
        const SidebarNav(isDrawer: false),

        // Column 2: Main Academic Dashboard Content Area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Hero Academic Banner
                const HeroBanner(),
                const SizedBox(height: 20),

                // 2. 4 Metric Cards Row
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: DashboardData.metrics.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (context, index) {
                    return MetricCard(metric: DashboardData.metrics[index]);
                  },
                ),
                const SizedBox(height: 24),

                // 3. Split Section: Courses & Deadlines
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Enrolled Courses Grid
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Active Enrolled Courses',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: DashboardData.enrolledCourses.length,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.35,
                            ),
                            itemBuilder: (context, index) {
                              return CourseCard(
                                course: DashboardData.enrolledCourses[index],
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const ActivityList(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Deadlines & Priority Tasks
                    const Expanded(
                      flex: 2,
                      child: DeadlinesCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
