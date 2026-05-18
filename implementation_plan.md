# Implementation Plan: Workout Habit (Brand New Template Launch)

This document outlines the updated design, domain models, exact modifications, and step-by-step execution roadmap to convert **Hydro Habit** into **Workout Habit** as a brand-new, local-first workout tracker. There are no requirements for backward compatibility or historical data migration.

---

## User Direction & Final Decisions

> [!IMPORTANT]
> **No Upgrade Path Required**: This is a new local-only personal app using Hydro Habit as a code template. All backward compatibility, data migration, and translation of old hydration values are eliminated.
> - Start with a clean, empty workout history.
> - Widen the use of **generalized "units"** internally rather than hardcoding "reps", accommodating both reps (for push-ups/sit-ups/squats) and seconds (for planks).

> [!TIP]
> **Android Widget Action & Visual Label**: 
> - The two interactive widget buttons (+5 and +10) will log the **Preferred Exercise** rather than generic reps.
> - The native layout will show the preferred exercise label (e.g. "Push-ups") so the user knows exactly what they are logging.

> [!NOTE]
> **Application ID Retention**:
> - The native Android `applicationId` will remain `com.example.hydrohabit.hydro_habit` during early migration to minimize native build friction, with the flexibility to rename later if needed. The user-facing app name in `AndroidManifest.xml` will be changed to **Workout Habit**.

---

## Default State Configuration

Upon first boot or fresh database initialization:
- **Daily Target**: 50 units (reps/seconds)
- **Preferred Exercise**: Push-ups
- **Quick Actions**: +5 and +10 (or +5, +10, +20, and Custom on the Home Screen)
- **Streak**: 0 days
- **Today's Progress**: 0 units
- **History**: Empty

---

## Proposed Domain Model

The domain model will capture individual exercise logs with specific types (supporting both reps and seconds).

```dart
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
    return ExerciseType.values.firstWhere((e) => e.id == id, orElse: () => ExerciseType.custom);
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

  factory ExerciseLog.fromJson(Map<String, dynamic> json) => ExerciseLog(
    id: json['id'] ?? '',
    exerciseId: json['exerciseId'] ?? 'push_ups',
    amount: json['amount'] ?? 0,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    customName: json['customName'],
  );
}

class DailyWorkoutHistory {
  final String date; // yyyy-MM-dd
  final int completedUnits; // Total units completed today
  final int targetUnits; // Daily target units
  final bool goalReached;
  final List<ExerciseLog> logs;

  const DailyWorkoutHistory({
    required this.date,
    required this.completedUnits,
    required this.targetUnits,
    required this.goalReached,
    required this.logs,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'completedUnits': completedUnits,
    'targetUnits': targetUnits,
    'goalReached': goalReached,
    'logs': logs.map((l) => l.toJson()).toList(),
  };

  factory DailyWorkoutHistory.fromJson(Map<String, dynamic> json) => DailyWorkoutHistory(
    date: json['date'],
    completedUnits: json['completedUnits'] ?? 0,
    targetUnits: json['targetUnits'] ?? 50,
    goalReached: json['goalReached'] ?? false,
    logs: (json['logs'] as List? ?? [])
        .map((l) => ExerciseLog.fromJson(l))
        .toList(),
  );
}
```

---

## File-by-File Conceptual Changes & Renames

### 📂 Feature Directory Renaming
- Rename `lib/features/hydration/` ➡️ `lib/features/workout/`
- Rename files inside:
  - `hydration_controller.dart` ➡️ `workout_controller.dart`
  - `hydration_models.dart` ➡️ `workout_models.dart`
  - `hydration_screen.dart` ➡️ `workout_screen.dart`
  - `hydration_storage.dart` ➡️ `workout_storage.dart`
  - `widgets/add_water_dialog.dart` ➡️ `widgets/log_exercise_dialog.dart`

---

## Proposed Changes

### Core Foundation

#### [MODIFY] [pubspec.yaml](file:///c:/Developing/workout_habit/pubspec.yaml)
- Update package name to `workout_habit`.
- Keep dependencies: `shared_preferences`, `flutter_local_notifications`, `home_widget`, `audioplayers`, `workmanager`.
- Modify launcher icons assets references to the new mascot.

