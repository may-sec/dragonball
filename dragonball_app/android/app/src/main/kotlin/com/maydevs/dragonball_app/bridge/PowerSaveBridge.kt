package dev.dragonball.bridge

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.PowerManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// LEARN (the native half of a platform channel):
//  * MethodChannel  : Dart asks "isPowerSaveMode", we answer once.
//  * EventChannel   : Dart listens; we register a BroadcastReceiver for the
//    system broadcast ACTION_POWER_SAVE_MODE_CHANGED and forward each change.
//  * The receiver is registered in onListen and UNREGISTERED in onCancel. A
//    receiver that is never unregistered leaks the Context and keeps firing.
//  * Both channels run on the Android main thread, so calling events.success
//    from onReceive is safe (it is already on the main thread).
//
// The channel names are plain strings and MUST be identical to the ones in
// lib/core/platform/power_save_source.dart. (Pigeon generates both sides from
// one interface so this cannot drift: Module 9.7.)
class PowerSaveBridge(private val context: Context) {

    private val powerManager: PowerManager =
        context.getSystemService(Context.POWER_SERVICE) as PowerManager

    private var receiver: BroadcastReceiver? = null

    fun register(engine: FlutterEngine) {
        val messenger = engine.dartExecutor.binaryMessenger

        MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPowerSaveMode" -> result.success(powerManager.isPowerSaveMode)
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    // A second listener must not leave the first receiver behind.
                    unregister()

                    // Send the current value first, then every change.
                    events.success(powerManager.isPowerSaveMode)

                    val newReceiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            events.success(powerManager.isPowerSaveMode)
                        }
                    }

                    context.registerReceiver(
                        newReceiver,
                        IntentFilter(PowerManager.ACTION_POWER_SAVE_MODE_CHANGED)
                    )
                    receiver = newReceiver
                }

                override fun onCancel(arguments: Any?) {
                    unregister()
                }
            }
        )
    }

    private fun unregister() {
        receiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: IllegalArgumentException) {
                // Already unregistered.
            }
        }
        receiver = null
    }

    companion object {
        const val METHOD_CHANNEL = "dev.dragonball/power"
        const val EVENT_CHANNEL = "dev.dragonball/power_events"
    }
}