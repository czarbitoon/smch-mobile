package com.example.smch_mobile;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {
    private static final String ENGINE_ID = "CACHED_ENGINE_ID";
    
    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);
    }
    
    /**
     * This method tells Flutter to use the cached engine instead of creating a new one
     */
    @Override
    public String getCachedEngineId() {
        return ENGINE_ID;
    }
} 