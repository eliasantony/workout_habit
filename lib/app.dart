import 'package:flutter/material.dart';
import 'package:hydro_habit/theme/app_theme.dart';
import 'package:hydro_habit/main_screen.dart';
import 'package:hydro_habit/features/hydration/hydration_controller.dart';

class HydroHabitApp extends StatelessWidget {
  final HydrationController hydrationController;

  const HydroHabitApp({super.key, required this.hydrationController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: hydrationController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Hydro Habit',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: hydrationController.state.themeMode,
          home: MainScreen(controller: hydrationController),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

}
