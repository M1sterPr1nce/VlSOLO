package com.example.fitloch

import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.PluginRegistrantCallback
import io.flutter.plugins.GeneratedPluginRegistrant
import androidx.work.Configuration
import io.flutter.view.FlutterMain

class Application : FlutterApplication(), Configuration.Provider {
    override fun onCreate() {
        super.onCreate()
        FlutterMain.startInitialization(this)
    }

    override fun getWorkManagerConfiguration(): Configuration {
        return Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
    }
}