import 'package:flutter/material.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_models.dart';
import 'package:workout_habit/services/notification_service.dart';
import 'package:audioplayers/audioplayers.dart';

class SettingsScreen extends StatefulWidget {
  final WorkoutController controller;

  const SettingsScreen({super.key, required this.controller});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _pendingCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  late TextEditingController _goalController;
  late TextEditingController _smallAddController;
  late TextEditingController _largeAddController;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
    _goalController = TextEditingController(
      text: widget.controller.state.dailyWorkoutTargetUnits.toString(),
    );
    _smallAddController = TextEditingController(
      text: widget.controller.state.quickAddSmall.toString(),
    );
    _largeAddController = TextEditingController(
      text: widget.controller.state.quickAddLarge.toString(),
    );
  }

  Future<void> _loadPendingCount() async {
    try {
      final pending = await NotificationService().getPendingNotifications();
      if (mounted) {
        setState(() {
          _pendingCount = pending.length;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load reminders: $e')));
      }
    }
  }

  @override
  void dispose() {
    _goalController.dispose();
    _smallAddController.dispose();
    _largeAddController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _saveGoal() {
    final newGoal = int.tryParse(_goalController.text);
    if (newGoal != null && newGoal > 0) {
      widget.controller.updateDailyWorkoutTargetUnits(newGoal);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily workout target updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target (> 0)')),
      );
    }
  }

  void _saveQuickAdd() {
    final small = int.tryParse(_smallAddController.text);
    final large = int.tryParse(_largeAddController.text);
    if (small != null && small > 0 && large != null && large > 0) {
      widget.controller.updateQuickAddSmallUnits(small);
      widget.controller.updateQuickAddLargeUnits(large);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quick log presets updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid positive numbers (> 0)'),
        ),
      );
    }
  }

  void _resetWorkoutProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Today?'),
        content: const Text(
          'Are you sure you want to reset your workout progress for today?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.controller.resetToday();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Today\'s progress reset')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final state = widget.controller.state;
    final currentTimeString = isStart
        ? state.reminderStartTime
        : state.reminderEndTime;

    final parts = currentTimeString.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      if (isStart) {
        widget.controller.updateReminderTimeRange(
          formattedTime,
          state.reminderEndTime,
        );
      } else {
        widget.controller.updateReminderTimeRange(
          state.reminderStartTime,
          formattedTime,
        );
      }
    }
  }

  Future<void> _selectEveningTime(BuildContext context) async {
    final state = widget.controller.state;
    final currentTimeString = state.eveningCheckTime;

    final parts = currentTimeString.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 21,
      minute: int.tryParse(parts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      widget.controller.updateEveningCheckTime(formattedTime);
    }
  }

  Future<void> _playPreview(String soundName) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/$soundName.mp3'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not play preview: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, child) {
          final state = widget.controller.state;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
            children: [
              const _SectionHeader(
                title: 'Appearance',
                icon: Icons.palette_outlined,
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Theme Mode'),
                      subtitle: const Text('Choose how Workout Habit looks'),
                      trailing: SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded),
                          ),
                        ],
                        selected: {state.themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          widget.controller.updateThemeMode(selection.first);
                        },
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader(
                title: 'Preferred Exercise',
                icon: Icons.star_rounded,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose your preferred exercise. The Android homescreen widget quick log buttons (+5 and +10) will log this exercise.',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ExerciseType>(
                        initialValue: state.preferredExercise,
                        decoration: InputDecoration(
                          labelText: 'Preferred Exercise',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                        items: ExerciseType.values.map((type) {
                          return DropdownMenuItem<ExerciseType>(
                            value: type,
                            child: Row(
                              children: [
                                Icon(
                                  type.icon,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(type.label),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (ExerciseType? newValue) {
                          if (newValue != null) {
                            widget.controller.setPreferredExercise(newValue);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Preferred exercise updated to ${newValue.label}',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader(
                title: 'Daily Workout Target',
                icon: Icons.fitness_center_rounded,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What is your daily target?',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _goalController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                suffixText: state.preferredExercise.unit,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _saveGoal,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader(
                title: 'Quick Log Buttons',
                icon: Icons.add_circle_outline_rounded,
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _smallAddController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Small Preset',
                                suffixText: state.preferredExercise.unit,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _largeAddController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Large Preset',
                                suffixText: state.preferredExercise.unit,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _saveQuickAdd,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Update Presets'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const _SectionHeader(
                title: 'Workout Reminders',
                icon: Icons.notifications_active_outlined,
              ),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Workout Reminders'),
                      subtitle: const Text(
                        'Get reminders to work out throughout the day',
                      ),
                      value: state.remindersEnabled,
                      onChanged: (value) {
                        widget.controller.updateRemindersEnabled(value);
                      },
                    ),
                    if (state.remindersEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text('Reminder Interval'),
                        trailing: DropdownButton<int>(
                          value: state.reminderIntervalMins,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(value: 60, child: Text('1 hour')),
                            DropdownMenuItem(
                              value: 90,
                              child: Text('1.5 hours'),
                            ),
                            DropdownMenuItem(
                              value: 120,
                              child: Text('2 hours'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              widget.controller.updateReminderInterval(value);
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text('Active From'),
                        trailing: TextButton(
                          onPressed: () => _selectTime(context, true),
                          child: Text(state.reminderStartTime),
                        ),
                      ),
                      ListTile(
                        title: const Text('Active Until'),
                        trailing: TextButton(
                          onPressed: () => _selectTime(context, false),
                          child: Text(state.reminderEndTime),
                        ),
                      ),
                    ],
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    SwitchListTile(
                      title: const Text('Evening Workout Check'),
                      subtitle: const Text(
                        'Notify if workout target is not met by evening',
                      ),
                      value: state.eveningCheckEnabled,
                      onChanged: (value) {
                        widget.controller.updateEveningCheckEnabled(value);
                      },
                    ),
                    if (state.eveningCheckEnabled)
                      ListTile(
                        title: const Text('Check Time'),
                        trailing: TextButton(
                          onPressed: () => _selectEveningTime(context),
                          child: Text(state.eveningCheckTime),
                        ),
                      ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text('Notification Sound'),
                      subtitle: const Text('Choose your reminder sound'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded),
                            color: Theme.of(context).colorScheme.primary,
                            onPressed: () =>
                                _playPreview(state.notificationSound),
                            tooltip: 'Preview current sound',
                          ),
                          DropdownButton<String>(
                            value: state.notificationSound,
                            underline: const SizedBox(),
                            items: const [
                              DropdownMenuItem(
                                value: 'notification_sound',
                                child: Text('Default'),
                              ),
                              DropdownMenuItem(
                                value: 'notification_sound_1',
                                child: Text('Sound 1'),
                              ),
                              DropdownMenuItem(
                                value: 'notification_sound_2',
                                child: Text('Sound 2'),
                              ),
                              DropdownMenuItem(
                                value: 'notification_sound_3',
                                child: Text('Sound 3'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                widget.controller.updateNotificationSound(
                                  value,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text('Test Notification'),
                      subtitle: const Text('Send an immediate reminder now'),
                      trailing: const Icon(Icons.notifications_active_outlined),
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        try {
                          final ns = NotificationService();
                          if (!ns.isInitialized) {
                            await ns.init();
                          }
                          await ns.showInstantNotification(
                            sound: state.notificationSound,
                          );
                          _loadPendingCount();

                          if (!mounted) return;

                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Notification error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text('Scheduled Reminders'),
                      subtitle: Text(
                        '$_pendingCount reminders currently active',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadPendingCount,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const _SectionHeader(
                title: 'Danger Zone',
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              Card(
                color: Colors.red.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
                ),
                child: ListTile(
                  onTap: _resetWorkoutProgress,
                  leading: const Icon(Icons.refresh_rounded, color: Colors.red),
                  title: const Text(
                    'Reset Today\'s Progress',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: const Text(
                    'This will clear all workout logs for today',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? color;

  const _SectionHeader({required this.title, required this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final finalColor = color ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: finalColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: finalColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
