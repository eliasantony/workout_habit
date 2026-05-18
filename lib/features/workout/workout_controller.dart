import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:workout_habit/features/workout/workout_models.dart';
import 'package:workout_habit/features/workout/workout_storage.dart';
import 'package:workout_habit/services/notification_service.dart';

class WorkoutController extends ChangeNotifier {
  final WorkoutStorage _storage;
  final NotificationService _notificationService;
  final Completer<void> _initCompleter = Completer<void>();

  late WorkoutState _state;

  WorkoutController(this._storage, this._notificationService) {
    _init();
  }

  Future<void> get ready => _initCompleter.future;

  WorkoutState get state => _state;

  Future<void> _init() async {
    await _storage.initializeForWorkoutHabit();

    final currentWater = _storage.getCurrentWorkoutUnits();
    final dailyGoal = _storage.getDailyWorkoutTargetUnits();
    final lastTrackedDate = _storage.getLastLoggedDate();

    final remindersEnabled = _storage.getRemindersEnabled();
    final reminderIntervalMins = _storage.getReminderIntervalMins();
    final reminderStartTime = _storage.getReminderStartTime();
    final reminderEndTime = _storage.getReminderEndTime();

    final currentStreak = _storage.getStreak();
    final lastGoalMetDate = _storage.getLastGoalMetDate();
    final history = _storage.getWorkoutHistory();
    final todayLogs = _storage.getTodayLogs();

    final quickAddSmall = _storage.getQuickAddSmallUnits();
    final quickAddLarge = _storage.getQuickAddLargeUnits();

    final eveningCheckEnabled = _storage.getEveningCheckEnabled();
    final eveningCheckTime = _storage.getEveningCheckTime();
    final themeMode = _storage.getThemeMode();
    final notificationSound = _storage.getNotificationSound();

    final preferredExercise = _storage.getPreferredExercise();
    final selectedExercise = _storage.getSelectedExercise();

    _state = WorkoutState(
      currentWaterMl: currentWater,
      dailyGoalMl: dailyGoal,
      lastTrackedDate: lastTrackedDate,
      history: history,
      todayLogs: todayLogs,
      currentStreak: currentStreak,
      lastGoalMetDate: lastGoalMetDate,
      remindersEnabled: remindersEnabled,
      reminderIntervalMins: reminderIntervalMins,
      reminderStartTime: reminderStartTime,
      reminderEndTime: reminderEndTime,
      eveningCheckEnabled: eveningCheckEnabled,
      eveningCheckTime: eveningCheckTime,
      quickAddSmall: quickAddSmall,
      quickAddLarge: quickAddLarge,
      themeMode: themeMode,
      notificationSound: notificationSound,
      preferredExercise: preferredExercise,
      selectedExercise: selectedExercise,
    );

    await _checkNewDay();

    // Always schedule reminders on init to ensure they are active
    _notificationService.scheduleReminders(_state);

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  Future<void> _notifyAndSchedule({bool forceReschedule = false}) async {
    notifyListeners();

    // Check if we should reschedule reminders
    // We only reschedule if forced (e.g. settings change)
    // or if the goal was just met (to cancel them)
    if (forceReschedule || (_state.currentWaterMl >= _state.dailyGoalMl)) {
      _notificationService.scheduleReminders(_state);
    }

    await _saveWidgetData();
  }

  Future<void> _saveWidgetData() async {
    final data = _state.widgetData;

    await HomeWidget.saveWidgetData('todayMl', data.todayMl);
    await HomeWidget.saveWidgetData('goalMl', data.goalMl);
    await HomeWidget.saveWidgetData('progressPercent', data.progressPercent);
    await HomeWidget.saveWidgetData(
      'progress',
      (data.progressPercent * 100).toInt(),
    );
    await HomeWidget.saveWidgetData('streak', data.streak);
    await HomeWidget.saveWidgetData('goalReached', data.goalReached);
    await HomeWidget.saveWidgetData('quickAddSmall', data.quickAddSmall);
    await HomeWidget.saveWidgetData('quickAddLarge', data.quickAddLarge);

    // New keys for widget action provider Kotlin refactoring later
    await HomeWidget.saveWidgetData('todayUnits', _state.currentWorkoutUnits);
    await HomeWidget.saveWidgetData(
      'goalUnits',
      _state.dailyWorkoutTargetUnits,
    );
    await HomeWidget.saveWidgetData(
      'preferredExerciseLabel',
      _state.preferredExercise.label,
    );

    await HomeWidget.updateWidget(
      androidName: 'WaterWidgetProvider',
      iOSName: 'WaterWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'WaterWidgetBarProvider',
      iOSName: 'WaterWidget',
    );
  }

  // --- NEW WORKOUT METHODS ---

  Future<void> logExercise({
    required ExerciseType exercise,
    required int amount,
    String? customName,
  }) async {
    if (amount <= 0) return; // ignore or reject amount <= 0

    await _checkNewDay(); // Ensure correct day before adding

    final newLog = ExerciseLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      exerciseId: exercise.id,
      amount: amount,
      timestamp: DateTime.now(),
      customName: customName,
    );

    final updatedLogs = List<ExerciseLog>.from(_state.todayLogs)..add(newLog);

    final oldAmount = _state.currentWorkoutUnits;
    final newAmount = oldAmount + amount;

    _state = _state.copyWith(
      currentWaterMl: newAmount,
      todayLogs: updatedLogs,
      lastTrackedDate: DateTime.now(),
    );

    await _storage.saveCurrentWorkoutUnits(newAmount);
    await _storage.saveTodayLogs(updatedLogs);
    await _storage.saveLastLoggedDate(_state.lastTrackedDate);

    // Check for goal met and increment streak
    await _checkGoalMet(
      oldAmount,
      newAmount,
      _state.dailyWorkoutTargetUnits,
      _state.dailyWorkoutTargetUnits,
    );

    await _notifyAndSchedule();
  }

