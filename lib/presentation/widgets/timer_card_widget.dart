import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.surface, colorScheme.surfaceVariant.withOpacity(0.8)],
          ),
          boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 16))],
          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4), width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            timer.name,
                            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: statusColor, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusLabel(timer.status, l10n),
                                    style: textTheme.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        _ActionIconButton(
                          icon: Icons.edit,
                          tooltip: l10n.editTimerTooltip,
                          color: colorScheme.primary,
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddTimerPage(timerToEdit: timer)));
                          },
                        ),
                        const SizedBox(height: 12),
                        _ActionIconButton(
                          icon: Icons.delete_outline,
                          tooltip: l10n.deleteTimerTooltip,
                          color: colorScheme.error,
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: Text(l10n.deleteTimerTitle),
                                  content: Text(l10n.deleteTimerMessage(timer.name)),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(l10n.cancelButton),
                                      onPressed: () {
                                        Navigator.of(dialogContext).pop();
                                      },
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                      child: Text(l10n.deleteButton),
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
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    displayedTime,
                    key: ValueKey<String>(displayedTime),
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        timer.alertUntilStopped
                            ? l10n.alertUntilStoppedLabel
                            : l10n.singleAlertLabel,
                        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                    _buildControlButtons(context, ref, timer, colorScheme, l10n),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: 1.0 - progress.clamp(0.0, 1.0),
                    minHeight: 6.0,
                    backgroundColor: colorScheme.surfaceVariant.withOpacity(0.6),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
              ],
            ),
          ),
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
    AppLocalizations l10n,
  ) {
    final notifier = ref.read(timerListProvider.notifier);
    final List<Widget> buttons = [];

    if (timer.isPending || timer.isPaused) {
      buttons.add(
        Tooltip(
          message: timer.isPaused ? l10n.resumeAction : l10n.startAction,
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
          message: l10n.pauseAction,
          child: IconButton(
            icon: Icon(Icons.pause, color: colorScheme.secondary),
            onPressed: () => notifier.pauseTimer(timer.id),
          ),
        ),
      );
    }

    if (!timer.isPending || timer.remainingDuration < timer.totalDuration) {
      if (timer.alertUntilStopped && timer.remainingDuration.inMilliseconds == 0) {
        buttons.add(
          Tooltip(
            message: l10n.stopAction,
            child: IconButton(icon: Icon(Icons.stop, color: colorScheme.error), onPressed: () => notifier.resetTimer(timer.id)),
          ),
        );
      } else {
        buttons.add(
          Tooltip(
            message: l10n.resetAction,
            child: IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => notifier.resetTimer(timer.id),
            ),
          ),
        );
      }
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    return buttons.length == 1 ? buttons.first : Wrap(spacing: 4, children: buttons);
  }

  String _statusLabel(TimerStatus status, AppLocalizations l10n) {
    switch (status) {
      case TimerStatus.pending:
        return l10n.timerStatusPending;
      case TimerStatus.running:
        return l10n.timerStatusRunning;
      case TimerStatus.paused:
        return l10n.timerStatusPaused;
      case TimerStatus.finished:
        return l10n.timerStatusFinished;
      case TimerStatus.alerting:
        return l10n.timerStatusAlerting;
    }
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({required this.icon, required this.tooltip, required this.color, required this.onTap});

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        radius: 24,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
