package io.flutter.app;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;
import android.app.Application;

/**
 * Flutter's default Application class for v2 embedding backward compatibility.
 * 
 * This can be removed once all plugins requiring the embedding v1 are migrated
 * to the embedding v2.
 */
public class FlutterApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
    }
} 