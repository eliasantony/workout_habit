# AGENTS

Welcome to the Hydro Habit project! This document provides context for future AI agents working on this repository.

## Project Goal
Hydro Habit is a small, lightweight Flutter app that reminds the user to drink water throughout the day. It operates locally without any backend, Firebase, or cloud sync. 

## Architectural Guidelines
- **State Management:** Use `ChangeNotifier` / `ValueNotifier` for local state. The app must remain lightweight.
- **Persistence:** Use `shared_preferences` for storing settings, the daily goal, and today's consumed water amount.
- **UI/UX:** Material 3 with a clean, hydration-inspired theme (calm blues, rounded cards, subtle gradients). The design should not look like default Flutter.
- **Notifications:** Local notifications via `flutter_local_notifications` scheduled using `timezone`. No server push notifications.
- **Units:** Metric units only (ml).

## Important Constraints
- Keep it simple and maintainable.
- Do not over-engineer.
- Always check `ROADMAP.md` to understand where we are in the development lifecycle.
- Update `CHANGELOG.md` after any meaningful implementation step.
- Update `AGENTS.md` if the architectural approach changes significantly.

## How to Work
1. Look at the `ROADMAP.md` and `CHANGELOG.md` to get up to speed.
2. Read the source code in `lib/` to understand the current implementation.
3. Discuss any architectural changes before making them.
4. Add small, focused features and verify them.
