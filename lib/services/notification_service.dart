import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workout_habit/features/workout/workout_models.dart';
import 'package:workout_habit/features/workout/workout_storage.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const List<String> _motivationalMessages = [
    "Time for a quick set 💪",
    "Keep your streak alive 🔥",
    "A few reps now beats zero!",
    "Consistency is key. Let's do this!",
    "Crush your daily target today!",
    "Small efforts lead to big results 🏆",
    "Time to get moving! 🏋️‍♂️",
  ];

  static const String actionIdSmall = 'add_small';
  static const String actionIdLarge = 'add_large';

  static const int maxReminderNotifications = 50;
  static const int maxEveningCheckNotifications = 7;
  static const int startEveningCheckId = 100;

  Future<void> init({
    DidReceiveBackgroundNotificationResponseCallback? backgroundHandler,
  }) async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_stat_gym');

      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          _handleNotificationAction(response);
        },
        onDidReceiveBackgroundNotificationResponse: backgroundHandler,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
      debugPrint('WorkoutHabit: NotificationService init error: $e');
      rethrow;
    }
  }

  static void _handleNotificationAction(NotificationResponse response) {
    if (response.actionId != null &&
        (response.actionId == actionIdSmall ||
            response.actionId == actionIdLarge ||
            response.actionId!.startsWith('log_'))) {
      // In foreground, we can let the app refresh its state.
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool granted = false;

      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final androidGranted = await androidImplementation
            .requestNotificationsPermission();
        granted = androidGranted ?? false;
        await androidImplementation.requestExactAlarmsPermission();
      }

      final iosImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosImplementation != null) {
        final iosGranted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        granted = granted || (iosGranted ?? false);
      }

      return granted;
    } catch (e) {
      debugPrint('WorkoutHabit: requestPermissions error: $e');
      return false;
    }
  }

  Future<void> cancelAll() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> scheduleReminders(WorkoutState state) async {
    if (!_initialized) {
      debugPrint(
        'WorkoutHabit: NotificationService not initialized. Skipping scheduleReminders.',
      );
      return;
    }
    try {
      // Cancel reminder IDs up to maxReminderNotifications
      for (int i = 0; i < maxReminderNotifications; i++) {
        await _flutterLocalNotificationsPlugin.cancel(id: i);
      }

      // Always schedule/cancel evening check, even if standard reminders are disabled or goal is met
      await scheduleEveningCheck(state);

      if (!state.remindersEnabled) {
        return;
      }

      // Daily Workout Reminder: scheduled once per day at state.reminderStartTime
      final startParts = state.reminderStartTime.split(':');
      final startHour = int.tryParse(startParts[0]) ?? 8;
      final startMin = int.tryParse(startParts[1]) ?? 0;

      final now = tz.TZDateTime.now(tz.local);
      int scheduledCount = 0;

      for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
        var scheduleTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          startHour,
          startMin,
        ).add(Duration(days: dayOffset));

        bool shouldSkip = false;
        // If today's reminder time has already passed, skip today's reminder
        if (scheduleTime.isBefore(now)) {
          shouldSkip = true;
        }

        if (!shouldSkip) {
          final message =
              _motivationalMessages[dayOffset % _motivationalMessages.length];

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id: dayOffset,
            title: 'Workout Habit 💪',
            body: message,
            scheduledDate: scheduleTime,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'workout_reminders_v2_${state.notificationSound}',
                'Workout Reminders',
                channelDescription: 'Daily reminders to do your workout',
                importance: Importance.high,
                priority: Priority.high,
                sound: state.notificationSound == 'default'
                    ? null
                    : RawResourceAndroidNotificationSound(
                        state.notificationSound,
                      ),
                largeIcon: const DrawableResourceAndroidBitmap('ic_stat_gym'),
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'log_${state.quickAddSmall}_units',
                    '+${state.quickAddSmall} ${state.preferredExercise.label}',
                    showsUserInterface: false,
                  ),
                  AndroidNotificationAction(
                    'log_${state.quickAddLarge}_units',
                    '+${state.quickAddLarge} ${state.preferredExercise.label}',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            payload: 'open_app',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledCount++;
        }
      }
      debugPrint(
        'WorkoutHabit: Scheduled $scheduledCount daily reminders across 7 days.',
      );
    } catch (e, stack) {
      debugPrint('WorkoutHabit: Error scheduling reminders: $e\n$stack');
    }
  }

  Future<void> scheduleEveningCheck(WorkoutState state) async {
    if (!_initialized) {
      debugPrint(
        'WorkoutHabit: NotificationService not initialized. Skipping scheduleEveningCheck.',
      );
      return;
    }
    try {
      // Always cancel first to avoid duplicate/stale ones
      for (int i = 0; i < maxEveningCheckNotifications; i++) {
        await _flutterLocalNotificationsPlugin.cancel(
          id: startEveningCheckId + i,
        );
      }

      // Only schedule if enabled
      if (!state.eveningCheckEnabled) {
        return;
      }

      final timeParts = state.eveningCheckTime.split(':');
      final hour = int.tryParse(timeParts[0]) ?? 21;
      final min = int.tryParse(timeParts[1]) ?? 0;

      final now = tz.TZDateTime.now(tz.local);
      final goalReachedToday =
          state.currentWorkoutUnits >= state.dailyWorkoutTargetUnits;

      int scheduledCount = 0;

      for (
        int dayOffset = 0;
        dayOffset < maxEveningCheckNotifications;
        dayOffset++
      ) {
        var scheduleTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          min,
        ).add(Duration(days: dayOffset));

        bool isToday = dayOffset == 0;
        bool shouldSkip = false;

        // If the time has already passed today OR goal reached today, skip today's check
        if (scheduleTime.isBefore(now)) {
          shouldSkip = true;
        } else if (isToday && goalReachedToday) {
          shouldSkip = true;
        }

        if (!shouldSkip) {
          await _flutterLocalNotificationsPlugin.zonedSchedule(
            id: startEveningCheckId + dayOffset,
            title: 'Daily Goal Check 💪',
            body:
                'You haven\'t reached your workout target yet! Do some exercises to finish strong.',
            scheduledDate: scheduleTime,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                'workout_goal_check_v2_${state.notificationSound}',
                'Goal Check',
                channelDescription:
                    'Evening reminders if workout target is not met',
                importance: Importance.high,
                priority: Priority.high,
                sound: state.notificationSound == 'default'
                    ? null
                    : RawResourceAndroidNotificationSound(
                        state.notificationSound,
                      ),
                largeIcon: const DrawableResourceAndroidBitmap('ic_stat_gym'),
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    'log_${state.quickAddSmall}_units',
                    '+${state.quickAddSmall} ${state.preferredExercise.label}',
                    showsUserInterface: false,
                  ),
                  AndroidNotificationAction(
                    'log_${state.quickAddLarge}_units',
                    '+${state.quickAddLarge} ${state.preferredExercise.label}',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            payload: 'open_app',
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledCount++;
        }
      }

      debugPrint(
        'WorkoutHabit: Scheduled $scheduledCount evening checks for the next $maxEveningCheckNotifications days.',
      );
    } catch (e) {
      debugPrint('WorkoutHabit: Error scheduling evening check: $e');
    }
  }

  Future<void> showInstantNotification({
    int? smallAmount,
    int? bigAmount,
    String? sound,
    ExerciseType? preferredExercise,
  }) async {
    int sAmount = smallAmount ?? 5;
    int bAmount = bigAmount ?? 10;
    ExerciseType exercise = preferredExercise ?? ExerciseType.pushUps;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storage = WorkoutStorage(prefs);
      sAmount = smallAmount ?? storage.getQuickAddSmallUnits();
      bAmount = bigAmount ?? storage.getQuickAddLargeUnits();
      exercise = preferredExercise ?? storage.getPreferredExercise();
    } catch (e) {
      debugPrint(
        'WorkoutHabit: Error loading preferences in showInstantNotification: $e',
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'test_workout_channel_v2_${sound ?? 'default'}',
      'Test Notifications',
      channelDescription: 'For testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: (sound == null || sound == 'default')
          ? null
          : RawResourceAndroidNotificationSound(sound),
      largeIcon: const DrawableResourceAndroidBitmap('ic_stat_gym'),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'log_${sAmount}_units',
          '+$sAmount ${exercise.label}',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'log_${bAmount}_units',
          '+$bAmount ${exercise.label}',
          showsUserInterface: false,
        ),
      ],
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      id: 999,
      title: 'Test Notification 💪',
      body: 'This is a test to verify notifications and actions work!',
      notificationDetails: notificationDetails,
      payload: 'open_app',
    );
  }

  Future<void> showBackgroundSuccess(int amount, {String? message}) async {
    await _flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'Workout Logged! 💪',
      body: message ?? 'Successfully logged $amount units.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_silent_v2',
          'Background Updates',
          importance: Importance.low,
          priority: Priority.low,
        ),
      ),
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}
