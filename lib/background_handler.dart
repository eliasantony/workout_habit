import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_storage.dart';
import 'package:workout_habit/services/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'dart:io';

@pragma('vm:entry-point')
Future<void> backgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();

  // SYNCHRONOUS LOGGING TO BYPASS METHOD CHANNELS
  try {
    // Assuming standard Android cache dir
    final logFile = File(
      '/data/data/com.example.hydrohabit.hydro_habit/cache/bg_debug_log.txt',
    );
    logFile.writeAsStringSync(
      'BACKGROUND CALLED with URI: $uri\n',
      mode: FileMode.append,
    );
  } catch (e) {
    debugPrint('Failed to write sync log: $e');
  }

  if (uri == null) {
    debugPrint('WorkoutHabit: URI is null, skipping');
    return;
  }

  try {
    // Check if the URI is ours
    if (uri.scheme == 'home_widget' &&
        (uri.host == 'add_water' ||
            uri.path.contains('add_water') ||
            uri.host == 'log_exercise' ||
            uri.path.contains('log_exercise') ||
            uri.host == 'log_workout' ||
            uri.path.contains('log_workout'))) {
      int? amount;

      // Try parsing from path first (e.g., home_widget://log_exercise/10)
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

      // Fallback to query parameters (e.g., ?amount=10)
      if (amount == null && uri.queryParameters.containsKey('amount')) {
        amount = int.tryParse(uri.queryParameters['amount']!);
      }

      debugPrint('WorkoutHabit: Resolved amount: $amount');

      if (amount != null && amount > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload(); // Crucial to read updates from main app
        final storage = WorkoutStorage(prefs);
        final notificationService = NotificationService();
        await notificationService.init();

        final controller = WorkoutController(storage, notificationService);
        await controller.ready;
        await controller.logPreferredExercise(amount);
        await prefs.setString(
          'bg_log',
          'SUCCESSFULLY ADDED $amount units. URI: $uri',
        );
      } else {
        final p = await SharedPreferences.getInstance();
        await p.setString('bg_error', 'Invalid amount, skipping. URI: $uri');
      }
    } else {
      final p = await SharedPreferences.getInstance();
      await p.setString('bg_error', 'URI does not match pattern: $uri');
    }
  } catch (e, stack) {
    final p = await SharedPreferences.getInstance();
    await p.setString('bg_error', 'CRITICAL ERROR: $e\n$stack');
  }
}
