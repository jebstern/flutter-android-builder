# ==========================================
# Base image: Ubuntu with Java 17 + deps
# ==========================================
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

# Install essential packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl git unzip wget xz-utils zip openjdk-17-jdk && \
    rm -rf /var/lib/apt/lists/*

# Set Java environment dynamically
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# ==========================================
# Install Flutter
# ==========================================
ARG FLUTTER_VERSION=3.35.1
ARG FLUTTER_CHANNEL=stable

# Clone Flutter into /opt/flutter
RUN git clone --branch $FLUTTER_VERSION https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH"

# Pre-cache Flutter SDK
RUN flutter doctor -v

# ==========================================
# Install Android SDK, NDK, CMake
# ==========================================
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Create Android SDK directory and download command line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && cd $ANDROID_SDK_ROOT/cmdline-tools \
    && curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip \
    && unzip commandlinetools.zip && rm commandlinetools.zip \
    && mv cmdline-tools latest

# Accept licenses and install SDK/NDK/CMake/build-tools
RUN export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    export PATH=$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH && \
    yes | sdkmanager --sdk_root=$ANDROID_SDK_ROOT --licenses && \
    sdkmanager --sdk_root=$ANDROID_SDK_ROOT \
        "platform-tools" \
        "platforms;android-31" \
        "platforms;android-33" \
        "platforms;android-34" \
        "ndk;27.0.12077973" \
        "cmake;3.22.1" \
        "build-tools;33.0.2"

# ==========================================
# Pre-cache Gradle & Flutter pub packages
# ==========================================
RUN mkdir -p /root/.gradle && echo "Gradle cache ready"
RUN flutter pub get --offline || true

# ==========================================
# Set working directory for builds
# ==========================================
WORKDIR /workspace

# Default entrypoint
ENTRYPOINT ["/bin/bash"]
