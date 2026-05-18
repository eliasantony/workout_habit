import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

import 'package:hydro_habit/features/hydration/hydration_models.dart';
import 'package:hydro_habit/features/hydration/hydration_storage.dart';
import 'package:hydro_habit/services/notification_service.dart';

class HydrationController extends ChangeNotifier {

  final HydrationStorage _storage;
  final NotificationService _notificationService;
  final Completer<void> _initCompleter = Completer<void>();

  late HydrationState _state;

  HydrationController(this._storage, this._notificationService) {
    _init();
  }

  Future<void> get ready => _initCompleter.future;

  HydrationState get state => _state;

  Future<void> _init() async {
    final currentWater = _storage.getCurrentWater();
    final dailyGoal = _storage.getDailyGoal();
    final lastTrackedDate = _storage.getLastTrackedDate();

    final remindersEnabled = _storage.getRemindersEnabled();
    final reminderIntervalMins = _storage.getReminderIntervalMins();
    final reminderStartTime = _storage.getReminderStartTime();
    final reminderEndTime = _storage.getReminderEndTime();

    final currentStreak = _storage.getCurrentStreak();
    final lastGoalMetDate = _storage.getLastGoalMetDate();
    final history = _storage.getDailyHistory();

    final quickAddSmall = _storage.getQuickAddSmall();
    final quickAddLarge = _storage.getQuickAddLarge();

    final eveningCheckEnabled = _storage.getEveningCheckEnabled();
    final eveningCheckTime = _storage.getEveningCheckTime();
    final themeMode = _storage.getThemeMode();
    final notificationSound = _storage.getNotificationSound();


    _state = HydrationState(
      currentWaterMl: currentWater,
      dailyGoalMl: dailyGoal,
      lastTrackedDate: lastTrackedDate,
      history: history,
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
    await HomeWidget.saveWidgetData('progress', (data.progressPercent * 100).toInt());
    await HomeWidget.saveWidgetData('streak', data.streak);
    await HomeWidget.saveWidgetData('goalReached', data.goalReached);
    await HomeWidget.saveWidgetData('quickAddSmall', data.quickAddSmall);
    await HomeWidget.saveWidgetData('quickAddLarge', data.quickAddLarge);
    
    await HomeWidget.updateWidget(
      androidName: 'WaterWidgetProvider',
      iOSName: 'WaterWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'WaterWidgetBarProvider',
      iOSName: 'WaterWidget',
    );
  }

  Future<void> updateQuickAdd(int small, int large) async {
    _state = _state.copyWith(quickAddSmall: small, quickAddLarge: large);
    await _storage.saveQuickAddSmall(small);
    await _storage.saveQuickAddLarge(large);
    await _notifyAndSchedule(forceReschedule: true);
  }

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
          consumedMl: _state.currentWaterMl,
          goalMl: _state.dailyGoalMl,
          goalReached: _state.currentWaterMl >= _state.dailyGoalMl,
          completedAt: _state.currentWaterMl >= _state.dailyGoalMl
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
      _state = _state.copyWith(currentWaterMl: 0, lastTrackedDate: now);
      await _storage.saveCurrentWater(0);
      await _storage.saveLastTrackedDate(now);
      await _notifyAndSchedule(forceReschedule: true);
    }
  }

  Future<void> addWater(int amount) async {
    await _checkNewDay(); // Ensure we are on the correct day before adding

    int oldAmount = _state.currentWaterMl;
    int newAmount = oldAmount + amount;
    
    _state = _state.copyWith(currentWaterMl: newAmount);
    await _storage.saveCurrentWater(newAmount);

    // Check for goal met and increment streak
    await _checkGoalMet(oldAmount, newAmount, _state.dailyGoalMl, _state.dailyGoalMl);

    // Also save last tracked date just in case
    final now = DateTime.now();
    _state = _state.copyWith(lastTrackedDate: now);
    await _storage.saveLastTrackedDate(now);

    await _notifyAndSchedule();
  }

  Future<void> _checkGoalMet(int oldAmount, int newAmount, int oldGoal, int newGoal) async {
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
      
      // Note: We don't call notifyListeners here because addWater/updateDailyGoal will call _notifyAndSchedule
    }
  }

  Future<void> resetToday() async {
    _state = _state.copyWith(currentWaterMl: 0);
    await _storage.saveCurrentWater(0);
    await _notifyAndSchedule(forceReschedule: true);
  }

  Future<void> updateDailyGoal(int newGoal) async {
    final oldGoal = _state.dailyGoalMl;
    final currentAmount = _state.currentWaterMl;

    _state = _state.copyWith(dailyGoalMl: newGoal);
    await _storage.saveDailyGoal(newGoal);

    // Check if goal was just met by lowering it
    await _checkGoalMet(currentAmount, currentAmount, oldGoal, newGoal);

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
