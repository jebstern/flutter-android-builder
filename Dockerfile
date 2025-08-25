# Base Ubuntu image
FROM ubuntu:22.04

# Environment variables
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin
ENV GRADLE_USER_HOME=/root/.gradle
ENV PUB_CACHE=/root/.pub-cache

# Install minimal Linux dependencies + Java 17
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jdk \
    unzip curl git wget xz-utils zip && \
    rm -rf /var/lib/apt/lists/*

# Detect correct JAVA_HOME dynamically
RUN update-alternatives --config java && \
    JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java)))) && \
    echo "JAVA_HOME=$JAVA_HOME" >> /etc/environment && \
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile && \
    echo "export PATH=$JAVA_HOME/bin:$PATH" >> /etc/profile

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /opt/flutter -b 3.35.1 && \
    /opt/flutter/bin/flutter precache

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Install Android command line tools
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    curl -o commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools.zip && rm commandlinetools.zip && \
    mv cmdline-tools latest

# Accept licenses
RUN bash -lc "yes | sdkmanager --licenses"

# Install required SDKs, NDK, CMake, build-tools
RUN bash -lc "sdkmanager \
    'platform-tools' \
    'platforms;android-31' \
    'platforms;android-33' \
    'platforms;android-34' \
    'ndk;27.0.12077973' \
    'cmake;3.22.1' \
    'build-tools;33.0.2'"

# Pre-cache Gradle wrapper
RUN mkdir -p /root/.gradle && echo "Gradle cache ready"

# Set working directory for builds
WORKDIR /workspace
