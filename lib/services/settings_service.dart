import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  static const String _settingsBoxName = 'settingsBox';
  static const String _themeKey = 'theme_mode';
  static const String _securityEnabledKey = 'security_enabled';
  static const String _fabPositionKey = 'fab_position';

  late Box<String> _settingsBox;

  Future<void> initialize() async {
    _settingsBox = await Hive.openBox<String>(_settingsBoxName);
  }

  // Theme Management
  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsBox.put(_themeKey, mode.toString());
  }

  ThemeMode getThemeMode() {
    final stored = _settingsBox.get(_themeKey, defaultValue: 'ThemeMode.light');
    if (stored == 'ThemeMode.dark') {
      return ThemeMode.dark;
    }
    return ThemeMode.light;
  }

  // Security Management
  Future<void> setSecurityEnabled(bool enabled) async {
    await _settingsBox.put(_securityEnabledKey, enabled.toString());
  }

  bool isSecurityEnabled() {
    final stored = _settingsBox.get(_securityEnabledKey, defaultValue: 'true');
    return stored == 'true';
  }

  // FAB Position Management
  Future<void> setFabPosition(String position) async {
    await _settingsBox.put(_fabPositionKey, position);
  }

  String getFabPosition() {
    final stored = _settingsBox.get(_fabPositionKey);
    if (stored == null || stored.isEmpty) {
      return 'bottom-right';
    }
    return stored;
  }

  FloatingActionButtonLocation getFabLocation() {
    final position = getFabPosition();
    switch (position) {
      case 'bottom-left':
        return FloatingActionButtonLocation.startFloat;
      case 'center-bottom':
        return FloatingActionButtonLocation.centerFloat;
      default:
        return FloatingActionButtonLocation.endFloat;
    }
  }
}

