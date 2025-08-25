# -----------------------------
# Base image
# -----------------------------
FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV ANDROID_SDK_ROOT=/opt/android-sdk
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH

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

RUN flutter precache --android
RUN flutter doctor -v

# -----------------------------
# Android Command line tools
# -----------------------------
RUN mkdir -p $ANDROID_SDK_ROOT/cmdline-tools && \
    cd $ANDROID_SDK_ROOT/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O cmdline-tools.zip && \
    unzip cmdline-tools.zip && rm cmdline-tools.zip && \
    mv cmdline-tools latest

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
# Pre-download Gradle distribution
# -----------------------------
RUN mkdir -p /root/.gradle/wrapper/dists && \
    wget https://services.gradle.org/distributions/gradle-8.14.3-all.zip -O /tmp/gradle.zip && \
    mkdir -p /root/.gradle/wrapper/dists/gradle-8.14.3-all && \
    unzip -q /tmp/gradle.zip -d /root/.gradle/wrapper/dists/gradle-8.14.3-all/ && \
    rm /tmp/gradle.zip

# -----------------------------
# Pre-cache Flutter packages
# -----------------------------
RUN mkdir -p /workspace && \
    cd /workspace && \
    flutter create temp_project && \
    cd temp_project && \
    flutter pub get && \
    cd / && rm -rf /workspace/temp_project

# -----------------------------
# Pre-cache Gradle wrapper + dependencies
# -----------------------------
# Minimal dummy Android project to warm up Gradle caches
RUN mkdir -p /workspace/android_warmup && \
    cd /workspace/android_warmup && \
    mkdir -p app && \
    echo "plugins { \
          id 'com.android.application' \
          id 'org.jetbrains.kotlin.android' \
          id 'com.google.gms.google-services' \
          id 'com.google.firebase.crashlytics' \
          }" > build.gradle.kts && \
    echo "android { compileSdk = 34 }" >> build.gradle.kts && \
    echo "dependencies { implementation(\"org.jetbrains.kotlin:kotlin-stdlib:1.9.25\") }" >> build.gradle.kts && \
    echo "rootProject.name = \"warmup\"" > settings.gradle.kts && \
    ./gradlew assembleDebug --no-daemon || true

# -----------------------------
# Clean up workspace (optional)
# -----------------------------
RUN rm -rf /workspace/android_warmup

WORKDIR /