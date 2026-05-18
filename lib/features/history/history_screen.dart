import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hydro_habit/features/hydration/hydration_controller.dart';
import 'package:hydro_habit/features/hydration/hydration_models.dart';
import 'package:hydro_habit/features/settings/settings_screen.dart';

class HistoryScreen extends StatefulWidget {
  final HydrationController controller;

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
            monthHistory.add(DailyHistory(
              date: dateKey,
              consumedMl: state.currentWaterMl,
              goalMl: state.dailyGoalMl,
              goalReached: state.currentWaterMl >= state.dailyGoalMl,
            ));
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

  Widget _buildCalendarGrid(dynamic state) {
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
        DailyHistory? historyEntry;
        try {
          historyEntry = state.history.firstWhere((h) => h.date == dateKey);
        } catch (_) {
          historyEntry = null;
        }

        // Special case for today (not in history yet)
        bool reached = false;
        bool hasData = false;
        if (isToday) {
          reached = state.currentWaterMl >= state.dailyGoalMl;
          hasData = state.currentWaterMl > 0;
        } else if (historyEntry != null) {
          reached = historyEntry.goalReached;
          hasData = true;
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
    dynamic history,
    bool isToday,
    dynamic state,
  ) {
    int consumed = 0;
    int goal = state.dailyGoalMl;
    if (isToday) {
      consumed = state.currentWaterMl;
    } else if (history != null) {
      consumed = history.consumedMl;
      goal = history.goalMl;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Intake', style: TextStyle(fontSize: 16)),
                Text(
                  '$consumed / $goal ml',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (consumed / goal).clamp(0.0, 1.0),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 24),
            if (consumed >= goal)
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Daily Goal Reached!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            else
              Text(
                '${goal - consumed} ml remaining',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
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
