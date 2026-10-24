---
type: Runbook
title: Build (Android)
description: Build the QMapLibre library and the MLNGlobeApp APK for Android (arm64-v8a).
tags: [ runbook, android, build ]
status: draft
---
## Summary

Build the [`QMapLibre`](../concepts/maplibre-native-qt.md) library for Android, then the [MLNGlobeApp](../modules/mapplibrerearth-app.md) APK. arm64-v8a shown; x86_64 is analogous.

## Prerequisites (environment)

```
QT_ROOT_DIR      = C:\Qt\6.12.0\android_arm64_v8a
ANDROID_ABI      = arm64-v8a
ANDROID_SDK_ROOT = C:\Users\JohnD\AppData\Local\Android\Sdk
ANDROID_NDK_ROOT = C:\Users\JohnD\AppData\Local\Android\Sdk\ndk\27.2.12479018
JAVA_HOME        = C:\Program Files\Eclipse Adoptium\jdk-21.0.0.35-hotspot
PATH            += C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin;%QT_ROOT_DIR%\bin
```

## 1. Library for Android

Qt-for-Android has no QtLocation, so Location/Widgets are off:

```
cmake --preset Android-Vulkan -B C:\hda\dev\tmp\build-maplibre-native-qt-Android-Vulkan
      -DMLN_QT_WITH_LOCATION=OFF -DMLN_QT_WITH_WIDGETS=OFF
cmake --build C:\hda\dev\tmp\build-maplibre-native-qt-Android-Vulkan
cmake --install C:\hda\dev\tmp\build-maplibre-native-qt-Android-Vulkan `
      --prefix C:\hda\dev\tmp\install-maplibre-android
```

## 2. App APK

> **`QMapLibre_DIR` is required** — without it CMake fails with *Could not find a package configuration file provided by "QMapLibre"*.

```
cmake -S C:\hda\dev\Projects\MapLibreEarth -B C:\hda\dev\tmp\build-maplibreearth-android -G Ninja `
      -DCMAKE_TOOLCHAIN_FILE=%QT_ROOT_DIR%\lib\cmake\Qt6\qt.toolchain.cmake `
      -DANDROID_ABI=arm64-v8a -DCMAKE_BUILD_TYPE=Release `
      -DQT_HOST_PATH=C:\Qt\6.12.0\msvc2022_64 `
      -DQMapLibre_DIR=C:\hda\dev\tmp\install-maplibre-android\lib\cmake\QMapLibre
cmake --build C:\hda\dev\tmp\build-maplibreearth-android --target apk
```

The APK lands at `build-maplibreearth-android\android-build\MLNGlobeApp.apk` (package `org.qtproject.example.MLNGlobeApp`).

> Qt Creator cannot build this yet — it has no Android kit config for MLNGlobeApp. See [Next steps](../next-steps.md).

## Related

- [Deploy to the S23](./deploy-android.md) · [Open Waters](./open-waters.md) · [Android verification](../verification/android.md)
