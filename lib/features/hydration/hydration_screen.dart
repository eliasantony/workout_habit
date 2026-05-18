import 'package:flutter/material.dart';
import 'package:hydro_habit/features/hydration/hydration_controller.dart';
import 'package:hydro_habit/features/settings/settings_screen.dart';

class HydrationScreen extends StatefulWidget {
  final HydrationController controller;

  const HydrationScreen({super.key, required this.controller});

  static void showCelebrationDialog(
      BuildContext context, HydrationController controller) {
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
            const Text(
              '🎉',
              style: TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            const Text(
              'Amazing work! Your body is hydrated and happy. Keep up the streak!',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Heck Yeah!'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> with WidgetsBindingObserver {
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

  void _addWater(int amount) {
    final oldProgress = widget.controller.state.currentWaterMl / widget.controller.state.dailyGoalMl;
    widget.controller.addWater(amount).then((_) {
      if (!mounted) return;
      final newProgress = widget.controller.state.currentWaterMl / widget.controller.state.dailyGoalMl;
      if (oldProgress < 1.0 && newProgress >= 1.0) {
        HydrationScreen.showCelebrationDialog(context, widget.controller);
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final theme = Theme.of(context);
        final state = widget.controller.state;
        final currentWaterMl = state.currentWaterMl;
        final dailyGoalMl = state.dailyGoalMl;
        final progress = (currentWaterMl / dailyGoalMl).clamp(0.0, 1.0);
        final isGoalReached = currentWaterMl >= dailyGoalMl;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hydro Habit'),
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
                  // App Identity Section
                  Center(
                    child: Column(
                      children: [
                        _DropletMascot(progress: progress),
                        const SizedBox(height: 12),
                        Text(
                          'Small sips. Big streaks.',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

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
                            icon: '🌊',
                            label: '3 Day Flow',
                            color: Color(0xFF0EA5E9),
                          ),
                        if (state.currentStreak >= 7)
                          const _BadgeChip(
                            icon: '🏆',
                            label: 'Perfect Week',
                            color: Color(0xFF14B8A6),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],

                  if (isGoalReached) ...[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                          width: 250,
                          height: 250,
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
                          width: 250,
                          height: 250,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 20,
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
                              '$currentWaterMl',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            Text(
                              'of $dailyGoalMl ml',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

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
                              _getMotivationalText(currentWaterMl, dailyGoalMl),
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

                  // Quick Add Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _WaterAddButton(
                          amount: state.quickAddSmall,
                          onPressed: () => _addWater(state.quickAddSmall),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _WaterAddButton(
                          amount: state.quickAddLarge,
                          onPressed: () => _addWater(state.quickAddLarge),
                        ),
                      ),
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

  String _getMotivationalText(int current, int goal) {
    if (current == 0) return "Let's start with one glass. 💧";
    final percent = current / goal;
    if (percent >= 1.0) return "Goal reached! Great job. 🏆";
    if (percent >= 0.75) return "Almost there, finish strong!";
    if (percent >= 0.5) return "Halfway hydrated, keep it up!";
    if (percent >= 0.25) return "Nice start, you're on your way.";
    return "Every sip counts! 💧";
  }
}

class _DropletMascot extends StatelessWidget {
  final double progress;
  const _DropletMascot({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String emoji = '💧';
    String face = '•  •';
    
    if (progress == 0) {
      emoji = '😴';
      face = 'z Z';
    } else if (progress < 0.25) {
      emoji = '🧊';
      face = '•  •';
    } else if (progress < 0.75) {
      emoji = '💧';
      face = '•  •';
    } else if (progress < 1.0) {
      emoji = '✨';
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

class _WaterAddButton extends StatelessWidget {
  final int amount;
  final VoidCallback onPressed;

  const _WaterAddButton({required this.amount, required this.onPressed});

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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, size: 28, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            '$amount ml',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}