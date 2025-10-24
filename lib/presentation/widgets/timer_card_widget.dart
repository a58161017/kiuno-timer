import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/timer_list_provider.dart';
import '../../domain/entities/timer_model.dart';
import '../../domain/entities/timer_status.dart';
import '../screens/add_timer_page.dart';

class TimerCardWidget extends ConsumerWidget {
  final TimerModel timer;
  
  const TimerCardWidget({
    super.key,
    required this.timer,
  });
  
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

    IconData statusIcon;
    Color statusColor;
    String displayedTime;

    // 根據狀態決定顯示的時間和圖示
    if (timer.status == TimerStatus.pending || timer.status == TimerStatus.finished) {
      displayedTime = _formatDuration(timer.totalDuration);
    } else { // running or paused
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
        statusColor = colorScheme.onSurface.withValues(alpha: 0.6);
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    timer.name,
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                                Navigator.of(dialogContext).pop(); // 關閉對話框
                              },
                            ),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                              child: const Text('Delete'),
                              onPressed: () {
                                // 調用 Notifier 的刪除方法
                                ref.read(timerListProvider.notifier).removeTimer(timer.id);
                                Navigator.of(dialogContext).pop(); // 關閉對話框
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
            const SizedBox(height: 8),
            Text(
              displayedTime, // 使用我們上面計算的 displayedTime
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  timer.status.name.substring(0, 1).toUpperCase() + timer.status.name.substring(1), // 首字母大寫
                  style: textTheme.labelLarge?.copyWith(color: statusColor),
                ),
                const Spacer(), // 把後面的按鈕推到右邊
                // 控制按鈕區域
                _buildControlButtons(context, ref, timer, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 輔助方法來構建控制按鈕
  Widget _buildControlButtons(BuildContext context, WidgetRef ref, TimerModel timer, ColorScheme colorScheme) {
    final notifier = ref.read(timerListProvider.notifier);

    List<Widget> buttons = [];

    if (timer.isPending || timer.isPaused || timer.isFinished) {
      // 顯示開始/重啟按鈕
      buttons.add(
          timer.isFinished || (timer.isPending && timer.remainingDuration == timer.totalDuration)
              ? Tooltip(
            message: "Start",
            child: IconButton(
              icon: Icon(Icons.play_arrow, color: colorScheme.primary),
              onPressed: () => notifier.startTimer(timer.id),
            ),
          )
              : Tooltip( // 如果是從暫停狀態或未完成的 pending 狀態開始，則顯示 "Resume"
            message: timer.isPaused ? "Resume" : "Start",
            child: IconButton(
              icon: Icon(Icons.play_circle_outline, color: colorScheme.primary),
              onPressed: () => notifier.startTimer(timer.id),
            ),
          )
      );
    }

    if (timer.isRunning) {
      // 顯示暫停按鈕
      buttons.add(
          Tooltip(
            message: "Pause",
            child: IconButton(
              icon: Icon(Icons.pause, color: colorScheme.secondary),
              onPressed: () => notifier.pauseTimer(timer.id),
            ),
          )
      );
    }

    // 總是可以顯示重置按鈕 (除非是純粹的 pending 狀態且時間未動)
    if (!timer.isPending || timer.remainingDuration < timer.totalDuration) {
      buttons.add(
          Tooltip(
            message: "Reset",
            child: IconButton(
              icon: Icon(Icons.refresh, color: colorScheme.onSurface.withOpacity(0.7)),
              onPressed: () => notifier.resetTimer(timer.id),
            ),
          )
      );
    }


    if (buttons.isEmpty) {
      // 理論上根據上面的邏輯，總會有按鈕，但以防萬一
      return const SizedBox.shrink();
    }

    // 如果只有一個按鈕，直接返回它，否則用 Row 包裹
    return buttons.length == 1 ? buttons.first : Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}