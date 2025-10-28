import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kiuno_timer/l10n/app_localizations.dart';

import '../../application/timer_list_provider.dart';
import '../../domain/entities/timer_model.dart';
import '../../domain/entities/timer_status.dart';
import '../widgets/countdown_analog_clock.dart';

class TimerDetailPage extends ConsumerStatefulWidget {
  const TimerDetailPage({super.key, required this.timerId});

  final String timerId;

  @override
  ConsumerState<TimerDetailPage> createState() => _TimerDetailPageState();
}

class _TimerDetailPageState extends ConsumerState<TimerDetailPage> {
  ProviderSubscription<List<TimerModel>>? _subscription;
  TimerStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _previousStatus = _findTimer(ref.read(timerListProvider))?.status;
    _subscription = ref.listen<List<TimerModel>>(timerListProvider, (previous, next) {
      final TimerModel? timer = _findTimer(next);
      if (timer == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).maybePop();
          }
        });
        return;
      }

      if (_previousStatus != TimerStatus.finished && timer.status == TimerStatus.finished) {
        _showHeadsUpNotification(timer);
      }
      _previousStatus = timer.status;
    });
  }

  @override
  void dispose() {
    if (mounted) {
      ScaffoldMessenger.of(context).clearMaterialBanners();
    }
    _subscription?.close();
    super.dispose();
  }

  TimerModel? _findTimer(List<TimerModel> timers) {
    try {
      return timers.firstWhere((timer) => timer.id == widget.timerId);
    } catch (_) {
      return null;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final int hours = duration.inHours;
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
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

  Color _statusColor(TimerStatus status, ColorScheme colorScheme) {
    switch (status) {
      case TimerStatus.running:
        return colorScheme.primary;
      case TimerStatus.paused:
        return colorScheme.secondary;
      case TimerStatus.finished:
        return Colors.green;
      case TimerStatus.alerting:
        return colorScheme.error;
      case TimerStatus.pending:
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  void _showHeadsUpNotification(TimerModel timer) {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        leading: Icon(Icons.notifications_active, color: Theme.of(context).colorScheme.primary),
        content: Text(l10n.notificationTimerFinishedBody(timer.name)),
        actions: [
          TextButton(
            onPressed: messenger.hideCurrentMaterialBanner,
            child: Text(l10n.cancelButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TimerModel? timer = _findTimer(ref.watch(timerListProvider));

    if (timer == null) {
      return const SizedBox.shrink();
    }

    _previousStatus ??= timer.status;

    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final Color statusColor = _statusColor(timer.status, colorScheme);
    final String statusLabel = _statusLabel(timer.status, l10n);

    return Scaffold(
      appBar: AppBar(
        title: Text(timer.name),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer.withOpacity(0.8),
                      colorScheme.secondaryContainer.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: CountdownAnalogClock(
                  totalDuration: timer.totalDuration,
                  remainingDuration: timer.remainingDuration,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  _formatDuration(timer.remainingDuration),
                  style: textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withOpacity(0.15),
                  labelStyle: textTheme.bodyMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _TimerControls(timer: timer),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimerControls extends ConsumerWidget {
  const _TimerControls({required this.timer});

  final TimerModel timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(timerListProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final List<Widget> buttons = [];

    if (timer.isRunning) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => notifier.pauseTimer(timer.id),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          icon: const Icon(Icons.pause),
          label: Text(l10n.pauseAction),
        ),
      );
    } else if (timer.isPaused || timer.isPending || timer.isFinished) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => notifier.startTimer(timer.id),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          icon: const Icon(Icons.play_arrow),
          label: Text(timer.isPaused ? l10n.resumeAction : l10n.startAction),
        ),
      );
    }

    final bool shouldShowStopButton =
        timer.alertUntilStopped && timer.remainingDuration.inMilliseconds == 0 && (timer.isFinished || timer.isAlerting);

    if (shouldShowStopButton) {
      buttons.add(
        FilledButton.icon(
          onPressed: () => notifier.resetTimer(timer.id),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          icon: const Icon(Icons.stop),
          label: Text(l10n.stopAction),
        ),
      );
    } else if (!timer.isPending || timer.remainingDuration < timer.totalDuration) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: () => notifier.resetTimer(timer.id),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          icon: const Icon(Icons.refresh),
          label: Text(l10n.resetAction),
        ),
      );
    }

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }
}
