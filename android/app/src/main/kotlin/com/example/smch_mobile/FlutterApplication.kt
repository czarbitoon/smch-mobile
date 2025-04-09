package com.example.smch_mobile

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint

/**
 * Application class that properly implements Flutter's v2 embedding.
 * This is referenced by the AndroidManifest.xml via ${applicationName}
 */
class FlutterApplication : android.app.Application() {
    override fun onCreate() {
        super.onCreate()
        // Flutter v2 embedding handles plugin registration automatically
    }
}