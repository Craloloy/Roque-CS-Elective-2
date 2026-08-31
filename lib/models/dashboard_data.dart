import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CourseItem {
  final String code;
  final String name;
  final String professor;
  final String schedule;
  final String room;
  final double progress; // 0.0 to 1.0
  final Color color;
  final IconData materialIcon;
  final IconData cupertinoIcon;

  const CourseItem({
    required this.code,
    required this.name,
    required this.professor,
    required this.schedule,
    required this.room,
    required this.progress,
    required this.color,
    required this.materialIcon,
    required this.cupertinoIcon,
  });
}

class DeadlineItem {
  final String id;
  final String title;
  final String courseCode;
  final String dueTime;
  final String urgency; // 'Urgent', 'Upcoming', 'In Review', 'Scheduled'
  final bool isCompleted;
  final Color badgeColor;

  const DeadlineItem({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.dueTime,
    required this.urgency,
    required this.isCompleted,
    required this.badgeColor,
  });
}

class ActivityItem {
  final String id;
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final bool isPositive;
  final String courseCode;
  final IconData materialIcon;
  final IconData cupertinoIcon;

  const ActivityItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.isPositive,
    required this.courseCode,
    required this.materialIcon,
    required this.cupertinoIcon,
  });
}

class MetricStat {
  final String title;
  final String value;
  final String sublabel;
  final String badgeText;
  final bool isPositive;
  final Color color;
  final IconData materialIcon;
  final IconData cupertinoIcon;
  final double progressValue;

  const MetricStat({
    required this.title,
    required this.value,
    required this.sublabel,
    required this.badgeText,
    required this.isPositive,
    required this.color,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.progressValue,
  });
}

class DayStudyData {
  final String day;
  final double hours;
  const DayStudyData(this.day, this.hours);
}

class DashboardData {
  static const List<MetricStat> metrics = [
    MetricStat(
      title: 'Current GPA',
      value: '3.88',
      sublabel: 'Target: 3.90',
      badgeText: "Dean's List",
      isPositive: true,
      color: Color(0xFF10B981),
      materialIcon: Icons.emoji_events_rounded,
      cupertinoIcon: CupertinoIcons.rosette,
      progressValue: 0.97,
    ),
    MetricStat(
      title: 'Study Focus',
      value: '42.5h',
      sublabel: 'Goal: 40h/wk',
      badgeText: '+6.2h vs wk 7',
      isPositive: true,
      color: Color(0xFF6366F1),
      materialIcon: Icons.bolt_rounded,
      cupertinoIcon: CupertinoIcons.flame_fill,
      progressValue: 0.85,
    ),
    MetricStat(
      title: 'Tasks Due',
      value: '4 Pending',
      sublabel: '2 Critical Today',
      badgeText: 'Midterms Wk',
      isPositive: false,
      color: Color(0xFFF59E0B),
      materialIcon: Icons.alarm_rounded,
      cupertinoIcon: CupertinoIcons.bell_fill,
      progressValue: 0.50,
    ),
    MetricStat(
      title: 'Term Credits',
      value: '18 / 21',
      sublabel: '6 Courses Enrolled',
      badgeText: '85.7% Done',
      isPositive: true,
      color: Color(0xFF0EA5E9),
      materialIcon: Icons.school_rounded,
      cupertinoIcon: CupertinoIcons.book_solid,
      progressValue: 0.857,
    ),
  ];

  static const List<DayStudyData> weeklyStudy = [
    DayStudyData('M', 5.5),
    DayStudyData('T', 6.0),
    DayStudyData('W', 7.5),
    DayStudyData('T', 4.0),
    DayStudyData('F', 8.0),
    DayStudyData('S', 6.5),
    DayStudyData('S', 5.0),
  ];

