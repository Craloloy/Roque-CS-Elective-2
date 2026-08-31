import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/main.dart';
import 'package:flutter_application_1/state/platform_settings.dart';
import 'package:flutter_application_1/views/components/course_card.dart';
import 'package:flutter_application_1/views/components/deadlines_card.dart';
import 'package:flutter_application_1/views/components/hero_banner.dart';
import 'package:flutter_application_1/views/components/metric_card.dart';
import 'package:flutter_application_1/views/components/sidebar_nav.dart';
import 'package:flutter_application_1/views/desktop_layout.dart';
import 'package:flutter_application_1/views/mobile_layout.dart';
import 'package:flutter_application_1/views/tablet_layout.dart';
import 'package:flutter_application_1/widgets/adaptive/adaptive_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Responsive Layout Breakpoint Tests', () {
    testWidgets('Renders Mobile Layout with Bottom Navigation on small screen (< 600px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ResponsiveAdaptiveApp());
      await tester.pumpAndSettle();

      expect(find.byType(MobileDashboardLayout), findsOneWidget);
      expect(find.byType(DesktopDashboardLayout), findsNothing);
      expect(find.byType(AdaptiveBottomNav), findsOneWidget);
      expect(find.text('Lumina Study Hub'), findsOneWidget);
      expect(find.byType(HeroBanner), findsOneWidget);
      expect(find.byType(MetricCard), findsNWidgets(4));
    });

    testWidgets('Switches tabs via Bottom Navigation on mobile',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ResponsiveAdaptiveApp());
      await tester.pumpAndSettle();

      // Tap Courses tab
      final coursesTab = find.text('Courses');
      expect(coursesTab, findsOneWidget);
      await tester.tap(coursesTab);
      await tester.pumpAndSettle();

      expect(find.text('Enrolled Courses'), findsOneWidget);

      // Tap Deadlines tab
      final deadlinesTab = find.text('Deadlines');
      expect(deadlinesTab, findsOneWidget);
      await tester.tap(deadlinesTab);
      await tester.pumpAndSettle();

      expect(find.text('Deadlines & Exams'), findsOneWidget);
    });

    testWidgets('Renders Tablet Layout on medium screen (768px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(768, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ResponsiveAdaptiveApp());
      await tester.pumpAndSettle();

      expect(find.byType(TabletDashboardLayout), findsOneWidget);
      expect(find.byType(HeroBanner), findsOneWidget);
      expect(find.byType(MetricCard), findsNWidgets(4));
      expect(find.byType(DeadlinesCard), findsOneWidget);
      expect(find.byType(CourseCard), findsWidgets);
    });

    testWidgets('Renders Desktop Layout with Sidebar on large screen (1280px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ResponsiveAdaptiveApp());
      await tester.pumpAndSettle();

      expect(find.byType(DesktopDashboardLayout), findsOneWidget);
      expect(find.byType(SidebarNav), findsOneWidget);
      expect(find.byType(HeroBanner), findsOneWidget);
      expect(find.byType(MetricCard), findsNWidgets(4));
      expect(find.byType(DeadlinesCard), findsOneWidget);
      expect(find.byType(CourseCard), findsWidgets);
    });
  });

  group('Automatic Platform Adaptation Tests', () {
    testWidgets('Automatically renders Cupertino widgets when running on iOS',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const ResponsiveAdaptiveApp());
        await tester.pumpAndSettle();

        expect(find.byType(CupertinoPageScaffold), findsOneWidget);
        expect(find.byType(CupertinoButton), findsWidgets);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Automatically renders Material widgets when running on Android',
        (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(const ResponsiveAdaptiveApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(FilledButton), findsWidgets);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Toggles Dark Mode via AppBar Action',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(const ResponsiveAdaptiveApp());
      await tester.pumpAndSettle();

      final themeButton = find.byTooltip('Toggle Theme');
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      final settings = PlatformSettings.of(
          tester.element(find.byType(DesktopDashboardLayout)));
      expect(settings.isDarkMode, isTrue);
    });
  });
}
