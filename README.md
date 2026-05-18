# Workout Habit 🏋️

**Workout Habit** is a premium, lightweight, local-first Flutter application designed to help users track their daily bodyweight exercises (Push-ups, Sit-ups, Squats, Planks, and Custom exercises) and build long-term fitness habits. 

Designed with rich visual aesthetics, deep slate dark modes, and dynamic micro-animations, Workout Habit helps you build consistent physical workout habits while keeping your personal data completely secure and private on your device.

---

## ✨ Features

- **Intuitive Workout Logging**: Track bodyweight reps or seconds of exercises (Push-ups, Sit-ups, Squats, Planks, and Custom workouts) with predefined buttons (`+5`, `+10`, `+20`) or custom inputs.
- **Generalized Units Architecture**: Automatically adapts UI terminology to display reps (for push-ups/squats/sit-ups), seconds (for planks), or custom units dynamically.
- **Vibrant & Premium Fitness Aesthetic**: Beautiful Material 3 UI featuring vibrant Flame Coral / Sunset Orange accent colors, elegant glassmorphic cards, and deep slate dark mode.
- **Motivational Mascot & Celebratory Milestones**: Expressive mascot reacting to your daily progression with rewards and motivational badges (💪, 🔥, 🏆).
- **Streak & Goal Tracking**: Keep a daily target (default 50 units) to construct workout streaks and maintain fitness consistency.
- **Smart Notification Reminders**: Simplified daily training reminders and evening goal-check alerts scheduled using a robust, rolling 7-day calendar.
- **Native Android Homescreen Widget**: Interactive 2x2 homescreen widgets featuring direct quick log buttons (e.g. "+5 Push-ups") that sync instantly with the main application state.
- **Local & Privacy First**: Zero server connections, zero cloud databases, and zero tracking. 100% of your data remains securely on your physical device.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Material 3)
- **State Management**: `ChangeNotifier` & `ValueNotifier`
- **Persistence**: `shared_preferences` (fully local storage, automatic legacy keys cleanup on start)
- **Notifications**: `flutter_local_notifications`
- **Background Tasks**: `workmanager`
- **Native Integration**: `home_widget` (Kotlin Broadcast Receivers for interactive widget clicks)
- **Audio**: `audioplayers` (custom congratulations and selection alert sounds)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code with Flutter extension
- An Android or iOS device/emulator

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/eliasantony/workout_habit.git
   ```
2. Navigate to the project directory:
   ```bash
   cd workout_habit
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🏗️ Architecture

Workout Habit follows a simple, clean, and maintainable architecture:

- **Features**: Structured around clean domains (`workout` for core logging, `settings`, and `history`).
- **Controller Layer**: Uses `ChangeNotifier` to bridge widget states and local storage.
- **Storage Layer**: Implemented inside `WorkoutStorage` around `shared_preferences` with robust, defensive fallback parsing.
- **Native Sync**: Uses `HomeWidget` with custom Kotlin classes (`WorkoutWidgetProvider.kt`, `WidgetActionReceiver.kt`) to bind widget buttons directly to background callback logging.

For more technical details and guidelines, see [AGENTS.md](AGENTS.md).

---

## 🗺️ Roadmap

Check out [ROADMAP.md](ROADMAP.md) to see our detailed migration path and completed phases.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
