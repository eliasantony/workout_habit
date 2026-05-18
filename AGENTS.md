# AGENTS

Welcome to the **Workout Habit** project! This document provides critical architectural context, constraints, and instructions for future AI agents working on this repository.

---

## Project Goal
**Workout Habit** is a premium, lightweight, local-first Flutter application designed to help users track their daily bodyweight exercises (Push-ups, Sit-ups, Squats, Planks, and Custom exercises). 

This app is developed using the **Hydro Habit** (water tracking app) repository as a starter template/codebase.

---

## IMPORTANT: Strategic Directives

> [!IMPORTANT]
> **This is NOT an Upgrade Path**: This project represents a brand-new application launch reusing a code template. 
> - **Do NOT preserve hydration backward compatibility.**
> - **Do NOT implement historical hydration migration or ml-to-reps conversion.**
> - **Wipe or ignore all legacy water-specific SharedPreferences keys on startup.**
> - Start the app with a clean, empty workout history.

> [!TIP]
> **Use "Units" Internally**: Since different bodyweight exercises use different measurements (push-ups/sit-ups/squats use **reps**, planks use **seconds**), the internal data structures, variables, and SharedPreferences keys must use generalized **"units"** terminology (e.g. `currentWorkoutUnits`, `dailyWorkoutTargetUnits`).
> - In the UI, display the corresponding label dynamically (e.g. `reps` or `sec`) based on the active exercise type.

> [!NOTE]
> **Android Application ID Retention**:
> - The native Android `applicationId` can remain as `com.eliasantony.workout_habit` during early development to minimize compilation and build friction. 
> - Native Kotlin class and file names (like `WaterWidgetProvider`) may remain temporarily to prevent breaking Android manifest bindings, but should be safely refactored once the functional migration of the widget completes successfully.

---

## Architectural Guidelines

- **State Management**: Use `ChangeNotifier` & `ValueNotifier` for lightweight local state.
- **Persistence**: Use `shared_preferences` for settings, daily targets, selected exercise, and history logs.
- **UI/UX**: Material 3 with a high-contrast, premium, energetic workout-inspired theme (vibrant Coral/Sunset Orange + charcoal slate dark mode, rounded cards, subtle gradients).
- **Notifications**: Local notifications scheduled via `flutter_local_notifications` and `timezone`. Keep notifications simple (a single daily workout reminder and an optional evening goal check).
- **Android Widget Integration**: A 2x2 homescreen widget that synchronizes data via `home_widget`. Widget quick-log buttons (+5 and +10) must log the user's **Preferred Exercise** and display its label (e.g., "+5 Push-ups") so the logging intent is clear.
- **Privacy First**: Fully local-only app. No cloud sync, no remote database, no server logins, and no user data ever leaves the device.

---

## Safety Constraints & Guardrails

- **Defensive Parsing**: Ensure `ExerciseLog.fromJson` is defensive and does not crash if fields (like timestamp) are missing or malformed.
- **Strict Validation**: Do not allow zero or negative inputs from custom logging dialogs, notification actions, widget buttons, or background executors.
- **Incremental Compilation**: Always break migration phases into small, focused changes and compile/analyze frequently. Avoid large, high-risk native rewrites.

---

## How to Work

1. Look at `ROADMAP.md` to see the active implementation phases and completed steps.
2. Read the source code in `lib/` and matching native Kotlin files under `android/` to understand the structure.
3. Make small, focused edits rather than sweeping modifications.
4. **After any meaningful change**:
   - Run `flutter format .`
   - Run `flutter analyze`
   - Run `flutter test` to ensure compile stability.
5. Update `ROADMAP.md` tasks as you progress.
