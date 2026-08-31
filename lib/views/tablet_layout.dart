import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import 'components/activity_list.dart';
import 'components/course_card.dart';
import 'components/deadlines_card.dart';
import 'components/hero_banner.dart';
import 'components/metric_card.dart';

class TabletDashboardLayout extends StatelessWidget {
  final BoxConstraints constraints;
  const TabletDashboardLayout({super.key, required this.constraints});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Academic Banner
          const HeroBanner(),
          const SizedBox(height: 20),

          // 2. 4 Metric Cards Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: DashboardData.metrics.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: constraints.maxWidth > 850 ? 4 : 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: constraints.maxWidth > 850 ? 1.35 : 1.45,
            ),
            itemBuilder: (context, index) {
              return MetricCard(metric: DashboardData.metrics[index]);
            },
          ),
          const SizedBox(height: 24),

          // 3. Active Courses Section
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
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
          const SizedBox(height: 24),

          // 4. Deadlines Card
          const DeadlinesCard(),
          const SizedBox(height: 20),

          // 5. Activity List
          const ActivityList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