#### [MODIFY] [app_theme.dart](file:///c:/Developing/workout_habit/lib/theme/app_theme.dart)
- Setup a fitness-focused palette:
  - **Light Theme Primary**: Flame Coral (`Color(0xFFFF5A36)`) or Vibrant Sunset Orange (`Color(0xFFF97316)`).
  - **Dark Theme Primary**: Salmon Pink (`Color(0xFFFF8C69)`).
  - **Light/Dark Surfaces**: Clean Material 3 style with deep charcoal (`Color(0xFF0B0E14)`) and slate colors.
- Maintain existing card shapes (`BorderRadius.circular(24)`).

### Workout Domain Feature (`lib/features/workout/`)

#### [NEW] [workout_models.dart](file:///c:/Developing/workout_habit/lib/features/workout/workout_models.dart)
- Declare `ExerciseType`, `ExerciseLog`, and `DailyWorkoutHistory`.
- Establish `WorkoutState` to capture app state (theme preference, daily target, selected preferred exercise, logs list).

#### [NEW] [workout_storage.dart](file:///c:/Developing/workout_habit/lib/features/workout/workout_storage.dart)
- Manage preferences with clean workout keys: `current_workout_units`, `daily_workout_target`, `preferred_exercise`, `selected_exercise`, `quick_add_small` (default: 5), `quick_add_large` (default: 10), streaks, and empty history.
- Write a clean `clearLegacyKeys()` method that runs once on app boot to ensure that any older `current_water_ml` or legacy preferences are permanently deleted from SharedPreferences to avoid state pollution.

#### [NEW] [workout_controller.dart](file:///c:/Developing/workout_habit/lib/features/workout/workout_controller.dart)
- Implement rep logging, streak calculations, preferred exercise handling, and `_saveWidgetData()` updates.
- Pass variables `todayUnits` (representing completed units today), `goalUnits` (target), `preferredExerciseLabel`, and `streak` to `home_widget`.

#### [NEW] [workout_screen.dart](file:///c:/Developing/workout_habit/lib/features/workout/workout_screen.dart)
- Redefine droplet mascot to a Workout Coach Mascot (`_WorkoutMascot`) reacting to daily progress with motivational badges (💪, 🔥, 🏆).
- Render a modern, horizontal exercise selector (Push-ups, Sit-ups, Squats, Plank, Custom).
- Configure Quick Log Buttons: `+5`, `+10`, `+20`, and a dedicated `Custom` button. The labels adapt automatically to the active unit (e.g. `+5 reps` or `+5 sec`).

#### [NEW] [log_exercise_dialog.dart](file:///c:/Developing/workout_habit/lib/features/workout/widgets/log_exercise_dialog.dart)
- Replace fluid containers with standard workout quantities grid:
  - `+5` and `+10`
  - `+20` and `+30`
  - Numeric keyboard input for customized entries.

### Navigation & Sub-Screens

#### [MODIFY] [main_screen.dart](file:///c:/Developing/workout_habit/lib/main_screen.dart)
- Import workout controllers and pages.
- Update bottom bar buttons: `Icons.fitness_center_rounded` (Home) and `Icons.calendar_month_rounded` (History).
- Map floating action button to `LogExerciseDialog`.

#### [MODIFY] [settings_screen.dart](file:///c:/Developing/workout_habit/lib/features/settings/settings_screen.dart)
- Modify labels: "Hydration Goal" ➡️ "Daily Workout Target", "Quick Add" ➡️ "Quick Action Presets".
- Add "Preferred Exercise" selection dropdown.
- **Simplified Notifications**:
  - Switch 1: Daily Reminder (Toggle & Time picker).
  - Switch 2: Evening Target Check (Toggle & Time picker).
  - Notifications display motivational gym quotes.

#### [MODIFY] [history_screen.dart](file:///c:/Developing/workout_habit/lib/features/history/history_screen.dart)
- Change layout text from `ml` to `units` or localized exercise labels.
- **Day Logs Detail Bottom Sheet**: Tapping a day in the calendar displays a bottom sheet with a list of logs completed that day (e.g. "Push-ups: 15 reps", "Plank: 60 sec").

### Background & Services

#### [MODIFY] [notification_service.dart](file:///c:/Developing/workout_habit/lib/services/notification_service.dart)
- Schedule two rolling notifications daily (Daily workout reminder and Evening goal check).
- Configure widget action callbacks to increment preferred exercise units.

#### [MODIFY] [main.dart](file:///c:/Developing/workout_habit/lib/main.dart)
- Initialize widget callbacks with the new keys.

