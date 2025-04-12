#!/bin/bash
# Script to fix Flutter embedding issues at build time

set -e

echo "Checking Flutter Embedding v2 setup..."

# Define paths
MANIFEST_PATH="android/app/src/main/AndroidManifest.xml"
MANIFEST_DIR="android/app/src/main"

# Check if Android directory structure exists
if [ ! -d "android" ]; then
  echo "Android directory does not exist. Please run ./init_flutter.sh first."
  exit 1
fi

# Create directory structure if it doesn't exist
if [ ! -d "$MANIFEST_DIR" ]; then
  echo "Creating directory structure: $MANIFEST_DIR"
  mkdir -p "$MANIFEST_DIR"
fi

# Create AndroidManifest.xml if it doesn't exist
if [ ! -f "$MANIFEST_PATH" ]; then
  echo "Creating $MANIFEST_PATH"
  cat > "$MANIFEST_PATH" << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.smch_mobile">
    <application
        android:label="SMCH Mobile"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOL
fi

# Check if Flutter Embedding v2 metadata is already in AndroidManifest.xml
if grep -q "flutterEmbedding" "$MANIFEST_PATH"; then
  echo "Flutter Embedding v2 metadata already exists in AndroidManifest.xml"
else
  echo "Adding Flutter Embedding v2 metadata to AndroidManifest.xml"
  # Insert metadata before closing </application> tag
  sed -i 's|</application>|    <meta-data android:name="flutterEmbedding" android:value="2" />\n    </application>|' "$MANIFEST_PATH"
  echo "Flutter Embedding v2 metadata added successfully"
fi

# Fix gradle.properties if needed
GRADLE_PROPS="android/gradle.properties"
if [ -f "$GRADLE_PROPS" ] && ! grep -q "android.enableR8=true" "$GRADLE_PROPS"; then
  echo "Adding R8 configuration to gradle.properties"
  echo "android.enableR8=true" >> "$GRADLE_PROPS"
  echo "R8 configuration added"
fi

# Create MainActivity if it doesn't exist
MAIN_ACTIVITY_DIR="android/app/src/main/kotlin/com/example/smch_mobile"
MAIN_ACTIVITY_PATH="$MAIN_ACTIVITY_DIR/MainActivity.kt"

if [ ! -d "$MAIN_ACTIVITY_DIR" ]; then
  echo "Creating directory for MainActivity: $MAIN_ACTIVITY_DIR"
  mkdir -p "$MAIN_ACTIVITY_DIR"
fi

if [ ! -f "$MAIN_ACTIVITY_PATH" ]; then
  echo "Creating MainActivity.kt with FlutterActivity implementation"
  cat > "$MAIN_ACTIVITY_PATH" << 'EOL'
package com.example.smch_mobile

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
}
EOL
  echo "MainActivity.kt created"
fi

echo "Flutter Embedding v2 setup completed successfully"
exit 0 