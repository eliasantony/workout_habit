# ROADMAP

This document outlines the phases of the **Workout Habit** migration and development process. We are reusing the Hydro Habit repository as a code template to launch a brand-new local-only workout logging application.

---

## Phase 0: Documentation Alignment [Completed]
- [x] Update `AGENTS.md` with new project goals, generalized units, and safety guidelines.
- [x] Update `ROADMAP.md` with workout-focused phases.
- [x] Update `implementation_plan.md` to reflect template reuse, empty history default, and no data migration.
- [x] Add short migration warning note at the top of `README.md` (to be fully refactored after migration).

---

## Phase 1: Safe Rename & Base Foundation [Completed]
- [x] Rename user-facing application label in `AndroidManifest.xml` to "Workout Habit".
- [x] Refactor package name in `pubspec.yaml` to `workout_habit`.
- [x] Update all package imports in `lib/` and `test/` to `package:workout_habit/...`.
- [x] Rename the hydration feature folder (`lib/features/hydration`) to `lib/features/workout`.
- [x] Rename files inside the workout folder to match workout/exercise terminology.
- [x] Verify clean compilation before making deep logic modifications.

---

## Phase 2: Workout Domain Model & Storage [Completed]
- [x] Implement `ExerciseType` enum (Push-ups, Sit-ups, Squats, Planks, Custom).
- [x] Implement `ExerciseLog` class with robust `fromJson` defensive parsing.
- [x] Implement `DailyWorkoutHistory` model with list of logs.
- [x] Define `WorkoutState` matching the fresh defaults (50 target, push-ups preferred).
- [x] Write `WorkoutStorage` to wrap `SharedPreferences` with generalized unit keys.
- [x] Implement `clearLegacyKeys()` on storage load to safely delete older Hydro Habit keys.

---

## Phase 3: Controller & Business Logic [Completed]
- [x] Refactor `HydrationController` into `WorkoutController` (`ChangeNotifier`).
- [x] Implement `logExercise(ExerciseType, amount)` with strict positive-number checks.
- [x] Integrate streak validation based on completing combined daily target units.
- [x] Implement safe checks for "new day" transitions to reset today's units count to 0.
- [x] Update `_saveWidgetData()` to push `todayUnits`, `goalUnits`, `preferredExerciseLabel`, and `streak` to `home_widget`.

---

## Cleanup Checkpoint: Legacy Label Purge [Completed]
- [x] Rename smoke test name from "Hydration screen smoke test" to "Workout Habit screen smoke test".
- [x] Adapt widget test expectations to workout-oriented strings.
- [x] Clean up obvious app-facing water/hydration/ml/drink water labels to workout/units counterparts in:
  - `lib/features/workout/workout_screen.dart`
  - `lib/features/workout/widgets/log_exercise_dialog.dart`
  - `lib/features/settings/settings_screen.dart`
  - `lib/features/history/history_screen.dart`
  - `lib/services/notification_service.dart`
  - `lib/main_screen.dart`
- [x] Verify clean compilation with `flutter analyze` (0 issues).
- [x] Verify all tests pass with `flutter test` (all tests passed!).

---

## Phase 4: Interactive UI Refactoring [Pending]
- [x] Adapt home screen (`workout_screen.dart`) to show workout progress.
- [x] Replace water mascot with Workout Mascot reacting with motivational badges (💪, 🔥, 🏆).
- [x] Implement beautiful horizontal selector for bodyweight exercises on the home screen.
- [x] Configure quick log buttons (`+5`, `+10`, `+20`, and `Custom` on the Home Screen) to log the active exercise, showing dynamic labels (e.g. `+5 reps` or `+5 sec`).
- [x] Refactor `LogExerciseDialog` to display custom repetitions grid inputs.
- [ ] Redesign `SettingsScreen` to manage daily target, preferred exercise, and theme modes.
- [ ] Redesign `HistoryScreen` to display daily completed units against target, and build a bottom sheet list detailing individual exercises performed on selected days.

---

## Phase 5: Notifications Simplification [Pending]
- [ ] Refactor `NotificationService` to support simplified notification schedules.
- [ ] Implement Switch 1: Daily Workout Reminder (Toggle and Time Picker).
- [ ] Implement Switch 2: Evening Target Check (Toggle and Time Picker).
- [ ] Update notification text to gym motivation quotes and verify background actions log to the preferred exercise.

---

## Phase 6: Android Native Widget Sync [Pending]
- [ ] Update native Android layouts (`widget_layout_square.xml`, `widget_layout_bar.xml`) to display "Workout Habit".
- [ ] Update native widget providers to bind and display `todayUnits`, `goalUnits`, and `preferredExerciseLabel` (e.g., "+5 Push-ups").
- [ ] Update `WidgetActionReceiver.kt` key mappings and implement logging the Preferred Exercise on interactive widget button clicks.
- [ ] Verify interactive home widgets sync immediately with the app before renaming native Kotlin files.

---

## Phase 7: Theme & Branding Polish [Pending]
- [ ] Implement the energetic and premium workout theme in `app_theme.dart` (vibrant Flame Coral / Sunset Orange + slate dark mode colors).
- [ ] Replace all water-themed graphics/icons with workout-themed visual elements.

---

## Phase 8: Tests & Verification [Pending]
- [ ] Adapt `widget_test.dart` to test Workout Habit widget rendering.
- [ ] Run `flutter format .` to format the migrated codebase.
- [ ] Run `flutter analyze` to ensure 0 linting errors or warnings.
- [ ] Run `flutter test` to ensure all tests pass.
- [ ] Clean up dead hydration assets/resources and fully update the `README.md`.