  static const List<CourseItem> enrolledCourses = [
    CourseItem(
      code: 'CS 402',
      name: 'Distributed Systems & Cloud Computing',
      professor: 'Dr. Santos',
      schedule: 'Mon / Wed • 10:00 AM - 11:30 AM',
      room: 'Lab 402',
      progress: 0.78,
      color: Color(0xFF6366F1),
      materialIcon: Icons.cloud_done_rounded,
      cupertinoIcon: CupertinoIcons.cloud_fill,
    ),
    CourseItem(
      code: 'CS 415',
      name: 'Mobile Application Development',
      professor: 'Prof. Cruz',
      schedule: 'Tue / Thu • 1:00 PM - 2:30 PM',
      room: 'Online Room A',
      progress: 0.90,
      color: Color(0xFF10B981),
      materialIcon: Icons.smartphone_rounded,
      cupertinoIcon: CupertinoIcons.device_phone_portrait,
    ),
    CourseItem(
      code: 'MATH 301',
      name: 'Advanced Linear Algebra',
      professor: 'Dr. Villanueva',
      schedule: 'Mon / Wed • 2:00 PM - 3:30 PM',
      room: 'Hall 205',
      progress: 0.65,
      color: Color(0xFFF59E0B),
      materialIcon: Icons.calculate_rounded,
      cupertinoIcon: CupertinoIcons.function,
    ),
    CourseItem(
      code: 'CS 320',
      name: 'Algorithm Design & Analysis',
      professor: 'Dr. Navarro',
      schedule: 'Fri • 9:00 AM - 12:00 PM',
      room: 'Lab 301',
      progress: 0.82,
      color: Color(0xFF8B5CF6),
      materialIcon: Icons.alt_route_rounded,
      cupertinoIcon: CupertinoIcons.arrow_branch,
    ),
  ];

  static const List<DeadlineItem> upcomingDeadlines = [
    DeadlineItem(
      id: '1',
      title: 'Lab #3: Distributed RPC System Client & Server',
      courseCode: 'CS 402',
      dueTime: 'Today, 11:59 PM',
      urgency: 'Urgent',
      isCompleted: false,
      badgeColor: Color(0xFFEF4444),
    ),
    DeadlineItem(
      id: '2',
      title: 'Midterm Quiz #2: Eigenvalues & Vector Kernels',
      courseCode: 'MATH 301',
      dueTime: 'Tomorrow, 9:00 AM',
      urgency: 'Upcoming',
      isCompleted: false,
      badgeColor: Color(0xFFF59E0B),
    ),
    DeadlineItem(
      id: '3',
      title: 'Responsive & Adaptive Flutter Dashboard UI Demo',
      courseCode: 'CS 415',
      dueTime: 'Friday, 5:00 PM',
      urgency: 'In Review',
      isCompleted: true,
      badgeColor: Color(0xFF10B981),
    ),
    DeadlineItem(
      id: '4',
      title: 'Graph Traversal & Dijkstra Implementation Report',
      courseCode: 'CS 320',
      dueTime: 'Monday, 11:59 PM',
      urgency: 'Scheduled',
      isCompleted: false,
      badgeColor: Color(0xFF6366F1),
    ),
  ];

  static const List<ActivityItem> recentActivities = [
    ActivityItem(
      id: '1',
      title: 'CS 402: Distributed Systems',
      subtitle: 'Lab 3: Remote Procedure Calls (RPC) submitted',
      time: '25 mins ago',
      status: '100 / 100',
      isPositive: true,
      courseCode: 'CS402',
      materialIcon: Icons.check_circle_outline_rounded,
      cupertinoIcon: CupertinoIcons.checkmark_seal_fill,
    ),
    ActivityItem(
      id: '2',
      title: 'MATH 301: Linear Algebra',
      subtitle: 'Quiz #2: Eigenvalues & Vector Spaces on Friday',
      time: '2 hours ago',
      status: 'Upcoming',
      isPositive: false,
      courseCode: 'MATH301',
      materialIcon: Icons.event_note_rounded,
      cupertinoIcon: CupertinoIcons.calendar,
    ),
    ActivityItem(
      id: '3',
      title: 'Campus Central Library',
      subtitle: 'Returned: "Modern Operating Systems 4th Ed."',
      time: 'Yesterday',
      status: 'Cleared',
      isPositive: true,
      courseCode: 'LIB',
      materialIcon: Icons.auto_stories_rounded,
      cupertinoIcon: CupertinoIcons.book_fill,
    ),
    ActivityItem(
      id: '4',
      title: 'CS 415: Mobile Development',
      subtitle: 'Adaptive & Responsive Project milestone reviewed',
      time: 'Yesterday',
      status: 'Passed',
      isPositive: true,
      courseCode: 'CS415',
      materialIcon: Icons.phone_android_rounded,
      cupertinoIcon: CupertinoIcons.device_phone_portrait,
    ),
    ActivityItem(
      id: '5',
      title: 'Algorithm Study Group',
      subtitle: 'Dynamic Programming & Graph notes shared by team',
      time: '2 days ago',
      status: '5 Files',
      isPositive: true,
      courseCode: 'STUDY',
      materialIcon: Icons.folder_shared_outlined,
      cupertinoIcon: CupertinoIcons.folder_badge_person_crop,
    ),
  ];
}
