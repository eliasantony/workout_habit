# Changelog

All notable changes to this project will be documented in this file.

## [2.9.1] - 2026-05-15
### Added
- Comprehensive `README.md` with project overview, features, tech stack, and mockups.
- Project `LICENSE` (MIT).

## [2.9.0] - 2026-05-15
### Fixed
- Notification Persistence: Fixed a major issue where notifications wouldn't start on a new day if the app wasn't opened.
- Reminder Rescheduling: Refactored the notification engine to pre-schedule all reminder slots for the following day as recurring notifications.
- Goal Reach Transitions: Notifications now correctly schedule for tomorrow even after the daily goal is reached today, ensuring they resume automatically at the start of the next day.

## [2.8.0] - 2026-05-11
### Fixed
- Background Sync & Notification Rescheduling: Added WorkManager to periodically check for a "new day" and update the home screen widget and notifications even if the app is closed.
- Widget Stale State: Resolved an issue where the widget would show the previous day's data until the app was manually opened.
- Added support for opening the app by clicking on the home screen widget (excluding action buttons).
- Cleaned up analyzer issues and optimized production build stability.

## [2.7.0] - 2026-05-08
### Added
- Notification Sound Selection: Users can now choose from multiple reminder sounds in the settings.
- Customizable Alerts: Support for multiple audio assets (`notification_sound_1` through `3`) alongside the default chime.
- Live Test Option: Added the ability to preview selected sounds directly from the settings menu via the test notification button.

## [2.6.0] - 2026-05-08
### Fixed
- Notification Action Sync: Fixed a bug where adding water via notification buttons bypassed the app's main logic, causing streaks to not update and reminders to persist.
- Evening Reminder: Resolved an issue where evening reminders would fire even after hitting the daily goal.
- Streak Tracking: Fixed several edge cases in streak calculations, ensuring streaks are awarded correctly when adding water or adjusting goals.
- History Stats Accuracy: Updated the history screen to include today's progress in the monthly completion statistics.

### Added
- Goal Celebration UI: Added a celebratory "Goal Reached" badge and visual indicator to the main screen when hitting the daily target.

## [2.5.0] - 2026-05-08
### Added
- Redesigned Water Dialog: Replaced simple numeric input with an intuitive selection of predefined amounts (100ml, Small, Large, 1 Liter) with distinct icons.
- Unified Experience: The new selection dialog is now consistent across both the center action button and the hydration screen shortcut.
- Animated Transitions: Smoothly toggle between predefined selections and custom numeric input.

## [2.4.0] - 2026-05-07
### Added
- Dark Mode Support: The entire app now supports Light, Dark, and System theme modes.
- Native Widget Dark Mode: HomeScreen widgets now automatically adapt to the system's light/dark theme.
- Appearance Settings: New section in settings to toggle the app's theme preference.
- Widened Quick Add buttons for better reachability and a more modern layout.

### Changed
- Improved Dark Mode aesthetics and readability: Shifted to a Pixel Weather-inspired palette with deep charcoal/black surfaces and vibrant blue accents.
- Fixed unreadable gray and black text in `HydrationScreen` and `HistoryScreen` by replacing hardcoded colors with theme-aware tokens.
- Resolved a build error in `HistoryScreen` caused by an undefined theme variable.
- Updated native Android widget colors to align with the new high-contrast dark theme.


## [2.3.0] - 2026-05-07
### Added
- Evening Goal Check: New notification setting to remind users if they haven't met their goal by a specific time.
- Expressive Droplet Mascot: The mascot now reacts to hydration progress with different emojis and facial expressions.
- Celebration UI: A new celebratory dialog appears when the daily goal is reached, showing the current streak and encouraging the user.
- New notification channel for Goal Checks.

### Changed
- Refined Settings screen with additional controls for Evening Goal Check.
- Updated NotificationService to handle conditional evening reminders.

## [2.2.0] - 2026-05-07
### Changed
- Visually improved the 2x2 HomeScreen widget with larger interaction buttons and enhanced typography.
- Refined widget button background with better corner radius and subtle border for a more premium feel.
- Increased header text sizes on the square widget for better readability at a glance.

## [2.1.0] - 2026-05-07
### Fixed
- Fixed app hang on splash screen in release builds by adding ProGuard rules and improving startup robustness.
- Fixed "vanishing notifications" issue by optimizing reminder rescheduling logic.
- Improved splash screen management with `flutter_native_splash`.
- Added try-catch blocks to critical initialization paths.

## [2.0.0] - 2026-05-07
### Added
- App Icon and Splash Screen featuring the `DropletMascot`.
- "Danger Zone" in Settings for sensitive operations.
- Interactive Notification Actions to add water intake directly from reminders.
- "Test Notification" button in Hydration Screen for quick debugging.

## [1.3.0] - 2026-05-07
### Added
- App Icon and Splash Screen featuring the `DropletMascot`.
- "Danger Zone" in Settings for sensitive operations.
- Interactive Notification Actions to add water intake directly from reminders.
- "Test Notification" button in Hydration Screen for quick debugging.

### Fixed
- Reminders not scheduling correctly on app startup.
- Notifications using the wrong icon resource (fixed with silhouette status bar icon).
- Interactive notification buttons not triggering in the background.
- Custom notification sound not playing on modern Android versions.

### Changed
- Moved "Reset Today" button from the main screen to Settings for a cleaner UI.
- Improved Settings screen with a modern, sectioned layout and descriptive icons.
- Updated Android application label to "Hydro Habit".

## [1.0.0] - 2024-05-06
- Initialized new Flutter project `hydro_habit`.
- Added initial documentation (`AGENTS.md`, `ROADMAP.md`, `CHANGELOG.md`).
- Implemented core file structure and Material 3 `AppTheme`.
- Created `HydrationScreen` UI with dummy state (Phase 1 complete).
- Implemented local state management and persistence using `shared_preferences` and `ChangeNotifier`.
- Connected `HydrationScreen` to `HydrationController` (Phase 2 complete).
- Implemented `SettingsScreen` to configure daily goal and reminder preferences.
- Updated `HydrationModels`, `HydrationStorage`, and `HydrationController` to handle settings (Phase 3 complete).
- Implemented `NotificationService` with `flutter_local_notifications` and `timezone` to schedule local reminders.
- Handled iOS and Android 13+ notification permissions gracefully (Phase 4 complete).
- Implemented gamification logic: streak tracking, persistent goals, and dynamic motivational text in `HydrationScreen` (Phase 5 complete).

## [1.2.0] - 2026-05-06
### Added
- Native Android Homescreen Widgets (2x2 Square and 4x1 Bar).
- Quick Add buttons (+250ml, +500ml) directly from the widget.
- Real-time data sync between App and Widgets using `home_widget`.
- Prepared iOS WidgetKit implementation (requires manual setup).

## [1.1.0] - 2026-05-06
- Enhanced brand identity with refined color palette and " Droplet\ mascot.
- Implemented modern floating bottom navigation bar.
- Added local history storage and History screen with monthly calendar grid.
- Improved gamification with badge chips (3 Day Flow, Perfect Week) and weekly progress card.
- Fixed UI issues: circular progress indicator visibility and status bar icon colors.
- Prepared data models for future homescreen widget implementation.
- Integrated intl package for date formatting in history.
