import 'package:flutter/material.dart';


class DailyHistory {
  final String date; // yyyy-MM-dd
  final int consumedMl;
  final int goalMl;
  final bool goalReached;
  final DateTime? completedAt;

  const DailyHistory({
    required this.date,
    required this.consumedMl,
    required this.goalMl,
    required this.goalReached,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'consumedMl': consumedMl,
    'goalMl': goalMl,
    'goalReached': goalReached,
    'completedAt': completedAt?.millisecondsSinceEpoch,
  };

  factory DailyHistory.fromJson(Map<String, dynamic> json) => DailyHistory(
    date: json['date'],
    consumedMl: json['consumedMl'],
    goalMl: json['goalMl'],
    goalReached: json['goalReached'],
    completedAt: json['completedAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'])
        : null,
  );
}

class WidgetData {
  final int todayMl;
  final int goalMl;
  final double progressPercent;
  final int streak;
  final bool goalReached;
  final int quickAddSmall;
  final int quickAddLarge;

  const WidgetData({
    required this.todayMl,
    required this.goalMl,
    required this.progressPercent,
    required this.streak,
    required this.goalReached,
    required this.quickAddSmall,
    required this.quickAddLarge,
  });

  Map<String, dynamic> toJson() => {
    'todayMl': todayMl,
    'goalMl': goalMl,
    'progressPercent': progressPercent,
    'streak': streak,
    'goalReached': goalReached,
    'quickAddSmall': quickAddSmall,
    'quickAddLarge': quickAddLarge,
  };
}

class HydrationState {
  final int currentWaterMl;
  final int dailyGoalMl;
  final DateTime lastTrackedDate;
  final List<DailyHistory> history;

  // Gamification
  final int currentStreak;
  final DateTime? lastGoalMetDate;

  // Settings
  final bool remindersEnabled;
  final int reminderIntervalMins;
  final String reminderStartTime;
  final String reminderEndTime;
  final bool eveningCheckEnabled;
  final String eveningCheckTime;
  final int quickAddSmall;
  final int quickAddLarge;
  final ThemeMode themeMode;
  final String notificationSound;


  const HydrationState({
    required this.currentWaterMl,
    required this.dailyGoalMl,
    required this.lastTrackedDate,
    required this.history,
    required this.currentStreak,
    this.lastGoalMetDate,
    required this.remindersEnabled,
    required this.reminderIntervalMins,
    required this.reminderStartTime,
    required this.reminderEndTime,
    this.eveningCheckEnabled = false,
    this.eveningCheckTime = '21:00',
    this.quickAddSmall = 250,
    this.quickAddLarge = 500,
    this.themeMode = ThemeMode.system,
    this.notificationSound = 'notification_sound',
  });


  HydrationState copyWith({
    int? currentWaterMl,
    int? dailyGoalMl,
    DateTime? lastTrackedDate,
    List<DailyHistory>? history,
    int? currentStreak,
    DateTime? lastGoalMetDate,
    bool? remindersEnabled,
    int? reminderIntervalMins,
    String? reminderStartTime,
    String? reminderEndTime,
    bool? eveningCheckEnabled,
    String? eveningCheckTime,
    int? quickAddSmall,
    int? quickAddLarge,
    ThemeMode? themeMode,
    String? notificationSound,
  }) {

    return HydrationState(
      currentWaterMl: currentWaterMl ?? this.currentWaterMl,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      lastTrackedDate: lastTrackedDate ?? this.lastTrackedDate,
      history: history ?? this.history,
      currentStreak: currentStreak ?? this.currentStreak,
      lastGoalMetDate: lastGoalMetDate ?? this.lastGoalMetDate,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderIntervalMins: reminderIntervalMins ?? this.reminderIntervalMins,
      reminderStartTime: reminderStartTime ?? this.reminderStartTime,
      reminderEndTime: reminderEndTime ?? this.reminderEndTime,
      eveningCheckEnabled: eveningCheckEnabled ?? this.eveningCheckEnabled,
      eveningCheckTime: eveningCheckTime ?? this.eveningCheckTime,
      quickAddSmall: quickAddSmall ?? this.quickAddSmall,
      quickAddLarge: quickAddLarge ?? this.quickAddLarge,
      themeMode: themeMode ?? this.themeMode,
      notificationSound: notificationSound ?? this.notificationSound,
    );

  }

  WidgetData get widgetData => WidgetData(
    todayMl: currentWaterMl,
    goalMl: dailyGoalMl,
    progressPercent: (currentWaterMl / dailyGoalMl).clamp(0.0, 1.0),
    streak: currentStreak,
    goalReached: currentWaterMl >= dailyGoalMl,
    quickAddSmall: quickAddSmall,
    quickAddLarge: quickAddLarge,
  );
}
