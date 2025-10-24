// lib/application/timer_list_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import '../infrastructure/android_foreground_service.dart';
import '../../../domain/entities/timer_model.dart';
import '../../../domain/entities/timer_status.dart'; // 雖然這裡沒直接用，但 TimerModel 依賴它

const String _timersStorageKey = 'kiuno_timers_list';
const String _continuousAlertStopActionId = 'STOP_CONTINUOUS_ALERT';
const Duration _continuousAlertReminderInterval = Duration(seconds: 6);

const AndroidNotificationChannel _timerFinishedChannel = AndroidNotificationChannel(
  'kiuno_timer_finished',
  'Timer Finished Alerts',
  description: 'Heads-up notifications when timers complete.',
  importance: Importance.max,
  playSound: true,
);

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  TimerListNotifier.instance?.handleNotificationResponse(response);
}

class TimerListNotifier extends StateNotifier<List<TimerModel>> {
  final Map<String, Timer> _activeTimers = {};
  SharedPreferences? _prefs;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  Timer? _continuousAlertTimer;
  String? _currentlyAlertingTimerId;
  bool _notificationsInitialized = false;
  static TimerListNotifier? _instance;

  static TimerListNotifier? get instance => _instance;

  TimerListNotifier() : super([]) {
    _instance = this;
    _init();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (_currentlyAlertingTimerId != null) {
        final alertingTimer = _findTimerById(_currentlyAlertingTimerId!);
        if (alertingTimer.id.isNotEmpty && alertingTimer.isAlerting) {
          Future.delayed(const Duration(milliseconds: 300), () {
            final stillAlertingTimer = _findTimerById(_currentlyAlertingTimerId!);
            if (_currentlyAlertingTimerId == alertingTimer.id && stillAlertingTimer.status == TimerStatus.alerting) {
              _playNotificationSoundInternal();
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    for (final timer in _activeTimers.values) {
      timer.cancel();
    }
    _activeTimers.clear();
    _audioPlayer.dispose();
    AndroidForegroundService.stop();
    if (identical(_instance, this)) {
      _instance = null;
    }
    super.dispose();
  }

  void addTimer(TimerModel timer) {
    _stopContinuousAlert();
    state = [...state, timer];
    _saveTimers();
    _updateForegroundServiceState();
  }

  void removeTimer(String timerId) {
    if (_currentlyAlertingTimerId == timerId) {
      _stopContinuousAlert();
    }
    _activeTimers[timerId]?.cancel();
    _activeTimers.remove(timerId);
    state = state.where((timer) => timer.id != timerId).toList();
    _saveTimers();
    _updateForegroundServiceState();
  }

  void startTimer(String timerId) {
    _stopContinuousAlert();

    _activeTimers[timerId]?.cancel();

    final timerIndex = state.indexWhere((t) => t.id == timerId);
    if (timerIndex == -1) return; // 找不到計時器

    TimerModel timerToStart = state[timerIndex];

    if (timerToStart.isFinished || timerToStart.isRunning) {
      if (timerToStart.isFinished && timerToStart.alertUntilStopped && _currentlyAlertingTimerId == timerId) {
        // 這種情況下，用戶點擊 "播放" 實際上是想重新開始這個計時器
        // _stopContinuousAlert(); // 會在 _updateTimerState 中處理
      } else if (timerToStart.isFinished) {
        // 普通完成的，直接重置並開始
      } else {
        return; // 正在運行的，不處理
      }
    }

    if (timerToStart.isPending || timerToStart.isFinished) {
      timerToStart = timerToStart.copyWith(remainingDuration: timerToStart.totalDuration);
    }
    _updateTimerState(timerId, status: TimerStatus.running, remainingDuration: timerToStart.remainingDuration);
    _updateForegroundServiceState();
    timerToStart = state.firstWhere((t) => t.id == timerId);

    _activeTimers[timerId] = Timer.periodic(const Duration(seconds: 1), (dartTimer) {
      final currentTimerModel = state.firstWhere((t) => t.id == timerId, orElse: () => timerToStart); // orElse 以防萬一
      if(currentTimerModel.id.isEmpty) {
        dartTimer.cancel();
        _activeTimers.remove(timerId);
        return;
      }

      if (currentTimerModel.remainingDuration.inSeconds > 0) {
        final newRemaining = currentTimerModel.remainingDuration - const Duration(seconds: 1);
        _updateTimerState(timerId, remainingDuration: newRemaining, status: TimerStatus.running);
      } else {
        _activeTimers[timerId]?.cancel();
        _activeTimers.remove(timerId);
        _updateTimerState(timerId, remainingDuration: Duration.zero, status: TimerStatus.finished);
        _updateForegroundServiceState();

        final finishedTimer = _findTimerById(timerId);
        if (finishedTimer.id.isNotEmpty && finishedTimer.alertUntilStopped) {
          unawaited(_showTimerFinishedNotification(finishedTimer));
          _startContinuousAlert(timerId);
        } else if (finishedTimer.id.isNotEmpty) {
          _playNotificationSound(initialCallForLoop: false);
          _vibrateDevice(continuous: false);
          unawaited(_showTimerFinishedNotification(finishedTimer));
        }
      }
    });
  }

  void pauseTimer(String timerId) {
    _activeTimers[timerId]?.cancel();

    final timerIndex = state.indexWhere((t) => t.id == timerId);
    if (timerIndex == -1) return;

    final timerToPause = state[timerIndex];
    if (!timerToPause.isRunning) return;

    _updateTimerState(timerId, status: TimerStatus.paused);
    _updateForegroundServiceState();
  }

  void resetTimer(String timerId) {
    if (_currentlyAlertingTimerId == timerId) {
      _stopContinuousAlert();
    }
    _activeTimers[timerId]?.cancel();
    _activeTimers.remove(timerId);
    _cancelNotificationForTimer(timerId);

    final timerIndex = state.indexWhere((t) => t.id == timerId);
    if (timerIndex == -1) return;

    final timerToReset = state[timerIndex];
    _updateTimerState(
      timerId,
      remainingDuration: timerToReset.totalDuration,
      status: TimerStatus.pending,
    );
    _updateForegroundServiceState();
  }

  void editTimer(TimerModel updatedTimer) {
    final existingTimerIndex = state.indexWhere((t) => t.id == updatedTimer.id);
    if (existingTimerIndex != -1) {
      final existingTimer = state[existingTimerIndex];
      if (existingTimer.isRunning) {
        _activeTimers[existingTimer.id]?.cancel();
        _activeTimers.remove(existingTimer.id);
      }
      if (existingTimer.isAlerting) {
        _stopContinuousAlert();
      }
    }

    state = [
      for (final timerInList in state)
        if (timerInList.id == updatedTimer.id)
          updatedTimer.copyWith(
            status: TimerStatus.pending,
            remainingDuration: updatedTimer.totalDuration,
          )
        else
          timerInList,
    ];
    _saveTimers();
    _updateForegroundServiceState();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    await _initializeNotifications();
    await _loadTimers();
    _resetRunningTimersToPausedOnLoad();
  }

  Future<void> _initializeNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      final InitializationSettings initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: handleNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      final androidImplementation = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(_timerFinishedChannel);
      await androidImplementation?.requestNotificationsPermission();

      _notificationsInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _loadTimers() async {
    if (_prefs == null) return; // 確保 _prefs 已初始化

    final String? timersJson = _prefs!.getString(_timersStorageKey);
    if (timersJson != null && timersJson.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(timersJson) as List;
        final List<TimerModel> loadedTimers = decodedList
            .map((item) => TimerModel.fromJson(item as Map<String, dynamic>))
            .toList();
        state = loadedTimers;
        print("Timers loaded: ${state.length}");
      } catch (e) {
        print("Error loading timers: $e");
        state = []; // 如果加載失敗，則使用空列表
      }
    } else {
      state = []; // 如果沒有存儲的數據，則使用空列表
      print("No saved timers found.");
    }
  }

  Future<void> _saveTimers() async {
    if (_prefs == null) return;

    final List<Map<String, dynamic>> timersToSave =
    state.map((timer) => timer.toJson()).toList();
    final String timersJson = jsonEncode(timersToSave);
    await _prefs!.setString(_timersStorageKey, timersJson);
    print("Timers saved.");
  }

  void _resetRunningTimersToPausedOnLoad() {
    bool changed = false;
    final newState = state.map((timer) {
      if (timer.status == TimerStatus.running) {
        changed = true;
        return timer.copyWith(status: TimerStatus.paused);
      }
      return timer;
    }).toList();

    if (changed) {
      state = newState;
      _saveTimers(); // 如果有更改，保存一下狀態
    }
  }

  void _updateTimerState(String timerId, {
    Duration? remainingDuration,
    TimerStatus? status,
  }) {
    final oldTimer = _findTimerById(timerId);
    if (oldTimer.id.isNotEmpty && oldTimer.status != TimerStatus.finished && status == TimerStatus.finished && _currentlyAlertingTimerId != timerId) {
      _stopContinuousAlert();
    }

    state = [
      for (final timerInList in state)
        if (timerInList.id == timerId)
          timerInList.copyWith(
            remainingDuration: remainingDuration,
            status: status,
          )
        else
          timerInList,
    ];
    _saveTimers();
  }

  Future<void> _playNotificationSoundInternal() async {
    try {
      await _audioPlayer.play(AssetSource('audio/timer_finished.mp3')); // 總是播放一次
      print("Notification sound played (internally for loop).");
    } catch (e) {
      print("Error playing sound internally: $e");
    }
  }

  Future<void> _playNotificationSound({bool initialCallForLoop = false}) async {
    try {
      if (initialCallForLoop) {
        // 這是 _startContinuousAlert 調用的，確保播放器沒有在播放其他東西
        await _audioPlayer.stop(); // 先停止，確保是新的播放序列
      }
      await _audioPlayer.play(AssetSource('audio/timer_finished.mp3'));
      print("Notification sound played (initialCallForLoop: $initialCallForLoop).");
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  Future<void> _vibrateDevice({bool continuous = false}) async {
    try {
      bool? canVibrate = await Vibration.hasVibrator(); // 檢查設備是否有震動器
      if (canVibrate == true) {
        if (canVibrate == true) {
          Vibration.vibrate(duration: 300);
        } else {
          Vibration.vibrate(duration: 500);
        }
        print("Device vibrated (continuous: $continuous).");
      }
    } catch (e) {
      print("Error vibrating device: $e");
    }
  }

  Future<void> _showTimerFinishedNotification(TimerModel timer) async {
    if (!_notificationsInitialized) {
      return;
    }

    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _timerFinishedChannel.id,
        _timerFinishedChannel.name,
        channelDescription: _timerFinishedChannel.description,
        importance: Importance.max,
        priority: Priority.max,
        ticker: 'Timer finished',
        autoCancel: !timer.alertUntilStopped,
        ongoing: timer.alertUntilStopped,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: timer.alertUntilStopped,
        actions: timer.alertUntilStopped
            ? const <AndroidNotificationAction>[
                AndroidNotificationAction(
                  _continuousAlertStopActionId,
                  'Stop',
                  showsUserInterface: false,
                  cancelNotification: true,
                ),
              ]
            : null,
      );

      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _localNotifications.show(
        timer.id.hashCode,
        '計時完成',
        '${timer.name} 已經結束',
        notificationDetails,
        payload: timer.id,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  void _startContinuousAlert(String timerId) {
    _stopContinuousAlert();

    final timerModel = _findTimerById(timerId);
    if (timerModel.id.isEmpty || !timerModel.alertUntilStopped || !timerModel.isFinished) {
      return;
    }

    _currentlyAlertingTimerId = timerId;
    _updateTimerState(timerId, status: TimerStatus.alerting);

    print("Starting continuous alert for $timerId");

    _playNotificationSound(initialCallForLoop: true);

    _continuousAlertTimer?.cancel();
    int ticksSinceReminder = 0;
    _continuousAlertTimer = Timer.periodic(const Duration(seconds: 2), (timer) { // 每2秒震動一次
      final currentTimer = _findTimerById(_currentlyAlertingTimerId!);
      if (currentTimer.status == TimerStatus.alerting) {
        _vibrateDevice(continuous: true);
        ticksSinceReminder += 2;
        if (_notificationsInitialized && ticksSinceReminder >= _continuousAlertReminderInterval.inSeconds) {
          ticksSinceReminder = 0;
          unawaited(_showTimerFinishedNotification(currentTimer));
        }
      } else {
        timer.cancel();
      }
    });
  }

  void stopContinuousAlertForTimer(String timerId) {
    if (_currentlyAlertingTimerId == timerId) {
      _stopContinuousAlert();
      print("Continuous alert stopped by user for $timerId");
    }
  }

  void _updateForegroundServiceState() {
    final runningTimers = state.where((timer) => timer.isRunning).length;
    unawaited(AndroidForegroundService.syncWithActiveTimers(runningTimers));
  }

  void _stopContinuousAlert() {
    String? previousAlertingId = _currentlyAlertingTimerId;
    _continuousAlertTimer?.cancel();
    _continuousAlertTimer = null;
    _audioPlayer.stop(); // 停止音頻播放
    _currentlyAlertingTimerId = null;

    if (previousAlertingId != null) {
      _cancelNotificationForTimer(previousAlertingId);
      final timerToUpdate = _findTimerById(previousAlertingId);
      if (timerToUpdate.id.isNotEmpty && timerToUpdate.status == TimerStatus.alerting) {
        // 只有當它確實處於 alerting 狀態時才改回 finished
        _updateTimerState(previousAlertingId, status: TimerStatus.finished);
      }
      print("Stopping continuous alert for $previousAlertingId");
    }
  }

  TimerModel _dummyTimerModel() {
    return TimerModel(
      id: '',
      name: 'Dummy',
      totalDuration: Duration.zero,
      initialRemainingDuration: Duration.zero,
      status: TimerStatus.pending,
      alertUntilStopped: false,
    );
  }

  TimerModel _findTimerById(String timerId) {
    try {
      return state.firstWhere((t) => t.id == timerId);
    } catch (e) {
      return _dummyTimerModel();
    }
  }

  void handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == _continuousAlertStopActionId && response.payload != null) {
      resetTimer(response.payload!);
    }
  }

  void _cancelNotificationForTimer(String timerId) {
    if (!_notificationsInitialized) {
      return;
    }
    _localNotifications.cancel(timerId.hashCode);
  }
}

final timerListProvider = StateNotifierProvider<TimerListNotifier, List<TimerModel>>((ref) {
  return TimerListNotifier();
});
    