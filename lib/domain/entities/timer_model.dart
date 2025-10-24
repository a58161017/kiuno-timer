// lib/domain/entities/timer_model.dart

import 'package:flutter/foundation.dart'; // 為了 @required (舊版) 或直接使用 required 關鍵字
import 'timer_status.dart'; // 引入我們剛剛定義的 TimerStatus

class TimerModel {
  final String id;
  final String name;
  final Duration totalDuration;
  Duration remainingDuration;
  TimerStatus status;
  final bool alertUntilStopped;

  TimerModel({
    required this.id,
    required this.name,
    required this.totalDuration,
    Duration? initialRemainingDuration,
    this.status = TimerStatus.pending,
    this.alertUntilStopped = false,
  }) : remainingDuration = initialRemainingDuration ?? totalDuration;

  TimerModel copyWith({
    String? id,
    String? name,
    Duration? totalDuration,
    Duration? remainingDuration,
    TimerStatus? status,
    bool? alertUntilStopped,
  }) {
    return TimerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      totalDuration: totalDuration ?? this.totalDuration,
      initialRemainingDuration: remainingDuration ?? this.remainingDuration, // 仔細檢查這一行
      status: status ?? this.status,
      alertUntilStopped: alertUntilStopped ?? this.alertUntilStopped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'totalDuration': totalDuration.inMilliseconds,
      'remainingDuration': remainingDuration.inMilliseconds,
      'status': status.name,
      'alertUntilStopped': alertUntilStopped,
    };
  }

  factory TimerModel.fromJson(Map<String, dynamic> json) {
    return TimerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      totalDuration: Duration(milliseconds: json['totalDuration'] as int),
      initialRemainingDuration: Duration(milliseconds: json['remainingDuration'] as int),
      status: TimerStatus.values.byName(json['status'] as String),
      alertUntilStopped: json['alertUntilStopped'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'TimerModel(id: $id, name: $name, total: $totalDuration, remaining: $remainingDuration, status: $status)';
  }

  bool get isRunning => status == TimerStatus.running;

  bool get isPaused => status == TimerStatus.paused;

  bool get isFinished => status == TimerStatus.finished;

  bool get isPending => status == TimerStatus.pending;

  bool get isAlerting => status == TimerStatus.alerting;
}