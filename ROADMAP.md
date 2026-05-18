# ROADMAP

This document outlines the phases of the Hydro Habit project.

## Phase 1: Foundation and UI [Done]
- [x] Create Flutter project
- [x] Define architecture guidelines
- [x] Implement `AppTheme`
- [x] Create `HydrationScreen` UI with dummy state

## Phase 2: Local Persistence and State Management [Done]
- [x] Implement `HydrationStorage` using `shared_preferences`
- [x] Implement `HydrationController` (`ChangeNotifier`)
- [x] Connect `HydrationScreen` to `HydrationController`

## Phase 3: Settings [Done]
- [x] Implement `SettingsScreen`
- [x] Allow customizing daily goal
- [x] Allow customizing reminder intervals

## Phase 4: Notifications [Done]
- [x] Implement `NotificationService`
- [x] Handle iOS / Android permissions
- [x] Schedule local notifications based on interval settings

## Phase 5: Gamification [Done]
- [x] Add streak tracking logic
- [x] Display daily summary / motivational cards

## Phase 6: Brand Identity & History [Done]
- [x] UI fixes (Progress indicator, Status bar icons)
- [x] Brand identity (Refined color palette, mascot, typography)
- [x] Floating navigation (Modern pill-shaped bar)
- [x] History/calendar screen (Local history storage, monthly grid)
- [x] Lightweight gamification (Badge chips, weekly progress)
- [x] Widget data preparation (Data model and service for future widget)
- [x] Verification (Tests and manual validation)

## Phase 7: Native Homescreen Widgets [Done]
- [x] Implement native Android widgets (2x2 Square and 4x1 Bar)
- [x] Integrate with `home_widget` package
- [x] Fix release build stability and notification persistence
- [ ] Implement native iOS widgets (Future)

## Phase 8: Advanced Gamification & Engagement [Done]
- [x] Evening Goal Check notifications
- [x] Expressive Mascot (Droplet) reactions
- [x] Goal celebration UI

## Phase 9: Customization & Polish [Done]
- [x] Full Dark Mode Support (App & Android Widgets)
- [x] Theme Customization (Light, Dark, System)
- [x] Refined UI Aesthetics: Pixel Weather-inspired dark theme and high-contrast typography.
