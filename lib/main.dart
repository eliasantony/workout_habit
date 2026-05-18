import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_habit/app.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_storage.dart';
import 'package:workout_habit/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Initialize bindings
      WidgetsFlutterBinding.ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final storage = WorkoutStorage(prefs);
      final notificationService = NotificationService();
      await notificationService.init();

      // Creating the controller triggers _init() -> _checkNewDay()
      // which handles resetting the day, updating the widget, and rescheduling notifications.
      final controller = WorkoutController(storage, notificationService);
      await controller.ready;

      debugPrint('WorkoutHabit: Background sync completed successfully');
      return Future.value(true);
    } catch (e) {
      debugPrint('WorkoutHabit: Background sync error: $e');
      return Future.value(false);
    }
  });
}

@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (response.actionId != null &&
      (response.actionId == 'add_small' ||
          response.actionId == 'add_large' ||
          response.actionId!.startsWith('log_'))) {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final storage = WorkoutStorage(prefs);
      final ns = NotificationService();
      await ns.init();

      int? amount;
      final actionId = response.actionId!;
      if (actionId == 'add_small') {
        amount = storage.getQuickAddSmallUnits();
      } else if (actionId == 'add_large') {
        amount = storage.getQuickAddLargeUnits();
      } else {
        final match = RegExp(r'log_(\d+)_units').firstMatch(actionId);
        if (match != null) {
          amount = int.tryParse(match.group(1) ?? '');
        }
      }

      // Ensure invalid action amounts cannot log zero or negative units
      if (amount != null && amount > 0) {
        final controller = WorkoutController(storage, ns);
        await controller.ready;
        await controller.logPreferredExercise(amount);

        final exercise = storage.getPreferredExercise();
        await ns.showBackgroundSuccess(
          amount,
          message: 'Logged $amount ${exercise.unit} of ${exercise.label}.',
        );
      }

      if (response.id != null) {
        await ns.cancelNotification(response.id!);
      }
    } catch (e) {
      debugPrint('Error handling background notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (uri == null) return;

  try {
    if (uri.scheme == 'home_widget' &&
        (uri.host == 'add_water' ||
            uri.path.contains('add_water') ||
            uri.host == 'log_exercise' ||
            uri.path.contains('log_exercise') ||
            uri.host == 'log_workout' ||
            uri.path.contains('log_workout'))) {
      int? amount;

      if (uri.pathSegments.isNotEmpty) {
        if (uri.host == 'add_water' ||
            uri.host == 'log_exercise' ||
            uri.host == 'log_workout') {
          amount = int.tryParse(uri.pathSegments.first);
        } else {
          final index = uri.pathSegments.indexWhere(
            (segment) =>
                segment == 'add_water' ||
                segment == 'log_exercise' ||
                segment == 'log_workout',
          );
          if (index >= 0 && index < uri.pathSegments.length - 1) {
            amount = int.tryParse(uri.pathSegments[index + 1]);
          }
        }
      }

      if (amount == null && uri.queryParameters.containsKey('amount')) {
        amount = int.tryParse(uri.queryParameters['amount']!);
      }

      if (amount != null && amount > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final storage = WorkoutStorage(prefs);
        final notificationService = NotificationService();
        await notificationService.init();

        final controller = WorkoutController(storage, notificationService);
        await controller.ready;
        await controller.logPreferredExercise(amount);
      }
    }
  } catch (e) {
    debugPrint('Background error: $e');
  }
}

void main() {
  runZonedGuarded(
    () async {
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

      // Keep splash screen visible while we initialize
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('WorkoutHabit FlutterError: ${details.exceptionAsString()}');
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        debugPrint('WorkoutHabit PlatformDispatcher Error: $error\n$stack');
        return true;
      };

      try {
        // Register background callback as early as possible
        await HomeWidget.registerInteractivityCallback(backgroundCallback);

        // Initialize WorkManager for periodic background sync
        await Workmanager().initialize(callbackDispatcher);

        // Register periodic task (every 3 hours)
        await Workmanager().registerPeriodicTask(
          "1", // Unique name
          "syncTask", // Task name
          frequency: const Duration(hours: 3),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );

        final notificationService = NotificationService();
        await notificationService.init(
          backgroundHandler: onNotificationActionBackground,
        );

        // We request permissions, but don't let a rejection/delay block the app
        notificationService.requestPermissions().timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );

        final prefs = await SharedPreferences.getInstance();
        final storage = WorkoutStorage(prefs);
        final workoutController = WorkoutController(
          storage,
          notificationService,
        );

        // Ensure controller is fully initialized before proceeding
        await workoutController.ready;

        // Check if we were launched from a widget (for foreground addition)
        final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
        if (launchUri != null) {
          debugPrint('WorkoutHabit: Launched from widget: $launchUri');
          backgroundCallback(launchUri);
        }

        runApp(WorkoutHabitApp(workoutController: workoutController));
      } catch (e, stack) {
        debugPrint('WorkoutHabit: Initialization error: $e\n$stack');
        // Fallback: try to run the app even if some services failed
        try {
          final prefs = await SharedPreferences.getInstance();
          final storage = WorkoutStorage(prefs);
          final notificationService =
              NotificationService(); // Might be uninitialized
          final workoutController = WorkoutController(
            storage,
            notificationService,
          );
          await workoutController.ready;
          runApp(WorkoutHabitApp(workoutController: workoutController));
        } catch (fallbackError) {
          debugPrint('WorkoutHabit: Fallback also failed: $fallbackError');
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Failed to start app.\n\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      } finally {
        // Always remove splash screen after a short delay to ensure UI is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          FlutterNativeSplash.remove();
        });
      }
    },
    (error, stack) {
      debugPrint('WorkoutHabit runZonedGuarded Error: $error\n$stack');
    },
  );
}
