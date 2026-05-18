import 'package:flutter/material.dart';

enum ExerciseType {
  pushUps('push_ups', 'Push-ups', 'reps', Icons.fitness_center_rounded),
  sitUps('sit_ups', 'Sit-ups', 'reps', Icons.accessibility_new_rounded),
  squats('squats', 'Squats', 'reps', Icons.directions_run_rounded),
  plank('plank', 'Plank', 'sec', Icons.timer_rounded),
  custom('custom', 'Custom', 'units', Icons.star_rounded);

  final String id;
  final String label;
  final String unit;
  final IconData icon;

  const ExerciseType(this.id, this.label, this.unit, this.icon);

  static ExerciseType fromId(String id) {
    return ExerciseType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ExerciseType.custom,
    );
  }
}

class ExerciseLog {
  final String id;
  final String exerciseId; // push_ups, sit_ups, squats, plank, custom
  final int amount; // units (reps or seconds)
  final DateTime timestamp;
  final String? customName; // Used if exerciseId is 'custom'

  const ExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.amount,
    required this.timestamp,
    this.customName,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'amount': amount,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'customName': customName,
  };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    int parsedAmount = 0;
    if (rawAmount is num) {
      parsedAmount = rawAmount.toInt();
    }
    // Amount should never be negative
    if (parsedAmount < 0) {
      parsedAmount = 0;
    }

    DateTime parsedTimestamp;
    try {
      final rawTimestamp = json['timestamp'];
      if (rawTimestamp is num) {
        parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(
          rawTimestamp.toInt(),
        );
      } else if (rawTimestamp is String) {
        parsedTimestamp = DateTime.parse(rawTimestamp);
      } else {
        parsedTimestamp = DateTime.now();
      }
    } catch (_) {
      parsedTimestamp = DateTime.now();
    }

    return ExerciseLog(
      id: json['id']?.toString() ?? '',
      exerciseId: json['exerciseId']?.toString() ?? 'push_ups',
      amount: parsedAmount,
      timestamp: parsedTimestamp,
      customName: json['customName']?.toString(),
    );
  }
}

class DailyWorkoutHistory {
  final String date; // yyyy-MM-dd
  final int completedUnits; // Total units completed today
  final int targetUnits; // Daily target units
  final bool goalReached;
  final List<ExerciseLog> logs;
  final DateTime? completedAt; // compatibility field

  const DailyWorkoutHistory({
    required this.date,
    int? completedUnits,
    int? targetUnits,
    required this.goalReached,
    this.logs = const [],
    this.completedAt,
    // compatibility support
    int? consumedMl,
    int? goalMl,
  }) : completedUnits = completedUnits ?? consumedMl ?? 0,
       targetUnits = targetUnits ?? goalMl ?? 50;

  int get consumedMl => completedUnits;
  int get goalMl => targetUnits;

  Map<String, dynamic> toJson() => {
    'date': date,
    'completedUnits': completedUnits,
    'targetUnits': targetUnits,
    'goalReached': goalReached,
    'logs': logs.map((l) => l.toJson()).toList(),
    'completedAt': completedAt?.millisecondsSinceEpoch,
    // compatibility support
    'consumedMl': consumedMl,
    'goalMl': goalMl,
  };

  factory DailyWorkoutHistory.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'] as List?;
    final parsedLogs = rawLogs != null
        ? rawLogs
              .map((l) => ExerciseLog.fromJson(l as Map<String, dynamic>))
              .toList()
        : <ExerciseLog>[];

    final completed = json['completedUnits'] ?? json['consumedMl'] ?? 0;
    final target = json['targetUnits'] ?? json['goalMl'] ?? 50;
    final reached = json['goalReached'] ?? false;

    DateTime? completedTime;
    if (json['completedAt'] != null) {
      try {
        completedTime = DateTime.fromMillisecondsSinceEpoch(
          json['completedAt'],
        );
      } catch (_) {
        // Defensive
      }
    }

