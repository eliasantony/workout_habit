import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:workout_habit/features/workout/workout_models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  static const List<String> _motivationalMessages = [
    "Time to work out! 🏋️‍♂️",
    "Small effort, big win.",
    "Workout check: complete a set of exercises.",
    "Keep your streak going, crush a workout!",
    "Your body will thank you. Get moving!",
  ];

  static const String actionIdSmall = 'add_small';
  static const String actionIdLarge = 'add_large';

  static const int maxReminderNotifications = 50;
  static const int maxReminderDaysToScan = 30;
  static const int maxEveningCheckNotifications = 7;
  static const int startEveningCheckId = 100;

  Future<void> init({
    DidReceiveBackgroundNotificationResponseCallback? backgroundHandler,
  }) async {
    try {
      tz.initializeTimeZones();

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('ic_stat_drop');

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
          // Handle foreground/tap actions if needed
          _handleNotificationAction(response);
        },
        onDidReceiveBackgroundNotificationResponse: backgroundHandler,
      );
      _initialized = true;
    } catch (e) {
      _initialized = false;
      debugPrint('HydroHabit: NotificationService init error: $e');
      rethrow;
    }
  }

  static void _handleNotificationAction(NotificationResponse response) {
    if (response.actionId == actionIdSmall ||
        response.actionId == actionIdLarge) {
      // In foreground, we might need a reference to the controller.
      // But for simplicity, we can let the app refresh its state.
      // Most of the time, the app is in background when notifications hit.
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool granted = false;

      // Request Android 13+ permission
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidImplementation != null) {
        final androidGranted = await androidImplementation
            .requestNotificationsPermission();
        granted = androidGranted ?? false;
        // Also request exact alarms if needed
        await androidImplementation.requestExactAlarmsPermission();
      }

      // Request iOS permissions
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
      debugPrint('HydroHabit: requestPermissions error: $e');
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
    try {
      // Cancel reminder IDs
      for (int i = 0; i < maxReminderNotifications; i++) {
        await _flutterLocalNotificationsPlugin.cancel(id: i);
      }

      // Always schedule/cancel evening check, even if standard reminders are disabled or goal is met
      await scheduleEveningCheck(state);

      if (!state.remindersEnabled) {
        return;
      }

      final goalReachedToday = state.currentWaterMl >= state.dailyGoalMl;

      // Parse start and end times
      final startParts = state.reminderStartTime.split(':');
      final endParts = state.reminderEndTime.split(':');

      final startHour = int.tryParse(startParts[0]) ?? 8;
      final startMin = int.tryParse(startParts[1]) ?? 0;

      final endHour = int.tryParse(endParts[0]) ?? 22;
      final endMin = int.tryParse(endParts[1]) ?? 0;

      final now = tz.TZDateTime.now(tz.local);

      int id = 0;
      int dayOffset = 0;
      int scheduledCount = 0;

      while (id < maxReminderNotifications &&
          dayOffset < maxReminderDaysToScan) {
        // limit day span to avoid infinite loop
        if (state.reminderIntervalMins <= 0) break;

        var startTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          startHour,
          startMin,
        ).add(Duration(days: dayOffset));

        var endTime = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          endHour,
          endMin,
        ).add(Duration(days: dayOffset));

        if (startTime.isAfter(endTime)) {
          endTime = endTime.add(const Duration(days: 1));
        }

        var scheduleTime = startTime;
        while (scheduleTime.isBefore(endTime) &&
            id < maxReminderNotifications) {
          bool isToday = dayOffset == 0;
          bool shouldSkip = false;

          if (scheduleTime.isBefore(now.add(const Duration(minutes: 1)))) {
            shouldSkip = true;
          } else if (isToday && goalReachedToday) {
            shouldSkip = true;
          }

          if (!shouldSkip) {
            final message =
                _motivationalMessages[id % _motivationalMessages.length];

            await _flutterLocalNotificationsPlugin.zonedSchedule(
              id: id,
              title: 'Workout Habit',
              body: message,
              scheduledDate: scheduleTime,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  'reminders_channel_${state.notificationSound}',
                  'Workout Reminders',
                  channelDescription: 'Reminders to work out',
                  importance: Importance.high,
                  priority: Priority.high,
                  sound: RawResourceAndroidNotificationSound(
                    state.notificationSound,
                  ),
                  largeIcon: const DrawableResourceAndroidBitmap('ic_mascot'),
                  actions: <AndroidNotificationAction>[
                    AndroidNotificationAction(
                      actionIdSmall,
                      'Log ${state.quickAddSmall} units',
                      showsUserInterface: false,
                    ),
                    AndroidNotificationAction(
                      actionIdLarge,
                      'Log ${state.quickAddLarge} units',
                      showsUserInterface: false,
                    ),
                  ],
                ),
                iOS: const DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
            scheduledCount++;
            id++;
          }

          scheduleTime = scheduleTime.add(
            Duration(minutes: state.reminderIntervalMins),
          );
        }
        dayOffset++;
      }
      debugPrint(
        'HydroHabit: Scheduled $scheduledCount reminders across $dayOffset days.',
      );
    } catch (e) {
      debugPrint('HydroHabit: Error scheduling reminders: $e');
    }
  }

  Future<void> scheduleEveningCheck(WorkoutState state) async {
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
      final goalReachedToday = state.currentWaterMl >= state.dailyGoalMl;

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
                'goal_check_channel_${state.notificationSound}',
                'Goal Check',
                channelDescription:
                    'Evening reminders if workout target is not met',
                importance: Importance.high,
                priority: Priority.high,
                sound: RawResourceAndroidNotificationSound(
                  state.notificationSound,
                ),
                largeIcon: const DrawableResourceAndroidBitmap('ic_mascot'),
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction(
                    actionIdSmall,
                    'Log ${state.quickAddSmall} units',
                    showsUserInterface: false,
                  ),
                  AndroidNotificationAction(
                    actionIdLarge,
                    'Log ${state.quickAddLarge} units',
                    showsUserInterface: false,
                  ),
                ],
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
          scheduledCount++;
        }
      }

      debugPrint(
        'HydroHabit: Scheduled $scheduledCount evening checks for the next $maxEveningCheckNotifications days.',
      );
    } catch (e) {
      debugPrint('HydroHabit: Error scheduling evening check: $e');
    }
  }

  Future<void> showInstantNotification({
    int? smallAmount,
    int? bigAmount,
    String? sound,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'test_channel_${sound ?? 'default'}',
      'Test Notifications',
      channelDescription: 'For testing notifications',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(sound ?? 'notification_sound'),
      largeIcon: const DrawableResourceAndroidBitmap('ic_mascot'),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionIdSmall,
          'Log Small',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          actionIdLarge,
          'Log Large',
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
    );
  }

  Future<void> showBackgroundSuccess(int amount, {String? message}) async {
    await _flutterLocalNotificationsPlugin.show(
      id: 888,
      title: 'Workout Logged! 💪',
      body: message ?? 'Successfully logged $amount units.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'hydro_habit_silent',
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

// onNotificationActionBackground moved to main.dart for better isolate resolution
