import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workout_habit/features/workout/workout_models.dart';

class WorkoutStorage {
  // New Workout-oriented keys
  static const String _keyCurrentWorkoutUnits = 'current_workout_units';
  static const String _keyDailyWorkoutTargetUnits =
      'daily_workout_target_units';
  static const String _keyPreferredExercise = 'preferred_exercise';
  static const String _keySelectedExercise = 'selected_exercise';
  static const String _keyQuickAddSmallUnits = 'quick_add_small_units';
  static const String _keyQuickAddLargeUnits = 'quick_add_large_units';
  static const String _keyWorkoutHistory = 'workout_history';
  static const String _keyStreak = 'streak';
  static const String _keyLastLoggedDate = 'last_logged_date';
  static const String _keyTodayLogs = 'today_logs';

  // Settings & others (retaining some keys for seamless integration where needed)
  static const String _keyRemindersEnabled = 'reminders_enabled';
  static const String _keyReminderInterval = 'reminder_interval_mins';
  static const String _keyReminderStartTime = 'reminder_start_time';
  static const String _keyReminderEndTime = 'reminder_end_time';
  static const String _keyLastGoalMetDate = 'last_goal_met_date';
  static const String _keyEveningCheckEnabled = 'evening_check_enabled';
  static const String _keyEveningCheckTime = 'evening_check_time';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationSound = 'notification_sound';

  final SharedPreferences _prefs;

  WorkoutStorage(this._prefs);

  Future<void> reload() async {
    await _prefs.reload();
  }

  // Idempotent initialization
  Future<void> initializeForWorkoutHabit() async {
    await clearLegacyKeys();

    if (!_prefs.containsKey(_keyCurrentWorkoutUnits)) {
      await _prefs.setInt(_keyCurrentWorkoutUnits, 0);
    }
    if (!_prefs.containsKey(_keyDailyWorkoutTargetUnits)) {
      await _prefs.setInt(_keyDailyWorkoutTargetUnits, 50);
    }
    if (!_prefs.containsKey(_keyPreferredExercise)) {
      await _prefs.setString(_keyPreferredExercise, 'push_ups');
    }
    if (!_prefs.containsKey(_keySelectedExercise)) {
      await _prefs.setString(_keySelectedExercise, 'push_ups');
    }
    if (!_prefs.containsKey(_keyQuickAddSmallUnits)) {
      await _prefs.setInt(_keyQuickAddSmallUnits, 5);
    }
    if (!_prefs.containsKey(_keyQuickAddLargeUnits)) {
      await _prefs.setInt(_keyQuickAddLargeUnits, 10);
    }
    if (!_prefs.containsKey(_keyStreak)) {
      await _prefs.setInt(_keyStreak, 0);
    }
    if (!_prefs.containsKey(_keyTodayLogs)) {
      await _prefs.setString(_keyTodayLogs, '[]');
    }
  }

  // Safely wipe old Hydro Habit keys
  Future<void> clearLegacyKeys() async {
    final Set<String> legacyKeys = {
      'current_water_ml',
      'daily_goal_ml',
      'last_tracked_date',
      'current_streak',
      'daily_history',
      'quick_add_small',
      'quick_add_large',
    };

    for (final String key in legacyKeys) {
      if (_prefs.containsKey(key)) {
        await _prefs.remove(key);
      }
    }
  }

  // --- NEW WORKOUT ORIENTED API ---

  int getCurrentWorkoutUnits() {
    return _prefs.getInt(_keyCurrentWorkoutUnits) ?? 0;
  }

  Future<void> saveCurrentWorkoutUnits(int units) async {
    if (units < 0) units = 0;
    await _prefs.setInt(_keyCurrentWorkoutUnits, units);
  }

  int getDailyWorkoutTargetUnits() {
    return _prefs.getInt(_keyDailyWorkoutTargetUnits) ?? 50;
  }

  Future<void> saveDailyWorkoutTargetUnits(int units) async {
    if (units < 0) units = 0;
    await _prefs.setInt(_keyDailyWorkoutTargetUnits, units);
  }

  DateTime getLastLoggedDate() {
    final timestamp = _prefs.getInt(_keyLastLoggedDate);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return DateTime.now();
  }

  Future<void> saveLastLoggedDate(DateTime date) async {
    await _prefs.setInt(_keyLastLoggedDate, date.millisecondsSinceEpoch);
  }

  int getStreak() {
    return _prefs.getInt(_keyStreak) ?? 0;
  }

  Future<void> saveStreak(int streak) async {
    if (streak < 0) streak = 0;
    await _prefs.setInt(_keyStreak, streak);
  }

  List<DailyWorkoutHistory> getWorkoutHistory() {
    final String? historyJson = _prefs.getString(_keyWorkoutHistory);
    if (historyJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.map((item) => DailyWorkoutHistory.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveWorkoutHistory(List<DailyWorkoutHistory> history) async {
    final String encoded = jsonEncode(history.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyWorkoutHistory, encoded);
  }

  int getQuickAddSmallUnits() {
    return _prefs.getInt(_keyQuickAddSmallUnits) ?? 5;
  }

  Future<void> saveQuickAddSmallUnits(int units) async {
    if (units < 0) units = 0;
    await _prefs.setInt(_keyQuickAddSmallUnits, units);
  }

  int getQuickAddLargeUnits() {
    return _prefs.getInt(_keyQuickAddLargeUnits) ?? 10;
  }

  Future<void> saveQuickAddLargeUnits(int units) async {
    if (units < 0) units = 0;
    await _prefs.setInt(_keyQuickAddLargeUnits, units);
  }

  ExerciseType getPreferredExercise() {
    final id = _prefs.getString(_keyPreferredExercise) ?? 'push_ups';
    return ExerciseType.fromId(id);
  }

  Future<void> savePreferredExercise(ExerciseType exercise) async {
    await _prefs.setString(_keyPreferredExercise, exercise.id);
  }

  ExerciseType getSelectedExercise() {
    final id = _prefs.getString(_keySelectedExercise) ?? 'push_ups';
    return ExerciseType.fromId(id);
  }

  Future<void> saveSelectedExercise(ExerciseType exercise) async {
    await _prefs.setString(_keySelectedExercise, exercise.id);
  }

  List<ExerciseLog> getTodayLogs() {
    final String? logsJson = _prefs.getString(_keyTodayLogs);
    if (logsJson == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(logsJson);
      return decoded.map((item) => ExerciseLog.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveTodayLogs(List<ExerciseLog> logs) async {
    final String encoded = jsonEncode(logs.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyTodayLogs, encoded);
  }

  // --- OTHER PERSISTENT SETTINGS ---

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

  DateTime? getLastGoalMetDate() {
    final ms = _prefs.getInt(_keyLastGoalMetDate);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveLastGoalMetDate(DateTime date) async {
    await _prefs.setInt(_keyLastGoalMetDate, date.millisecondsSinceEpoch);
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
    final index = _prefs.getInt(_keyThemeMode) ?? 0;
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
