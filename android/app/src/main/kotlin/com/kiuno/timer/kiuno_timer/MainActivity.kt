package com.kiuno.timer.kiuno_timer

import android.content.Intent
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.kiuno.timer/foreground_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val activeCount = call.argument<Int>("activeCount") ?: 1
                        val serviceIntent = Intent(this, TimerForegroundService::class.java).apply {
                            putExtra(TimerForegroundService.EXTRA_ACTIVE_COUNT, activeCount)
                        }
                        ContextCompat.startForegroundService(this, serviceIntent)
                        result.success(null)
                    }

                    "stopService" -> {
                        stopService(Intent(this, TimerForegroundService::class.java))
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
