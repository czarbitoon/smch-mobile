#!/bin/bash
# Script to build the Flutter APK with better error handling

set -e

# Initialize
echo "Initializing Flutter build..."
FLUTTER_PATH="/sdks/flutter/bin/flutter"

# Load environment variables
echo "Loading environment configuration..."
if [ -f "load_env.sh" ]; then
  chmod +x load_env.sh
  ./load_env.sh
else
  echo "Warning: load_env.sh not found. Using default configuration."
fi

# Create local.properties with the correct Flutter and Android SDK paths
mkdir -p android
echo "flutter.sdk=/sdks/flutter" > android/local.properties
echo "sdk.dir=/opt/android-sdk-linux" >> android/local.properties

# Run the fix_embedding script first to create all needed Android files
echo "Running fix_embedding.sh to ensure proper Flutter embedding..."
if [ -f "fix_embedding.sh" ]; then
  chmod +x fix_embedding.sh
  ./fix_embedding.sh
else
  echo "Error: fix_embedding.sh not found. Cannot continue without it."
  exit 1
fi

# Create a basic pubspec.yaml if it doesn't exist
if [ ! -f "pubspec.yaml" ]; then
  echo "Creating basic pubspec.yaml..."
  cat > "pubspec.yaml" << 'EOL'
name: smch_mobile
description: SMCH Mobile App

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=2.19.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  dio: ^5.3.2
  flutter_secure_storage: ^9.0.0
  provider: ^6.0.5
  shared_preferences: ^2.2.1
  intl: ^0.18.1
  google_fonts: ^6.1.0
  connectivity_plus: ^5.0.1
  image_picker: ^1.0.4
  path_provider: ^2.1.1
  flutter_riverpod: ^2.4.0
  retry: ^3.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
EOL

  # Create assets directory if it doesn't exist
  mkdir -p assets/images
fi

# Create a minimal lib/main.dart if it doesn't exist
if [ ! -f "lib/main.dart" ]; then
  echo "Creating minimal main.dart..."
  mkdir -p lib
  cat > "lib/main.dart" << 'EOL'
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMCH Mobile',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'SMCH Mobile Home'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'SMCH Mobile App',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
EOL
fi

# Create a flutter resource directory for fonts and assets if it doesn't exist
mkdir -p android/app/src/main/res/drawable
mkdir -p fonts

# Initialize Flutter project
echo "Setting up Flutter project..."
$FLUTTER_PATH create --no-overwrite .

# Check flutter installation
echo "Checking Flutter installation..."
$FLUTTER_PATH --version

# Configure flutter
echo "Configuring Flutter..."
$FLUTTER_PATH config --no-analytics

# Clean and get dependencies
echo "Cleaning previous build and getting dependencies..."
$FLUTTER_PATH clean || echo "Clean failed, continuing anyway"
$FLUTTER_PATH pub get || {
  echo "Pub get failed, trying with upgrade..."
  $FLUTTER_PATH pub upgrade
  $FLUTTER_PATH pub get
}

# Run flutter doctor with verbose output for debugging
echo "Running flutter doctor for diagnostics..."
$FLUTTER_PATH doctor -v

# Ensure Android files exist before starting the build
if [ ! -d "android/app/src/main" ]; then
  echo "Critical error: Android directory structure still not set up properly"
  echo "Current contents of android directory:"
  find android -type f | sort
  exit 1
fi

# Start the build
echo "Starting APK build..."
$FLUTTER_PATH build apk --release --verbose

# Check if build succeeded
if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
  echo "Build succeeded! APK file created at build/app/outputs/flutter-apk/app-release.apk"
  echo "APK details:"
  ls -la build/app/outputs/flutter-apk/app-release.apk
  exit 0
else
  echo "Build failed! APK file not found."
  echo "Checking build directory:"
  ls -la build/app/outputs/flutter-apk/ || echo "Directory not found"
  exit 1
fi