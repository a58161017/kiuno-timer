import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides a thin wrapper around the Android foreground service that keeps
/// timers alive while the application is in the background.
class AndroidForegroundService {
  static const MethodChannel _channel =
      MethodChannel('com.kiuno.timer/foreground_service');

  /// Ensures that the foreground service reflects the number of active timers.
  ///
  /// When [activeTimerCount] is greater than zero, the foreground service is
  /// started (or updated) so Android keeps the process alive. Otherwise the
  /// service is stopped so the system may reclaim resources.
  static Future<void> syncWithActiveTimers(int activeTimerCount) async {
    if (!Platform.isAndroid) return;

    try {
      if (activeTimerCount > 0) {
        await _channel.invokeMethod<void>('startService', {
          'activeCount': activeTimerCount,
        });
      } else {
        await _channel.invokeMethod<void>('stopService');
      }
    } on PlatformException catch (error) {
      debugPrint('Failed to update foreground service: ${error.message}');
    } catch (error, stackTrace) {
      debugPrint('Unexpected error while updating foreground service: '
          '$error\n$stackTrace');
    }
  }

  /// Explicitly stops the foreground service, ignoring any errors.
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;

    try {
      await _channel.invokeMethod<void>('stopService');
    } catch (error) {
      debugPrint('Failed to stop foreground service: $error');
    }
  }
}
