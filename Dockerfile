# Use the official Flutter SDK image as base with a specific version
FROM ghcr.io/cirruslabs/flutter:3.22.0

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
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for Flutter and Android SDK
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV FLUTTER_HOME=/sdks/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin:${ANDROID_HOME}/tools:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/cmdline-tools/latest/bin

# Install Android SDK components
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest && \
    rm -rf /tmp/cmdline-tools.zip

# Accept Android SDK licenses
RUN mkdir -p ${ANDROID_HOME}/licenses && \
    echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > ${ANDROID_HOME}/licenses/android-sdk-license && \
    echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> ${ANDROID_HOME}/licenses/android-sdk-license && \
    yes | sdkmanager --licenses

# Create a non-root user
RUN groupadd -r flutter && useradd -r -g flutter -m -d /home/flutter flutter
RUN mkdir /app && chown flutter:flutter /app

# Set Flutter SDK permissions
RUN chown -R flutter:flutter /sdks/flutter

# Set working directory
WORKDIR /app

# Switch to non-root user
USER flutter

# Configure Git safe directory and Flutter
RUN git config --global --add safe.directory /sdks/flutter
RUN flutter config --no-analytics

# Create local.properties with correct SDK paths
RUN mkdir -p android && echo "flutter.sdk=${FLUTTER_HOME}\nsdk.dir=${ANDROID_HOME}" > android/local.properties

# Copy pubspec files
COPY --chown=flutter:flutter pubspec.* ./

# Get app dependencies
RUN flutter pub get

# Copy the rest of the application code
COPY --chown=flutter:flutter . .

# Configure Flutter and build the app for Android
RUN flutter config --no-analytics && \
    flutter doctor -v && \
    cd /app && \
    flutter clean && \
    flutter pub get && \
    flutter build apk --debug --no-tree-shake-icons --verbose

# Set output directory for build artifacts
WORKDIR /app/build/app/outputs/flutter-apk

# Default command (can be overridden)
CMD ["cp", "app-debug.apk", "/app/build/"]