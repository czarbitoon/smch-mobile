package com.example.smch_mobile;

import android.app.Application;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.GeneratedPluginRegistrant;

/**
 * Application class that provides plugin registration for the Flutter app.
 */
public class MainApplication extends Application {
    private static final String ENGINE_ID = "CACHED_ENGINE_ID";
    
    @Override
    public void onCreate() {
        super.onCreate();
        
        // Pre-warm the Flutter engine
        FlutterEngine flutterEngine = new FlutterEngine(this);
        flutterEngine.getDartExecutor().executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        );
        
        // Register all plugins
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        
        // Cache the Flutter engine
        FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine);
    }
} 