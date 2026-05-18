import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_habit/features/workout/workout_controller.dart';
import 'package:workout_habit/features/workout/workout_models.dart';
import 'package:workout_habit/features/settings/settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  final WorkoutController controller;

  const HistoryScreen({super.key, required this.controller});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
  }

  String _determineLogsUnit(List<ExerciseLog> logs) {
    if (logs.isEmpty) {
      return 'units';
    }
    final units = logs
        .map((log) => ExerciseType.fromId(log.exerciseId).unit)
        .toSet();
    if (units.length == 1) {
      return units.first;
    } else {
      return 'units';
    }
  }

  String _determineDayUnit(DailyWorkoutHistory historyEntry) {
    return _determineLogsUnit(historyEntry.logs);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final state = widget.controller.state;

        // Calculate stats for the focused month
        final now = DateTime.now();
        final isFocusedMonthCurrent =
            _focusedMonth.year == now.year && _focusedMonth.month == now.month;

        final monthHistory = state.history.where((h) {
          final hDate = DateTime.parse(h.date);
          return hDate.year == _focusedMonth.year &&
              hDate.month == _focusedMonth.month;
        }).toList();

        // Include today in stats if it's the current month
        if (isFocusedMonthCurrent) {
          final dateKey =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          if (!monthHistory.any((h) => h.date == dateKey)) {
            monthHistory.add(
              DailyHistory(
                date: dateKey,
                completedUnits: state.currentWorkoutUnits,
                targetUnits: state.dailyWorkoutTargetUnits,
                goalReached:
                    state.currentWorkoutUnits >= state.dailyWorkoutTargetUnits,
                logs: state.todayLogs,
              ),
            );
          }
        }

        final goalsReached = monthHistory.where((h) => h.goalReached).length;
        final totalDaysWithData = monthHistory.length;
        final completionRate = totalDaysWithData > 0
            ? (goalsReached / totalDaysWithData * 100).round()
            : 0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('History'),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsCard(
                  goalsReached,
                  state.currentStreak,
                  completionRate,
                ),
                const SizedBox(height: 32),
                _buildCalendarHeader(),
                const SizedBox(height: 16),
                _buildCalendarGrid(state),
                const SizedBox(height: 100), // Space for floating nav
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(
    int monthGoals,
    int currentStreak,
    int completionRate,
  ) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Monthly',
              value: '$monthGoals',
              icon: Icons.emoji_events_rounded,
              color: Colors.amber,
            ),
            _StatItem(
              label: 'Streak',
              value: '$currentStreak',
              icon: Icons.local_fire_department_rounded,
              color: Colors.orange,
            ),
            _StatItem(
              label: 'Completion',
              value: '$completionRate%',
              icon: Icons.percent_rounded,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat('MMMM yyyy').format(_focusedMonth),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(
                () => _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(
                () => _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(WorkoutState state) {
    final theme = Theme.of(context);
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;
    final firstDayWeekday = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    ).weekday;

    // Adjust for Monday-start (Flutter/Dart default)
    final emptyLeadingDays = firstDayWeekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: emptyLeadingDays + daysInMonth,
      itemBuilder: (context, index) {
        if (index < emptyLeadingDays) return const SizedBox.shrink();

        final dayNum = index - emptyLeadingDays + 1;
        final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
        final dateKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        final now = DateTime.now();
        final isToday =
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
        final isFuture = date.isAfter(DateTime(now.year, now.month, now.day));

        // Find history for this day
        DailyWorkoutHistory? historyEntry;
        try {
          historyEntry = state.history.firstWhere((h) => h.date == dateKey);
        } catch (_) {
          historyEntry = null;
        }

        // Special case for today (not in history yet)
        bool reached = false;
        bool hasData = false;
        if (isToday) {
          reached = state.currentWorkoutUnits >= state.dailyWorkoutTargetUnits;
          hasData = state.currentWorkoutUnits > 0;
        } else if (historyEntry != null) {
          reached = historyEntry.goalReached;
          hasData = historyEntry.completedUnits > 0;
        }

        return InkWell(
          onTap: isFuture
              ? null
              : () => _showDaySummary(date, historyEntry, isToday, state),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: reached
                  ? theme.colorScheme.primary
                  : (hasData
                        ? theme.colorScheme.primaryContainer
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$dayNum',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: reached
                    ? theme.colorScheme.onPrimary
                    : (isFuture
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                          : theme.colorScheme.onSurface),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDaySummary(
    DateTime date,
    DailyWorkoutHistory? historyEntry,
    bool isToday,
    WorkoutState state,
  ) {
    int completed = 0;
    int target = state.dailyWorkoutTargetUnits;
    List<ExerciseLog> logs = [];

    if (isToday) {
      completed = state.currentWorkoutUnits;
      logs = state.todayLogs;
    } else if (historyEntry != null) {
      completed = historyEntry.completedUnits;
      target = historyEntry.targetUnits;
      logs = historyEntry.logs;
    }

    final dayUnit = historyEntry != null
        ? _determineDayUnit(historyEntry)
        : (isToday
              ? (logs.isEmpty ? 'units' : _determineLogsUnit(logs))
              : 'units');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow it to expand nicely
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final progress = target > 0
            ? (completed / target).clamp(0.0, 1.0)
            : 0.0;
        final isGoalReached = completed >= target;

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(date),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isToday ? "Today's Activity" : "Past Workout Summary",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Workout Target',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$completed / $target $dayUnit',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: progress,
                            minHeight: 12,
                            borderRadius: BorderRadius.circular(6),
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(height: 16),
                          if (isGoalReached)
                            Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Goal Reached! Awesome workout! 💪🔥',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${target - completed} $dayUnit remaining to hit target.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logs Section
                  Text(
                    'Exercise Logs',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (logs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.fitness_center_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No exercises logged for this day.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Consistency is key! Keep moving.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final type = ExerciseType.fromId(log.exerciseId);
                        final name =
                            log.exerciseId == 'custom' && log.customName != null
                            ? log.customName!
                            : type.label;
                        final unit = type.unit;
                        final formattedTime = DateFormat(
                          'h:mm a',
                        ).format(log.timestamp);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                type.icon,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(formattedTime),
                            trailing: Text(
                              '${log.amount} $unit',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
