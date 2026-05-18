import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydro_habit/features/hydration/hydration_models.dart';

class HydrationStorage {
  static const String _keyCurrentWater = 'current_water_ml';
  static const String _keyDailyGoal = 'daily_goal_ml';
  static const String _keyLastTrackedDate = 'last_tracked_date';
  static const String _keyRemindersEnabled = 'reminders_enabled';
  static const String _keyReminderInterval = 'reminder_interval_mins';
  static const String _keyReminderStartTime = 'reminder_start_time';
  static const String _keyReminderEndTime = 'reminder_end_time';
  static const String _keyCurrentStreak = 'current_streak';
  static const String _keyLastGoalMetDate = 'last_goal_met_date';
  static const String _keyDailyHistory = 'daily_history';
  static const String _keyQuickAddSmall = 'quick_add_small';
  static const String _keyQuickAddLarge = 'quick_add_large';
  static const String _keyEveningCheckEnabled = 'evening_check_enabled';
  static const String _keyEveningCheckTime = 'evening_check_time';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationSound = 'notification_sound';


  final SharedPreferences _prefs;

  HydrationStorage(this._prefs);
  
  Future<void> reload() async {
    await _prefs.reload();
  }

  List<DailyHistory> getDailyHistory() {
    final String? historyJson = _prefs.getString(_keyDailyHistory);
    if (historyJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((item) => DailyHistory.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveDailyHistory(List<DailyHistory> history) async {
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyDailyHistory, encoded);
  }

  int getCurrentWater() {
    return _prefs.getInt(_keyCurrentWater) ?? 0;
  }

  Future<void> saveCurrentWater(int ml) async {
    await _prefs.setInt(_keyCurrentWater, ml);
  }

  int getDailyGoal() {
    return _prefs.getInt(_keyDailyGoal) ?? 2500;
  }

  Future<void> saveDailyGoal(int ml) async {
    await _prefs.setInt(_keyDailyGoal, ml);
  }

  DateTime getLastTrackedDate() {
    final timestamp = _prefs.getInt(_keyLastTrackedDate);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now(); // Default to now if not set
  }

  Future<void> saveLastTrackedDate(DateTime date) async {
    await _prefs.setInt(_keyLastTrackedDate, date.millisecondsSinceEpoch);
  }

  bool getRemindersEnabled() {
    return _prefs.getBool(_keyRemindersEnabled) ?? false;
  }

  Future<void> saveRemindersEnabled(bool enabled) async {
    await _prefs.setBool(_keyRemindersEnabled, enabled);
  }

  int getReminderIntervalMins() {
    return _prefs.getInt(_keyReminderInterval) ?? 90;
  }

  Future<void> saveReminderIntervalMins(int mins) async {
    await _prefs.setInt(_keyReminderInterval, mins);
  }

  String getReminderStartTime() {
    return _prefs.getString(_keyReminderStartTime) ?? '08:00';
  }

  Future<void> saveReminderStartTime(String time) async {
    await _prefs.setString(_keyReminderStartTime, time);
  }

  String getReminderEndTime() {
    return _prefs.getString(_keyReminderEndTime) ?? '22:00';
  }

  Future<void> saveReminderEndTime(String time) async {
    await _prefs.setString(_keyReminderEndTime, time);
  }

  int getCurrentStreak() {
    return _prefs.getInt(_keyCurrentStreak) ?? 0;
  }

  Future<void> saveCurrentStreak(int streak) async {
    await _prefs.setInt(_keyCurrentStreak, streak);
  }

  DateTime? getLastGoalMetDate() {
    final ms = _prefs.getInt(_keyLastGoalMetDate);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastGoalMetDate(DateTime date) async {
    await _prefs.setInt(_keyLastGoalMetDate, date.millisecondsSinceEpoch);
  }

  int getQuickAddSmall() {
    return _prefs.getInt(_keyQuickAddSmall) ?? 250;
  }

  Future<void> saveQuickAddSmall(int ml) async {
    await _prefs.setInt(_keyQuickAddSmall, ml);
  }

  int getQuickAddLarge() {
    return _prefs.getInt(_keyQuickAddLarge) ?? 500;
  }

  Future<void> saveQuickAddLarge(int ml) async {
    await _prefs.setInt(_keyQuickAddLarge, ml);
  }

  bool getEveningCheckEnabled() {
    return _prefs.getBool(_keyEveningCheckEnabled) ?? false;
  }

  Future<void> saveEveningCheckEnabled(bool enabled) async {
    await _prefs.setBool(_keyEveningCheckEnabled, enabled);
  }

  String getEveningCheckTime() {
    return _prefs.getString(_keyEveningCheckTime) ?? '21:00';
  }

  Future<void> saveEveningCheckTime(String time) async {
    await _prefs.setString(_keyEveningCheckTime, time);
  }
  
  ThemeMode getThemeMode() {
    final index = _prefs.getInt(_keyThemeMode) ?? 0; // Default to system
    return ThemeMode.values[index];
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setInt(_keyThemeMode, mode.index);
  }

  String getNotificationSound() {
    return _prefs.getString(_keyNotificationSound) ?? 'notification_sound';
  }

  Future<void> saveNotificationSound(String sound) async {
    await _prefs.setString(_keyNotificationSound, sound);
  }
}

