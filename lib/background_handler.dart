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
    debugPrint('HydroHabit: URI is null, skipping');
    return;
  }

  try {
    // Check if the URI is ours
    if (uri.scheme == 'home_widget' &&
        (uri.host == 'add_water' || uri.path.contains('add_water'))) {
      int? amount;

      // Try parsing from path first (e.g., home_widget://add_water/250)
      if (uri.pathSegments.isNotEmpty) {
        // If host is add_water, the first segment is the amount
        if (uri.host == 'add_water') {
          amount = int.tryParse(uri.pathSegments.first);
        } else {
          // If host is empty and path is /add_water/250
          final index = uri.pathSegments.indexOf('add_water');
          if (index >= 0 && index < uri.pathSegments.length - 1) {
            amount = int.tryParse(uri.pathSegments[index + 1]);
          }
        }
      }

      // Fallback to query parameters (e.g., ?amount=250)
      if (amount == null && uri.queryParameters.containsKey('amount')) {
        amount = int.tryParse(uri.queryParameters['amount']!);
      }

      debugPrint('HydroHabit: Resolved amount: $amount');

      if (amount != null && amount > 0) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload(); // Crucial to read updates from main app
        final storage = WorkoutStorage(prefs);
        final notificationService = NotificationService();
        await notificationService.init();

        final controller = WorkoutController(storage, notificationService);
        await controller.ready;
        await controller.addWater(amount);
        await prefs.setString(
          'bg_log',
          'SUCCESSFULLY ADDED $amount ml. URI: $uri',
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