    return DailyWorkoutHistory(
      date: json['date'] ?? '',
      completedUnits: completed is num ? completed.toInt() : 0,
      targetUnits: target is num
          ? (target.toInt() >= 0 ? target.toInt() : 50)
          : 50,
      goalReached: reached is bool ? reached : false,
      logs: parsedLogs,
      completedAt: completedTime,
    );
  }
}

typedef DailyHistory = DailyWorkoutHistory;

class WidgetData {
  final int todayUnits;
  final int goalUnits;
  final double progressPercent;
  final int streak;
  final bool goalReached;
  final int quickAddSmall;
  final int quickAddLarge;

  const WidgetData({
    required this.todayUnits,
    required this.goalUnits,
    required this.progressPercent,
    required this.streak,
    required this.goalReached,
    required this.quickAddSmall,
    required this.quickAddLarge,
  });

  int get todayMl => todayUnits;
  int get goalMl => goalUnits;

  Map<String, dynamic> toJson() => {
    'todayUnits': todayUnits,
    'goalUnits': goalUnits,
    'todayMl': todayUnits,
    'goalMl': goalUnits,
    'progressPercent': progressPercent,
    'streak': streak,
    'goalReached': goalReached,
    'quickAddSmall': quickAddSmall,
    'quickAddLarge': quickAddLarge,
  };
}

class WorkoutState {
  final int currentWorkoutUnits;
  final int dailyWorkoutTargetUnits;
  final DateTime lastTrackedDate;
  final List<DailyWorkoutHistory> history;
  final List<ExerciseLog> todayLogs;

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

  // New fields
  final ExerciseType preferredExercise;
  final ExerciseType selectedExercise;

  const WorkoutState({
    required this.currentWorkoutUnits,
    required this.dailyWorkoutTargetUnits,
    required this.lastTrackedDate,
    required this.history,
    this.todayLogs = const [],
    required this.currentStreak,
    this.lastGoalMetDate,
    required this.remindersEnabled,
    required this.reminderIntervalMins,
    required this.reminderStartTime,
    required this.reminderEndTime,
    this.eveningCheckEnabled = false,
    this.eveningCheckTime = '21:00',
    required this.quickAddSmall,
    required this.quickAddLarge,
    required this.themeMode,
    required this.notificationSound,
    this.preferredExercise = ExerciseType.pushUps,
    this.selectedExercise = ExerciseType.pushUps,
  });

  int get todayUnits => currentWorkoutUnits;
  int get goalUnits => dailyWorkoutTargetUnits;

  WorkoutState copyWith({
    int? currentWorkoutUnits,
    int? dailyWorkoutTargetUnits,
    DateTime? lastTrackedDate,
    List<DailyWorkoutHistory>? history,
    List<ExerciseLog>? todayLogs,
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
    ExerciseType? preferredExercise,
    ExerciseType? selectedExercise,
  }) {
    return WorkoutState(
      currentWorkoutUnits: currentWorkoutUnits ?? this.currentWorkoutUnits,
      dailyWorkoutTargetUnits:
          dailyWorkoutTargetUnits ?? this.dailyWorkoutTargetUnits,
      lastTrackedDate: lastTrackedDate ?? this.lastTrackedDate,
      history: history ?? this.history,
      todayLogs: todayLogs ?? this.todayLogs,
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
      preferredExercise: preferredExercise ?? this.preferredExercise,
      selectedExercise: selectedExercise ?? this.selectedExercise,
    );
  }

  WidgetData get widgetData => WidgetData(
    todayUnits: currentWorkoutUnits,
    goalUnits: dailyWorkoutTargetUnits,
    progressPercent: (currentWorkoutUnits / dailyWorkoutTargetUnits).clamp(
      0.0,
      1.0,
    ),
    streak: currentStreak,
    goalReached: currentWorkoutUnits >= dailyWorkoutTargetUnits,
    quickAddSmall: quickAddSmall,
    quickAddLarge: quickAddLarge,
  );
}
