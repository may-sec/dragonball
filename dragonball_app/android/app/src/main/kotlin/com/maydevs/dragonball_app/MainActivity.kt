package com.maydevs.dragonball_app

import dev.dragonball.bridge.PowerSaveBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    // Called when the Flutter engine is ready: the moment to register channels.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        PowerSaveBridge(applicationContext).register(flutterEngine)
    }
}
