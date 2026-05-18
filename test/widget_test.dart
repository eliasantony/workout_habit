import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hydro_habit/app.dart';
import 'package:hydro_habit/features/hydration/hydration_controller.dart';
import 'package:hydro_habit/features/hydration/hydration_storage.dart';
import 'package:hydro_habit/services/notification_service.dart';

void main() {
  testWidgets('Hydration screen smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = HydrationStorage(prefs);

    // We mock NotificationService slightly or just use the real one since it handles uninitialized state gracefully (or rather init is needed)
    // Actually, initializing it in tests might crash if not mocked properly, but let's just pass an instance.
    final notificationService = NotificationService();
    final controller = HydrationController(storage, notificationService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(HydroHabitApp(hydrationController: controller));

    // Verify that the title and some text are present.
    expect(find.text('Hydro Habit'), findsAtLeast(1)); // Title in AppBar and possibly elsewhere
    expect(find.text('0'), findsOneWidget);
    expect(find.text('of 2500 ml'), findsOneWidget);
    expect(find.text("Let's start with one glass. 💧"), findsOneWidget);

    // Verify the add buttons are present.
    expect(find.text('250 ml'), findsOneWidget);
    expect(find.text('500 ml'), findsOneWidget);
  });
}
