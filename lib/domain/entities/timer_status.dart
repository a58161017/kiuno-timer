// lib/domain/entities/timer_status.dart

enum TimerStatus {
  pending,  // 待開始
  running,  // 運行中
  paused,   // 已暫停
  finished, // 已完成 (單次提示或已確認的持續提示)
  alerting, // 完成並且正在持續提示中
}