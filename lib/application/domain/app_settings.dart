import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/presentation/presentation.dart';
import 'assist_level.dart';

/// User preferences (not patient data). Stored locally on the device.
class AppSettings extends AppViewModel {
  AppSettings._();
  static final i = AppSettings._();

  static const _soundKey = 'SETTING_SOUND';
  static const _hapticsKey = 'SETTING_HAPTICS';
  static const _assistKey = 'SETTING_ASSIST';
  static const _goalKey = 'SETTING_DAILY_GOAL';
  static const _welcomeKey = 'WELCOME_SEEN';
  static const _themeKey = 'SETTING_THEME';

  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  AssistLevel _assistLevel = AssistLevel.standard;
  int _dailyGoal = 2;
  bool _welcomeSeen = false;
  ThemeMode _themeMode = ThemeMode.system;

  bool get soundEnabled => _soundEnabled;
  bool get hapticsEnabled => _hapticsEnabled;
  AssistLevel get assistLevel => _assistLevel;

  /// Finished sessions per day the patient aims for (1 to 5).
  int get dailyGoal => _dailyGoal;

  /// Whether the first-run welcome notice has been acknowledged.
  bool get welcomeSeen => _welcomeSeen;
  ThemeMode get themeMode => _themeMode;

  String get themeLabel => switch (_themeMode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> initialise() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _soundEnabled = sp.getBool(_soundKey) ?? true;
      _hapticsEnabled = sp.getBool(_hapticsKey) ?? true;
      final assistIndex = sp.getInt(_assistKey) ?? 0;
      _welcomeSeen = sp.getBool(_welcomeKey) ?? false;
      _dailyGoal = (sp.getInt(_goalKey) ?? 2).clamp(1, 5).toInt();
      _assistLevel = AssistLevel.values[
          assistIndex.clamp(0, AssistLevel.values.length - 1).toInt()];
      final themeIndex = sp.getInt(_themeKey) ?? 0;
      _themeMode = ThemeMode.values[
          themeIndex.clamp(0, ThemeMode.values.length - 1).toInt()];
      setState();
    } catch (_) {
      // Fall back to defaults if storage is unavailable.
    }
  }

  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    setState();
    await _save(_soundKey, _soundEnabled);
  }

  Future<void> toggleHaptics() async {
    _hapticsEnabled = !_hapticsEnabled;
    setState();
    await _save(_hapticsKey, _hapticsEnabled);
  }

  Future<void> cycleTheme() async {
    _themeMode =
        ThemeMode.values[(_themeMode.index + 1) % ThemeMode.values.length];
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_themeKey, _themeMode.index);
    } catch (_) {}
  }

  Future<void> markWelcomeSeen() async {
    _welcomeSeen = true;
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_welcomeKey, true);
    } catch (_) {}
  }

  Future<void> cycleDailyGoal() async {
    _dailyGoal = _dailyGoal % 5 + 1;
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_goalKey, _dailyGoal);
    } catch (_) {}
  }

  Future<void> cycleAssist() async {
    _assistLevel = _assistLevel.next;
    setState();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_assistKey, _assistLevel.index);
    } catch (_) {}
  }

  Future<void> _save(String key, bool value) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(key, value);
    } catch (_) {}
  }
}
