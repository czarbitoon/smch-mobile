#!/bin/bash
# Script to initialize Flutter project properly

set -e

echo "Initializing Flutter project for Android..."

# Configure Flutter
flutter config --no-analytics
flutter doctor -v

# Create Android directory structure if it doesn't exist
if [ ! -d "android" ]; then
  echo "Creating Android project files..."
  flutter create --platforms=android .
fi

# Remove other platforms to keep only Android
rm -rf ios macos linux windows web

# Create necessary directories
mkdir -p android/app/src/main/res/drawable
mkdir -p android/app/src/main/res/values
mkdir -p lib/config
mkdir -p lib/models
mkdir -p lib/providers
mkdir -p lib/screens
mkdir -p lib/services
mkdir -p lib/utils
mkdir -p lib/widgets

# Create local.properties file with SDK paths
if [ ! -f "android/local.properties" ]; then
  echo "Creating local.properties file..."
  FLUTTER_SDK=$(which flutter | xargs dirname | xargs dirname)
  
  # Try to find Android SDK path
  if [ -n "$ANDROID_SDK_ROOT" ]; then
    ANDROID_SDK=$ANDROID_SDK_ROOT
  elif [ -n "$ANDROID_HOME" ]; then
    ANDROID_SDK=$ANDROID_HOME
  elif [ -d "$HOME/Android/Sdk" ]; then
    ANDROID_SDK="$HOME/Android/Sdk"
  elif [ -d "$HOME/Library/Android/sdk" ]; then
    ANDROID_SDK="$HOME/Library/Android/sdk"
  else
    echo "Warning: Android SDK path not found. Please set ANDROID_SDK_ROOT or ANDROID_HOME environment variable."
    ANDROID_SDK="/path/to/your/android/sdk"
  fi
  
  cat > android/local.properties << EOL
sdk.dir=$ANDROID_SDK
flutter.sdk=$FLUTTER_SDK
flutter.buildMode=debug
flutter.versionName=1.0.0
flutter.versionCode=1
EOL
fi

# Ensure Gradle wrapper exists
if [ ! -f "android/gradlew" ]; then
  echo "Creating Gradle wrapper..."
  cd android
  gradle wrapper
  cd ..
fi

# Create basic app icon if it doesn't exist
if [ ! -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
  echo "Creating basic app icon..."
  mkdir -p android/app/src/main/res/mipmap-hdpi
  mkdir -p android/app/src/main/res/mipmap-mdpi
  mkdir -p android/app/src/main/res/mipmap-xhdpi
  mkdir -p android/app/src/main/res/mipmap-xxhdpi
  mkdir -p android/app/src/main/res/mipmap-xxxhdpi
  
  # Using a placeholder command to represent creating icons
  # In a real situation, you would use ImageMagick or a similar tool
  # For this example, we'll just copy the default Flutter icon if it exists
  if [ -f "android/app/src/main/res/mipmap-hdpi/ic_launcher.png" ]; then
    cp android/app/src/main/res/mipmap-hdpi/ic_launcher.png android/app/src/main/res/mipmap-hdpi/
    cp android/app/src/main/res/mipmap-mdpi/ic_launcher.png android/app/src/main/res/mipmap-mdpi/
    cp android/app/src/main/res/mipmap-xhdpi/ic_launcher.png android/app/src/main/res/mipmap-xhdpi/
    cp android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxhdpi/
    cp android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png android/app/src/main/res/mipmap-xxxhdpi/
  fi
fi

# Create theme files
if [ ! -f "android/app/src/main/res/values/styles.xml" ]; then
  echo "Creating styles.xml..."
  cat > android/app/src/main/res/values/styles.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoTitleBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOL
fi

if [ ! -f "android/app/src/main/res/drawable/launch_background.xml" ]; then
  echo "Creating launch_background.xml..."
  cat > android/app/src/main/res/drawable/launch_background.xml << 'EOL'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
EOL
fi

# Update Flutter
echo "Updating Flutter..."
flutter upgrade
flutter pub get

echo "Flutter project initialization completed successfully."
echo "You can now run ./fix_embedding.sh to apply Flutter embedding v2."
exit 0 