import 'package:flutter/material.dart';
import 'package:workout_habit/features/history/history_screen.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_screen.dart';
import 'package:workout_habit/features/workout/widgets/log_exercise_dialog.dart';

class MainScreen extends StatefulWidget {
  final WorkoutController controller;

  const MainScreen({super.key, required this.controller});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      WorkoutScreen(controller: widget.controller),
      HistoryScreen(controller: widget.controller),
    ];
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LogExerciseDialog(
        quickAddSmall: widget.controller.state.quickAddSmall,
        quickAddLarge: widget.controller.state.quickAddLarge,
        onAdd: (amount) async {
          final oldProgress =
              widget.controller.state.currentWaterMl /
              widget.controller.state.dailyGoalMl;

          final navigator = Navigator.of(context);

          await widget.controller.addWater(amount);

          if (!mounted) return;

          final newProgress =
              widget.controller.state.currentWaterMl /
              widget.controller.state.dailyGoalMl;
          if (oldProgress < 1.0 && newProgress >= 1.0) {
            if (!context.mounted) return;
            WorkoutScreen.showCelebrationDialog(context, widget.controller);
          }
          navigator.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: _FloatingBottomBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        onAddTap: () => _showAddDialog(context),
      ),
    );
  }
}

class _FloatingBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap;

  const _FloatingBottomBar({
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Center(
                  child: _BottomBarItem(
                    icon: Icons.water_drop_rounded,
                    label: 'Home',
                    isSelected: currentIndex == 0,
                    onTap: () => onTap(0),
                  ),
                ),
              ),
              _CenterAddButton(onTap: onAddTap),
              Expanded(
                child: Center(
                  child: _BottomBarItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'History',
                    isSelected: currentIndex == 1,
                    onTap: () => onTap(1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected ? theme.colorScheme.primary : Colors.grey[400];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(36),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CenterAddButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CenterAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}
