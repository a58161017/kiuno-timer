import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/timer_list_provider.dart';
import '../../../domain/entities/timer_model.dart';
import '../../../domain/entities/timer_status.dart';
import '../screens/add_timer_page.dart';

/// A card widget that displays information about a single timer.
///
/// This widget has been updated to follow 2025 UI guidelines, including
/// larger touch targets, improved spacing, a progress indicator, and subtle
/// animations. It adapts colors from the current theme to ensure
/// accessibility and visual harmony.
class TimerCardWidget extends ConsumerWidget {
  final TimerModel timer;

  const TimerCardWidget({super.key, required this.timer});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;

    // Choose icon and color based on timer status.
    IconData statusIcon;
    Color statusColor;
    String displayedTime;

    if (timer.status == TimerStatus.pending || timer.status == TimerStatus.finished) {
      displayedTime = _formatDuration(timer.totalDuration);
    } else {
      displayedTime = _formatDuration(timer.remainingDuration);
    }

    switch (timer.status) {
      case TimerStatus.running:
        statusIcon = Icons.play_arrow;
        statusColor = colorScheme.primary;
        break;
      case TimerStatus.paused:
        statusIcon = Icons.pause;
        statusColor = colorScheme.secondary;
        break;
      case TimerStatus.finished:
        statusIcon = Icons.check_circle;
        statusColor = Colors.green;
        break;
      case TimerStatus.pending:
      default:
        statusIcon = Icons.hourglass_empty;
        statusColor = colorScheme.onSurface.withOpacity(0.6);
        break;
    }

    // Compute progress ratio for visual indicator.
    final int totalSeconds = timer.totalDuration.inSeconds;
    final int remainingSeconds = timer.remainingDuration.inSeconds;
    final double progress = totalSeconds == 0 ? 0.0 : (remainingSeconds / totalSeconds);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with name and actions.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    timer.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                  tooltip: 'Edit Timer',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddTimerPage(timerToEdit: timer),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  tooltip: 'Delete Timer',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: Text('Are you sure you want to delete "${timer.name}"?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('Cancel'),
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                              child: const Text('Delete'),
                              onPressed: () {
                                ref.read(timerListProvider.notifier).removeTimer(timer.id);
                                Navigator.of(dialogContext).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Animated time display for smooth updates.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                displayedTime,
                key: ValueKey<String>(displayedTime),
                style: textTheme.headlineMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  // Capitalize status name for display.
                  timer.status.name.substring(0, 1).toUpperCase() + timer.status.name.substring(1),
                  style: textTheme.labelLarge?.copyWith(color: statusColor),
                ),
                const Spacer(),
                _buildControlButtons(context, ref, timer, colorScheme),
              ],
            ),
            const SizedBox(height: 12),
            // Visual progress indicator. Inverts progress so that full bar means finished.
            LinearProgressIndicator(
              value: 1.0 - progress.clamp(0.0, 1.0),
              minHeight: 4.0,
              backgroundColor: colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds control buttons (play/pause/reset) based on timer state.
  Widget _buildControlButtons(
    BuildContext context,
    WidgetRef ref,
    TimerModel timer,
    ColorScheme colorScheme,
  ) {
    final notifier = ref.read(timerListProvider.notifier);
    final List<Widget> buttons = [];

    if (timer.isPending || timer.isPaused || timer.isFinished) {
      buttons.add(
        Tooltip(
          message: timer.isPaused ? 'Resume' : 'Start',
          child: IconButton(
            icon: Icon(
              timer.isFinished || (timer.isPending && timer.remainingDuration == timer.totalDuration)
                  ? Icons.play_arrow
                  : Icons.play_circle_outline,
              color: colorScheme.primary,
            ),
            onPressed: () => notifier.startTimer(timer.id),
          ),
        ),
      );
    }

    if (timer.isRunning) {
      buttons.add(
        Tooltip(
          message: 'Pause',
          child: IconButton(
            icon: Icon(Icons.pause, color: colorScheme.secondary),
            onPressed: () => notifier.pauseTimer(timer.id),
          ),
        ),
      );
    }

    if (!timer.isPending || timer.remainingDuration < timer.totalDuration) {
      buttons.add(
        Tooltip(
          message: 'Reset',
          child: IconButton(
            icon: Icon(Icons.refresh, color: colorScheme.onSurface.withOpacity(0.7)),
            onPressed: () => notifier.resetTimer(timer.id),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    return buttons.length == 1
        ? buttons.first
        : Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}