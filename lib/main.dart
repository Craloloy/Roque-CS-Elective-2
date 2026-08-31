import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'state/platform_settings.dart';
import 'views/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ResponsiveAdaptiveApp());
}

class ResponsiveAdaptiveApp extends StatefulWidget {
  const ResponsiveAdaptiveApp({super.key});

  @override
  State<ResponsiveAdaptiveApp> createState() => _ResponsiveAdaptiveAppState();
}

class _ResponsiveAdaptiveAppState extends State<ResponsiveAdaptiveApp> {
  late final PlatformSettings _platformSettings;

  @override
  void initState() {
    super.initState();
    _platformSettings = PlatformSettings();
  }

  @override
  void dispose() {
    _platformSettings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformSettingsScope(
      notifier: _platformSettings,
      child: ListenableBuilder(
        listenable: _platformSettings,
        builder: (context, _) {
          final isCupertino =
              _platformSettings.isCupertinoActive(context);
          final isDark = _platformSettings.isDarkMode;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lumina Study Hub',
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              platform:
                  isCupertino ? TargetPlatform.iOS : TargetPlatform.android,
              cupertinoOverrideTheme: CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: const Color(0xFF6366F1),
                scaffoldBackgroundColor: const Color(0xFFF8FAFC),
                barBackgroundColor: Colors.white.withValues(alpha: 0.95),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: isCupertino
                  ? const Color(0xFFF8FAFC)
                  : const Color(0xFFF8FAFC),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0F172A),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              dividerColor: const Color(0xFFE2E8F0),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              platform:
                  isCupertino ? TargetPlatform.iOS : TargetPlatform.android,
              cupertinoOverrideTheme: CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: const Color(0xFF818CF8),
                scaffoldBackgroundColor: const Color(0xFF0F172A),
                barBackgroundColor:
                    const Color(0xFF1E293B).withValues(alpha: 0.95),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0B0F19),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF181820),
                foregroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFF282834)),
                ),
              ),
              dividerColor: const Color(0xFF282834),
            ),
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