### Android Native Widgets (`android/`)

#### [MODIFY] [WaterWidgetProvider.kt](file:///c:/Developing/workout_habit/android/app/src/main/kotlin/com/example/hydrohabit/hydro_habit/WaterWidgetProvider.kt) & [WaterWidgetBarProvider.kt](file:///c:/Developing/workout_habit/android/app/src/main/kotlin/com/example/hydrohabit/hydro_habit/WaterWidgetBarProvider.kt)
- Read variables `todayUnits`, `goalUnits`, and `preferredExerciseLabel`.
- Render labels beautifully on the widget (e.g., displaying `25 / 50 Push-ups` or `Plank` details).

#### [MODIFY] [WidgetActionReceiver.kt](file:///c:/Developing/workout_habit/android/app/src/main/kotlin/com/example/hydrohabit/hydro_habit/WidgetActionReceiver.kt)
- Read `"flutter.preferred_exercise"` to determine units and log the selected values on interactive clicks.
- Update layout elements accurately.

#### [MODIFY] [widget_layout_square.xml](file:///c:/Developing/workout_habit/android/app/src/main/res/layout/widget_layout_square.xml) & [widget_layout_bar.xml](file:///c:/Developing/workout_habit/android/app/src/main/res/layout/widget_layout_bar.xml)
- Change display text configurations: `Hydro Habit` ➡️ `Workout Habit`.
- Bind labels dynamically.

---

## Verification Plan

### Automated Tests
- Adapt `widget_test.dart` to assert:
  - Display matches "Workout Habit".
  - Core tracking shows "0 of 50 units".
  - Quick action buttons are visible with "+5" and "+10" labels.
- Run:
  ```bash
  flutter test
  ```

---

## Step-by-Step Execution Plan

### Phase 1: Clean Rename & Base Foundation
1. **Commit 1**: Rename package in `pubspec.yaml` to `workout_habit`, and refactor all references and package imports inside `lib/` and `test/` to `package:workout_habit/...`. Verify compilation.
2. **Commit 2**: Rename the feature folder `lib/features/hydration` to `lib/features/workout` and perform local file renames. Rename `Hydration` classes to `Workout` equivalents.
3. **Commit 3**: Implement styling changes in `lib/theme/app_theme.dart` (Vibrant Coral/Salmon/Sunset + charcoal palette).

### Phase 2: Domain Model & Storage Cleanup
4. **Commit 4**: Implement the detailed workout models in `workout_models.dart`.
5. **Commit 5**: Implement the storage layer in `workout_storage.dart`, including the key definitions, default getters/setters, and the legacy cleanup method `clearLegacyKeys()`.
6. **Commit 6**: Build the core business logic inside `workout_controller.dart`.

### Phase 3: Interactive UI Refactoring
7. **Commit 7**: Adapt the home screen `workout_screen.dart` with the horizontal exercise type selector, workout mascot configurations, and quick log buttons.
8. **Commit 8**: Implement the `LogExerciseDialog` with the grid configuration, custom inputs, and dynamic units (reps/seconds).
9. **Commit 9**: Refactor `HistoryScreen` with stats, completion rates, and the bottom modal detailing individual exercises logged.
10. **Commit 10**: Refactor `SettingsScreen` with daily targets, preferred exercise selections, simplified daily and evening notification switches, and audio controllers.

### Phase 4: Native Android Widget & Services Sync
11. **Commit 11**: Refactor `NotificationService` to support simplified reminders (one daily, one evening), fitness-inspired messaging, and updated preferred exercise background actions.
12. **Commit 12**: Modify `main.dart` background callbacks to process the new widget keys.
13. **Commit 13**: Refactor Kotlin Native widget code (`WaterWidgetProvider.kt`, `WaterWidgetBarProvider.kt`, and `WidgetActionReceiver.kt`) to utilize the updated workout SharedPreferences keys and trigger the preferred exercise additions.
14. **Commit 14**: Update widget XML layouts (`widget_layout_square.xml`, `widget_layout_bar.xml`) and system color configurations (`colors.xml`) to align with Workout Habit.

### Phase 5: Verification & Polishing
15. **Commit 15**: Generate a premium cartoon flame/workout mascot image under `assets/images/mascot.png` using the `generate_image` tool.
16. **Commit 16**: Adapt `widget_test.dart` to match Workout Habit tracking smoke tests, verify that `flutter test` completes successfully.
