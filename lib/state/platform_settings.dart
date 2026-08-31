import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PlatformSettings extends ChangeNotifier {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  double _volumeLevel = 0.75;
  String _selectedSection = 'Study Hub';
  int _selectedTabIndex = 0;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  double get volumeLevel => _volumeLevel;
  String get selectedSection => _selectedSection;
  int get selectedTabIndex => _selectedTabIndex;

  void toggleDarkMode(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }

  void setNotifications(bool value) {
    _notificationsEnabled = value;
    notifyListeners();
  }

  void setVolumeLevel(double value) {
    _volumeLevel = value;
    notifyListeners();
  }

  void setSelectedSection(String section) {
    if (_selectedSection != section) {
      _selectedSection = section;
      notifyListeners();
    }
  }

  void setSelectedTabIndex(int index) {
    if (_selectedTabIndex != index) {
      _selectedTabIndex = index;
      notifyListeners();
    }
  }

  /// Pure automatic platform detection:
  /// Returns true if running on iOS or macOS (Cupertino style)
  bool isCupertinoActive(BuildContext context) {
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  /// Returns true if running in a web browser
  bool get isWeb => kIsWeb;

  static PlatformSettings of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<PlatformSettingsScope>();
    if (provider == null) {
      throw FlutterError('PlatformSettingsScope not found in widget tree');
    }
    return provider.notifier!;
  }
}

class PlatformSettingsScope extends InheritedNotifier<PlatformSettings> {
  const PlatformSettingsScope({
    super.key,
    required PlatformSettings super.notifier,
    required super.child,
  });
}
