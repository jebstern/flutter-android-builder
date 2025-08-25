# Flutter Android Builder Docker Image

A ready-to-use Docker image for building Flutter Android apps. This image contains everything you need to build APKs and AABs without installing Flutter, Java, or the Android SDK manually.

## Features

- Flutter SDK: 3.35.1 (stable channel by default)
- Java: OpenJDK 17
- Android SDK: Platforms 31, 33, 34
- NDK: 27.0.12077973
- CMake: 3.22.1
- Build Tools: 33.0.2
- Pre-cached Gradle & Flutter dependencies for faster builds

All SDKs and tools are installed and pre-configured. Just mount your Flutter project and start building.

## Updating Flutter

Flutter releases new versions frequently. You can build a new Docker image with a newer Flutter version by changing the `FLUTTER_VERSION` build argument:

```bash
docker buildx build \
  --platform linux/amd64 \
  --build-arg FLUTTER_VERSION=3.36.0 \
  -t ghcr.io/jebstern/flutter-android-builder:3.36.0-ndk27-api31-34 \
  --push .
  