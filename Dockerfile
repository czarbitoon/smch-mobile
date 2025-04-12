# Builder stage
FROM ubuntu:22.04 as builder

# Set environment variables
ENV ANDROID_HOME=/opt/android-sdk-linux
ENV FLUTTER_HOME=/sdks/flutter
ENV PATH=${PATH}:${FLUTTER_HOME}/bin:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    openjdk-11-jdk \
    wget \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK
RUN mkdir -p ${ANDROID_HOME} && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-8512546_latest.zip -O android-sdk.zip && \
    unzip -q android-sdk.zip -d ${ANDROID_HOME} && \
    mkdir -p ${ANDROID_HOME}/cmdline-tools/latest && \
    mv ${ANDROID_HOME}/cmdline-tools/* ${ANDROID_HOME}/cmdline-tools/latest/ || true && \
    rm android-sdk.zip

# Accept licenses
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses

# Install SDK components
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

# Download Flutter SDK
RUN git clone https://github.com/flutter/flutter.git ${FLUTTER_HOME} && \
    cd ${FLUTTER_HOME} && \
    git checkout stable && \
    ${FLUTTER_HOME}/bin/flutter config --no-analytics

# Create a non-root user
RUN useradd -ms /bin/bash developer
WORKDIR /home/developer/app
COPY . .

# Fix Windows line endings and make scripts executable
RUN dos2unix init_flutter.sh fix_embedding.sh build_apk.sh && \
    chmod +x init_flutter.sh fix_embedding.sh build_apk.sh

# Give ownership to the developer user
RUN chown -R developer:developer /home/developer && \
    chown -R developer:developer ${FLUTTER_HOME} && \
    chown -R developer:developer ${ANDROID_HOME}

# Switch to the developer user
USER developer

# Run initialization and build scripts with proper error handling
RUN bash -c 'set -e; \
    echo "Running init_flutter.sh..."; \
    ./init_flutter.sh; \
    echo "Running fix_embedding.sh..."; \
    ./fix_embedding.sh; \
    echo "Running build_apk.sh..."; \
    ./build_apk.sh; \
    echo "Build completed successfully!"'

# Cleanup to reduce image size
RUN rm -rf ${FLUTTER_HOME}/.pub-cache

# Distribution image
FROM alpine:latest
WORKDIR /app
COPY --from=builder /home/developer/app/build/app/outputs/flutter-apk/app-release.apk /app/
COPY --from=builder /home/developer/app/build/app/outputs/flutter-apk/app-debug.apk /app/

# Set a default command to show the APKs
CMD ["ls", "-la", "/app"]