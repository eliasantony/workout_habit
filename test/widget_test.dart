import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:workout_habit/app.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_storage.dart';
import 'package:workout_habit/services/notification_service.dart';

void main() {
  testWidgets('Workout Habit screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = WorkoutStorage(prefs);

    // We mock NotificationService slightly or just use the real one since it handles uninitialized state gracefully (or rather init is needed)
    // Actually, initializing it in tests might crash if not mocked properly, but let's just pass an instance.
    final notificationService = NotificationService();
    final controller = WorkoutController(storage, notificationService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(WorkoutHabitApp(workoutController: controller));

    // Verify that the title and some text are present.
    expect(
      find.text('Workout Habit'),
      findsAtLeast(1),
    ); // Title in AppBar and possibly elsewhere
    expect(find.text('0'), findsOneWidget);
    expect(find.text('of 50 reps'), findsOneWidget);
    expect(
      find.text("Let's get moving! 💪 Select an exercise below to start."),
      findsOneWidget,
    );

    // Verify the add buttons are present.
    expect(find.text('+5 reps'), findsOneWidget);
    expect(find.text('+10 reps'), findsOneWidget);
  });
}
