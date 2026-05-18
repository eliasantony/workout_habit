# Hydro Habit 💧

Hydro Habit is a lightweight, premium Flutter application designed to help you stay hydrated throughout the day. Built with a focus on privacy and simplicity, it operates entirely locally with no cloud dependencies.

## ✨ Features

- **Intuitive Hydration Tracking**: Easily log your water intake with predefined amounts or custom values.
- **Dynamic Goals**: Set and adjust your daily hydration targets based on your needs.
- **Smart Reminders**: Customizable notification intervals to keep you on track.
- **Gamified Progress**: Earn streaks and watch your friendly Droplet mascot react to your progress.
- **Native Android Widgets**: Track your hydration and add water directly from your homescreen.
- **Detailed History**: Review your past performance with a calendar-based history view.
- **Premium Dark Mode**: A sleek, high-contrast dark theme inspired by modern design trends.
- **Local & Private**: No account required, no data leaves your device.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Material 3)
- **State Management**: `ChangeNotifier` & `ValueNotifier`
- **Persistence**: `shared_preferences`
- **Notifications**: `flutter_local_notifications`
- **Background Tasks**: `workmanager`
- **Native Integration**: `home_widget`
- **Audio**: `audioplayers`

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio / VS Code with Flutter extension
- An Android or iOS device/emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/eliasantony/water_reminder.git
   ```
2. Navigate to the project directory:
   ```bash
   cd water_reminder
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## 🏗️ Architecture

Hydro Habit follows a simple and maintainable architecture:

- **Features**: Organized by domain (hydration, settings, history).
- **Controller Layer**: Uses `ChangeNotifier` to bridge the UI and data layers.
- **Storage Layer**: Direct interaction with `shared_preferences` for fast local access.
- **Services**: Dedicated services for notifications and native widget synchronization.

For more technical details, see [AGENTS.md](AGENTS.md).

## 🗺️ Roadmap

Check out [ROADMAP.md](ROADMAP.md) to see our current progress and future plans.

## 📝 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed history of changes.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