  Future<void> logPreferredExercise(int amount) async {
    await logExercise(exercise: _state.preferredExercise, amount: amount);
  }

  Future<void> setSelectedExercise(ExerciseType exercise) async {
    _state = _state.copyWith(selectedExercise: exercise);
    await _storage.saveSelectedExercise(exercise);
    notifyListeners();
  }

  Future<void> setPreferredExercise(ExerciseType exercise) async {
    _state = _state.copyWith(preferredExercise: exercise);
    await _storage.savePreferredExercise(exercise);
    notifyListeners();
  }

  Future<void> updateDailyWorkoutTargetUnits(int units) async {
    if (units < 0) units = 0; // never allow negative target/progress
    final oldGoal = _state.dailyWorkoutTargetUnits;
    final currentAmount = _state.currentWorkoutUnits;

    _state = _state.copyWith(dailyGoalMl: units);
    await _storage.saveDailyWorkoutTargetUnits(units);

    // Check if goal was just met by lowering it
    await _checkGoalMet(currentAmount, currentAmount, oldGoal, units);

    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateQuickAddSmallUnits(int units) async {
    if (units < 0) units = 0;
    _state = _state.copyWith(quickAddSmall: units);
    await _storage.saveQuickAddSmallUnits(units);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateQuickAddLargeUnits(int units) async {
    if (units < 0) units = 0;
    _state = _state.copyWith(quickAddLarge: units);
    await _storage.saveQuickAddLargeUnits(units);
    await _notifyAndSchedule(forceReschedule: true);
  }

  // --- COMPATIBILITY DELEGATING METHODS ---

  Future<void> addWater(int amount) async {
    await logPreferredExercise(amount);
  }

  Future<void> updateDailyGoal(int newGoal) async {
    await updateDailyWorkoutTargetUnits(newGoal);
  }

  Future<void> updateQuickAdd(int small, int large) async {
    await updateQuickAddSmallUnits(small);
    await updateQuickAddLargeUnits(large);
  }

  // --- GENERAL MANAGEMENT METHODS ---

  Future<void> _checkNewDay() async {
    final now = DateTime.now();
    final lastTracked = _state.lastTrackedDate;

    // Check if it's a new day
    if (now.year != lastTracked.year ||
        now.month != lastTracked.month ||
        now.day != lastTracked.day) {
      // ARCHIVE PREVIOUS DAY
      final dateKey =
          "${lastTracked.year}-${lastTracked.month.toString().padLeft(2, '0')}-${lastTracked.day.toString().padLeft(2, '0')}";

      // Avoid duplicate history entries for the same date
      if (!_state.history.any((h) => h.date == dateKey)) {
        final previousDayHistory = DailyHistory(
          date: dateKey,
          completedUnits: _state.currentWorkoutUnits,
          targetUnits: _state.dailyWorkoutTargetUnits,
          goalReached:
              _state.currentWorkoutUnits >= _state.dailyWorkoutTargetUnits,
          logs: _state.todayLogs,
          completedAt:
              _state.currentWorkoutUnits >= _state.dailyWorkoutTargetUnits
              ? lastTracked
              : null,
        );

        final updatedHistory = List<DailyHistory>.from(_state.history)
          ..add(previousDayHistory);
        _state = _state.copyWith(history: updatedHistory);
        await _storage.saveDailyHistory(updatedHistory);
      }

      // Check if the streak is lost (if yesterday's goal was not met)
      if (_state.lastGoalMetDate != null) {
        final yesterday = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        final lastGoalMet = DateTime(
          _state.lastGoalMetDate!.year,
          _state.lastGoalMetDate!.month,
          _state.lastGoalMetDate!.day,
        );

        if (lastGoalMet.isBefore(yesterday)) {
          // Yesterday was missed, streak is lost
          _state = _state.copyWith(currentStreak: 0);
          await _storage.saveCurrentStreak(0);
        }
      }

      // Reset today
      _state = _state.copyWith(
        currentWaterMl: 0,
        lastTrackedDate: now,
        todayLogs: [],
      );
      await _storage.saveCurrentWater(0);
      await _storage.saveLastTrackedDate(now);
      await _storage.saveTodayLogs([]);
      await _notifyAndSchedule(forceReschedule: true);
    }
  }

  Future<void> _checkGoalMet(
    int oldAmount,
    int newAmount,
    int oldGoal,
    int newGoal,
  ) async {
    final wasMet = oldAmount >= oldGoal;
    final isMet = newAmount >= newGoal;

    if (isMet && !wasMet) {
      // Goal just met!
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int newStreak = _state.currentStreak;

      if (_state.lastGoalMetDate == null) {
        newStreak = 1;
      } else {
        final lastGoalMet = DateTime(
          _state.lastGoalMetDate!.year,
          _state.lastGoalMetDate!.month,
          _state.lastGoalMetDate!.day,
        );

        final difference = today.difference(lastGoalMet).inDays;

        if (difference == 1) {
          newStreak++; // Streak continues
        } else if (difference > 1) {
          newStreak = 1; // Streak restarts
        } else if (difference == 0) {
          // Already met today, don't increment but keep streak
          return;
        }
      }

      _state = _state.copyWith(currentStreak: newStreak, lastGoalMetDate: now);
      await _storage.saveCurrentStreak(newStreak);
      await _storage.saveLastGoalMetDate(now);
    }
  }

  Future<void> resetToday() async {
    _state = _state.copyWith(currentWaterMl: 0, todayLogs: []);
    await _storage.saveCurrentWater(0);
    await _storage.saveTodayLogs([]);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateRemindersEnabled(bool enabled) async {
    _state = _state.copyWith(remindersEnabled: enabled);
    await _storage.saveRemindersEnabled(enabled);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateReminderInterval(int mins) async {
    _state = _state.copyWith(reminderIntervalMins: mins);
    await _storage.saveReminderIntervalMins(mins);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateReminderTimeRange(String start, String end) async {
    _state = _state.copyWith(reminderStartTime: start, reminderEndTime: end);
    await _storage.saveReminderStartTime(start);
    await _storage.saveReminderEndTime(end);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateEveningCheckEnabled(bool enabled) async {
    _state = _state.copyWith(eveningCheckEnabled: enabled);
    await _storage.saveEveningCheckEnabled(enabled);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateEveningCheckTime(String time) async {
    _state = _state.copyWith(eveningCheckTime: time);
    await _storage.saveEveningCheckTime(time);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _state = _state.copyWith(themeMode: mode);
    await _storage.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> updateNotificationSound(String sound) async {
    _state = _state.copyWith(notificationSound: sound);
    await _storage.saveNotificationSound(sound);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> refreshFromStorage() async {
    // Crucial: reload shared_preferences to pick up changes from background isolates
    await _storage.reload();
    await _init();
    notifyListeners();
  }
}
