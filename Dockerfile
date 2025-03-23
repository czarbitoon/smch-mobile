# Use the official Flutter SDK image as base
FROM ghcr.io/cirruslabs/flutter:stable

# Install Linux build dependencies and Android SDK tools
RUN apt-get update && apt-get install -y \
    cmake \
    ninja-build \
    clang \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libglu1-mesa-dev \
    libstdc++-12-dev \
    build-essential \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Accept Android SDK licenses
RUN yes | flutter doctor --android-licenses

# Create a non-root user
RUN groupadd -r flutter && useradd -r -g flutter -m -d /home/flutter flutter
RUN mkdir /app && chown flutter:flutter /app

# Set Flutter SDK permissions
RUN chown -R flutter:flutter /sdks/flutter

# Set working directory
WORKDIR /app

# Switch to non-root user
USER flutter

# Configure Git safe directory
RUN git config --global --add safe.directory /sdks/flutter

# Copy pubspec files
COPY --chown=flutter:flutter pubspec.* ./

# Get app dependencies
RUN flutter pub get

# Copy the rest of the application code
COPY --chown=flutter:flutter . .

# Configure Flutter and build the app for Android
RUN flutter config --no-analytics && \
    flutter doctor && \
    flutter build apk --release

# Set output directory for build artifacts
WORKDIR /app/build/app/outputs/flutter-apk

# Default command (can be overridden)
CMD ["cp", "app-release.apk", "/app/build/"]