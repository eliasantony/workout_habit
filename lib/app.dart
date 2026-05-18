import 'package:flutter/material.dart';
import 'package:workout_habit/theme/app_theme.dart';
import 'package:workout_habit/main_screen.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';

class WorkoutHabitApp extends StatelessWidget {
  final WorkoutController workoutController;

  const WorkoutHabitApp({super.key, required this.workoutController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workoutController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Workout Habit',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: workoutController.state.themeMode,
          home: MainScreen(controller: workoutController),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
