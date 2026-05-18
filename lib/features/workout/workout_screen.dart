import 'package:flutter/material.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_models.dart';
import 'package:workout_habit/features/settings/settings_screen.dart';
import 'package:workout_habit/features/workout/widgets/log_exercise_dialog.dart';

class WorkoutScreen extends StatefulWidget {
  final WorkoutController controller;

  const WorkoutScreen({super.key, required this.controller});

  static void showCelebrationDialog(
    BuildContext context,
    WorkoutController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(
          child: Text(
            'Goal Reached! 🥳',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Amazing work! You crushed your workout goal today. Keep up the streak!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Streak: ${controller.state.currentStreak} Days 🔥',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Heck Yeah!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshFromStorage();
    }
  }

  void _logExercise(int amount) {
    if (amount <= 0) return; // strict positive number check
    final oldProgress =
        widget.controller.state.currentWorkoutUnits /
        widget.controller.state.dailyWorkoutTargetUnits;

    widget.controller
        .logExercise(
          exercise: widget.controller.state.selectedExercise,
          amount: amount,
        )
        .then((_) {
          if (!mounted || !context.mounted) return;
          final newProgress =
              widget.controller.state.currentWorkoutUnits /
              widget.controller.state.dailyWorkoutTargetUnits;
          if (oldProgress < 1.0 && newProgress >= 1.0) {
            WorkoutScreen.showCelebrationDialog(context, widget.controller);
          }
        });
  }

  void _showCustomAddDialog() {
    showDialog(
      context: context,
      builder: (context) => LogExerciseDialog(
        exercise: widget.controller.state.selectedExercise,
        quickAddSmall: widget.controller.state.quickAddSmall,
        quickAddLarge: widget.controller.state.quickAddLarge,
        onAdd: (amount) {
          if (amount <= 0) return;
          final oldProgress =
              widget.controller.state.currentWorkoutUnits /
              widget.controller.state.dailyWorkoutTargetUnits;

          widget.controller
              .logExercise(
                exercise: widget.controller.state.selectedExercise,
                amount: amount,
              )
              .then((_) {
                if (!mounted || !context.mounted) return;
                final newProgress =
                    widget.controller.state.currentWorkoutUnits /
                    widget.controller.state.dailyWorkoutTargetUnits;
                if (oldProgress < 1.0 && newProgress >= 1.0) {
                  WorkoutScreen.showCelebrationDialog(
                    context,
                    widget.controller,
                  );
                }
              });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final state = widget.controller.state;
        final currentWorkoutUnits = state.currentWorkoutUnits;
        final dailyWorkoutTargetUnits = state.dailyWorkoutTargetUnits;
        final progress = (currentWorkoutUnits / dailyWorkoutTargetUnits).clamp(
          0.0,
          1.0,
        );
        final isGoalReached = currentWorkoutUnits >= dailyWorkoutTargetUnits;
        final selectedExercise = state.selectedExercise;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Workout Habit'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen(controller: widget.controller),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Identity Section (Mascot)
                  Center(
                    child: Column(
                      children: [
                        _WorkoutMascot(progress: progress),
                        const SizedBox(height: 12),
                        Text(
                          'One rep at a time. Big streaks.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Horizontal Exercise Selector
                  const Text(
                    'Select Exercise',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _ExerciseSelector(
                    selectedExercise: selectedExercise,
                    onSelected: (exercise) {
                      widget.controller.setSelectedExercise(exercise);
                    },
                  ),
                  const SizedBox(height: 28),

                  // Streak and Badges
                  if (state.currentStreak > 0) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _BadgeChip(
                          icon: '🔥',
                          label: '${state.currentStreak} Day Streak',
                          color: const Color(0xFFF97316),
                        ),
                        if (state.currentStreak >= 3)
                          const _BadgeChip(
                            icon: '💪',
                            label: '3 Day Habit',
                            color: Color(0xFF14B8A6),
                          ),
                        if (state.currentStreak >= 7)
                          const _BadgeChip(
                            icon: '🏆',
                            label: 'Perfect Week',
                            color: Color(0xFF14B8A6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (isGoalReached) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🏆', style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Text(
                              'Goal Reached!',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Circular Progress Indicator
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 230,
                          height: 230,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 18,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isGoalReached
                                  ? Colors.greenAccent
                                  : theme.colorScheme.primary,
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$currentWorkoutUnits',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            Text(
                              'of $dailyWorkoutTargetUnits ${selectedExercise.unit}',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Motivational text card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _getMotivationalText(
                                currentWorkoutUnits,
                                dailyWorkoutTargetUnits,
                                state.currentStreak,
                              ),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Log Buttons
                  const Text(
                    'Quick Log Today',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _QuickLogButton(
                        amount: 5,
                        unit: selectedExercise.unit,
                        onPressed: () => _logExercise(5),
                      ),
                      _QuickLogButton(
                        amount: 10,
                        unit: selectedExercise.unit,
                        onPressed: () => _logExercise(10),
                      ),
                      _QuickLogButton(
                        amount: 20,
                        unit: selectedExercise.unit,
                        onPressed: () => _logExercise(20),
                      ),
                      _CustomLogButton(onPressed: () => _showCustomAddDialog()),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for floating nav
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMotivationalText(int current, int goal, int streak) {
    if (current == 0) {
      return "Let's get moving! 💪 Select an exercise below to start.";
    }
    final percent = current / goal;
    if (percent >= 1.0) {
      if (streak > 0) {
        return "Goal reached! You're on a $streak-day streak! 🏆 Keep it up!";
      } else {
        return "Goal reached! Amazing work today! 🏆";
      }
    }
    if (percent >= 0.75) return "Almost there, finish strong! 🔥";
    if (percent >= 0.5) return "Halfway there, keep it up! 💪";
    if (percent >= 0.25) return "Nice start, you're on your way! 🔥";
    return "Every rep counts! 💪";
  }
}

class _WorkoutMascot extends StatelessWidget {
  final double progress;
  const _WorkoutMascot({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String emoji = '💪';
    String face = '•  •';

    if (progress == 0) {
      emoji = '😴';
      face = 'z Z';
    } else if (progress < 0.25) {
      emoji = '👟';
      face = '•  •';
    } else if (progress < 0.75) {
      emoji = '💪';
      face = '•  •';
    } else if (progress < 1.0) {
      emoji = '🔥';
      face = 'ᵔ  ᵔ';
    } else {
      emoji = '🥳';
      face = '♥  ♥';
    }

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          Positioned(
            bottom: 12,
            child: Text(
              face,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _BadgeChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseSelector extends StatelessWidget {
  final ExerciseType selectedExercise;
  final ValueChanged<ExerciseType> onSelected;

  const _ExerciseSelector({
    required this.selectedExercise,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ExerciseType.values.length,
        itemBuilder: (context, index) {
          final exercise = ExerciseType.values[index];
          final isSelected = exercise == selectedExercise;

          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == ExerciseType.values.length - 1 ? 0 : 0,
            ),
            child: InkWell(
              onTap: () => onSelected(exercise),
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 100,
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      exercise.icon,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                      size: 28,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exercise.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  final int amount;
  final String unit;
  final VoidCallback onPressed;

  const _QuickLogButton({
    required this.amount,
    required this.unit,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            '+$amount $unit',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _CustomLogButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CustomLogButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        side: BorderSide(color: theme.colorScheme.primaryContainer),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_rounded, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          const Text(
            'Custom',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
