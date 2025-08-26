FROM ubuntu:22.04

# -----------------------------
# Basic tools
# -----------------------------
RUN apt-get update && apt-get install -y \
    curl unzip git xz-utils zip libglu1-mesa openjdk-17-jdk nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Install Flutter
# -----------------------------
ENV FLUTTER_VERSION=3.35.1
ENV FLUTTER_HOME=/opt/flutter
ENV PATH=$FLUTTER_HOME/bin:$PATH

RUN git clone https://github.com/flutter/flutter.git -b $FLUTTER_VERSION $FLUTTER_HOME \
    && flutter doctor -v

# -----------------------------
# Install Android SDK
# -----------------------------
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH

RUN mkdir -p $ANDROID_HOME/cmdline-tools \
    && curl -s https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o cmdline-tools.zip \
    && unzip cmdline-tools.zip -d $ANDROID_HOME/cmdline-tools \
    && mv $ANDROID_HOME/cmdline-tools/cmdline-tools $ANDROID_HOME/cmdline-tools/latest \
    && rm cmdline-tools.zip \
    && yes | sdkmanager --licenses

RUN sdkmanager "platform-tools" \
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
# Install Gradle (system-wide, avoid wrapper downloads)
# -----------------------------
ENV GRADLE_VERSION=8.14.3
ENV GRADLE_HOME=/opt/gradle
ENV PATH=$GRADLE_HOME/bin:$PATH

RUN curl -sL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-all.zip -o /opt/gradle-${GRADLE_VERSION}-all.zip \
    && unzip /opt/gradle-${GRADLE_VERSION}-all.zip -d /opt \
    && mv /opt/gradle-${GRADLE_VERSION} $GRADLE_HOME \
    && rm /opt/gradle-${GRADLE_VERSION}-all.zip

# -----------------------------
# Prepare Gradle (copy real Gradle files from repo)
# -----------------------------
WORKDIR /workspace/android

COPY android/settings.gradle.kts ./settings.gradle.kts
COPY android/build.gradle.kts ./build.gradle.kts
COPY android/gradle.properties ./gradle.properties
COPY android/gradle ./gradle
COPY android/app/build.gradle.kts ./app/build.gradle.kts

# Force Gradle wrapper to use local Gradle instead of downloading
RUN sed -i "s#distributionUrl=.*#distributionUrl=file:///opt/gradle/gradle-${GRADLE_VERSION}-all.zip#g" gradle/wrapper/gradle-wrapper.properties

# Warm-up Gradle (download AGP, Kotlin, Firebase, etc.)
RUN ./gradlew help --no-daemon || true

# -----------------------------
# Final workdir
# -----------------------------
WORKDIR /workspace
