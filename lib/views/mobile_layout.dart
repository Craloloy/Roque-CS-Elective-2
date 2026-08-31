import 'package:flutter/material.dart';
import '../models/dashboard_data.dart';
import '../state/platform_settings.dart';
import 'components/activity_list.dart';
import 'components/course_card.dart';
import 'components/deadlines_card.dart';
import 'components/hero_banner.dart';
import 'components/metric_card.dart';

class MobileDashboardLayout extends StatelessWidget {
  final BoxConstraints constraints;
  const MobileDashboardLayout({super.key, required this.constraints});

  @override
  Widget build(BuildContext context) {
    final settings = PlatformSettings.of(context);
    final tabIndex = settings.selectedTabIndex;

    switch (tabIndex) {
      case 1:
        // Tab 1: Courses View
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enrolled Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '4 Active Courses • 18 Credits Enrolled',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DashboardData.enrolledCourses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return CourseCard(
                    course: DashboardData.enrolledCourses[index],
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );

      case 2:
        // Tab 2: Deadlines View
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Deadlines & Exams',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Midterm Week Tasks & Exam Countdown',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              DeadlinesCard(),
              SizedBox(height: 24),
            ],
          ),
        );

      case 3:
        // Tab 3: Timeline & Activity View
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Academic Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Submission History, Grades & Group Updates',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 16),
              ActivityList(),
              SizedBox(height: 24),
            ],
          ),
        );

      case 0:
      default:
        // Tab 0: Overview / Hub View
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Academic Banner
              const HeroBanner(),
              const SizedBox(height: 16),

              // 2. 2x2 Grid of Metric Cards
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: DashboardData.metrics.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  return MetricCard(metric: DashboardData.metrics[index]);
                },
              ),
              const SizedBox(height: 20),

              // 3. Actionable Deadlines Card
              const DeadlinesCard(),
              const SizedBox(height: 20),

              // 4. Enrolled Courses Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Enrolled Courses',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => settings.setSelectedTabIndex(1),
                    child: const Text('View All (4)'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 2, // Preview 2 courses
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return CourseCard(
                    course: DashboardData.enrolledCourses[index],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 5. Timeline Activity Feed
              const ActivityList(),
              const SizedBox(height: 24),
            ],
          ),
        );
    }
  }
}
