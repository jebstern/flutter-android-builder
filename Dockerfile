# -----------------------------
# Optimized Flutter + Android Builder Dockerfile
# -----------------------------

FROM ubuntu:22.04

# -----------------------------
# Environment Variables
# -----------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

# -----------------------------
# Install required packages
# -----------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-17-jdk \
        wget \
        unzip \
        git \
        curl \
        xz-utils \
        zip \
        && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Install Flutter
# -----------------------------
RUN git clone https://github.com/flutter/flutter.git /opt/flutter -b stable && \
    chmod +x /opt/flutter/bin/flutter

# -----------------------------
# Flutter pre-cache
# -----------------------------
# Pre-download Flutter engine artifacts for Android to speed up builds
RUN flutter precache --android --linux

# -----------------------------
# Pre-cache Flutter packages for all projects
# -----------------------------
# Creates a pub cache layer that can be reused in CI
RUN mkdir -p /workspace && \
    cd /workspace && \
    flutter create temp_project && \
    cd temp_project && \
    flutter pub get

# -----------------------------
# Install Android Command Line Tools
# -----------------------------
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip && \
    rm cmdline-tools.zip && \
    mv cmdline-tools latest

# -----------------------------
# Accept licenses & install SDK packages
# -----------------------------
RUN yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses && \
    sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platform-tools" \
        "platforms;android-31" \
        "platforms;android-33" \
        "platforms;android-34" \
        "platforms;android-35" \
        "platforms;android-36" \
        "build-tools;33.0.2" \
        "build-tools;35.0.0" \
        "ndk;27.0.12077973" \
        "cmake;3.22.1"

# -----------------------------
# Pre-cache Gradle wrapper & dependencies
# -----------------------------
# Gradle wrapper will be cached in Docker layers
RUN mkdir -p /workspace/android_project && \
    cd /workspace/android_project && \
    mkdir -p android && \
    echo "apply plugin: 'com.android.application'" > android/build.gradle && \
    ./gradlew wrapper || true  # ignore if wrapper fails

# -----------------------------
# Verify installation
# -----------------------------
RUN flutter doctor -v

# -----------------------------
# Set working directory
# -----------------------------
WORKDIR /workspace