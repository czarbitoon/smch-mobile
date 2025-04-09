# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

# Install Flutter
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-17-jdk-headless \
    && rm -rf /var/lib/apt/lists/* \
    && git clone https://github.com/flutter/flutter.git /sdks/flutter \
    && cd /sdks/flutter \
    && git checkout stable \
    && ./bin/flutter --version

# Install Android SDK with retry mechanism
RUN mkdir -p /opt/android-sdk-linux/cmdline-tools \
    && for i in {1..3}; do \
        curl -fsSL https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -o /tmp/cmdline-tools.zip \
        && unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk-linux/cmdline-tools \
        && mv /opt/android-sdk-linux/cmdline-tools/cmdline-tools /opt/android-sdk-linux/cmdline-tools/latest \
        && rm -f /tmp/cmdline-tools.zip \
        && break \
        || { echo "Download failed, retrying in 5 seconds..."; sleep 5; }; \
    done

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk-linux \
    FLUTTER_HOME=/sdks/flutter \
    PATH=${PATH}:/sdks/flutter/bin:/opt/android-sdk-linux/cmdline-tools/latest/bin

# Accept licenses and setup Android SDK with retry mechanism
RUN mkdir -p ${ANDROID_HOME}/licenses \
    && echo "8933bad161af4178b1185d1a37fbf41ea5269c55" > ${ANDROID_HOME}/licenses/android-sdk-license \
    && echo "d56f5187479451eabf01fb78af6dfcb131a6481e" >> ${ANDROID_HOME}/licenses/android-sdk-license \
    && for i in {1..3}; do \
        yes | sdkmanager --licenses > /dev/null \
        && sdkmanager --install "platform-tools" "build-tools;34.0.0" "platforms;android-34" > /dev/null \
        && break \
        || { echo "SDK installation failed, retrying in 5 seconds..."; sleep 5; }; \
    done

# Set up non-root user and prepare workspace
RUN groupadd -r flutter && useradd -r -g flutter -m -d /home/flutter flutter \
    && mkdir /app && chown -R flutter:flutter /app /sdks/flutter

WORKDIR /app
USER flutter

# Configure Flutter and prepare for build
RUN git config --global --add safe.directory /sdks/flutter \
    && flutter config --no-analytics \
    && mkdir -p android \
    && echo "flutter.sdk=${FLUTTER_HOME}\nsdk.dir=${ANDROID_HOME}" > android/local.properties

# Copy dependency files and install
COPY --chown=flutter:flutter pubspec.* ./
RUN flutter pub get --no-offline

# Copy source and build
COPY --chown=flutter:flutter . .
RUN flutter build apk --release \
    && rm -rf /app/.dart_tool /app/.pub-cache /app/build/app/intermediates \
    && find /app -name "*.dart.js.deps" -delete \
    && find /app -name "*.dart.js.map" -delete

# Stage 2: Distribution image
FROM alpine:3.18.2
WORKDIR /app
COPY --from=builder /app/build/app/outputs/flutter-apk/app-release.apk ./
CMD ["cp", "app-release.apk", "/output/"]