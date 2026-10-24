---
type: Runbook
title: Build (Windows)
description: Build and install QMapLibre and build MLNGlobeApp on Windows (MSVC, Vulkan).
tags: [ runbook, windows, build ]
status: draft
---
## Summary

Two stages: build the [`QMapLibre`](../concepts/maplibre-native-qt.md) library, then build the [MLNGlobeApp app](../modules/mapplibrerearth-app.md) against the install. Full original notes: [handover §1–5](../references/handover-jdreadme.md).

## Prerequisites

Environment for the command-line build:

```
QTDIR       = C:\Qt\6.12.0\msvc2022_64
VULKAN_SDK  = C:\VulkanSDK\1.4.304.0
PATH       += C:\Qt\6.12.0\msvc2022_64\bin;C:\Qt\Tools\Ninja;C:\Qt\Tools\CMake_64\bin
```

MSVC (VS 2022), CMake ≥ 3.25, Ninja, Qt 6.12.0 MSVC2022 64-bit, Vulkan SDK.

## 1. Build + install the library

The library is configured with `MLN_WITH_VULKAN=ON`, `MLN_QT_WITH_WIDGETS=OFF`, `MLN_QT_WITH_LOCATION=OFF`. In Qt Creator it builds in **kit mode** (generator `NMake Makefiles JOM`); on the command line:

```powershell
cmake --build C:\hda\dev\tmp\build-maplibre-native-qt-Desktop_Qt_6_12_0_MSVC2022_64bit-Release
cmake --install C:\hda\dev\tmp\build-maplibre-native-qt-Desktop_Qt_6_12_0_MSVC2022_64bit-Release `
      --prefix C:\hda\dev\tmp\install\maplibre-native-qt
```

There is also a **Vulkan vendored-headers fix** needed for the library (`src/core/CMakeLists.txt`) — see [handover §2](../references/handover-jdreadme.md) and PR [#324](../references/upstream-prs.md). A ready-made batch is at `%LOCALAPPDATA%\Temp\opencode\build-me.bat` (app) and the Debug library batch at `build-mnqt-debug.bat`.

## 2. Build the app

```powershell
cmake -S C:\hda\dev\Projects\MapLibreEarth -B C:\hda\dev\Projects\MapLibreEarth\build -G Ninja `
  -DCMAKE_PREFIX_PATH=C:\Qt\6.12.0\msvc2022_64 `
  -DQMapLibre_DIR=C:\hda\dev\tmp\install\maplibre-native-qt\lib\cmake\QMapLibre `
  -DCMAKE_BUILD_TYPE=Release
cmake --build C:\hda\dev\Projects\MapLibreEarth\build
```

The POST_BUILD step copies the QMapLibre runtime next to the exe. To run: prepend Qt's `bin` (and, if needed, the install `bin`) to `PATH`.

## Related

- [Qt Creator Debug/Release](./qt-creator-debug-release.md) · [Android build](./build-android.md) · [JDReadme handover](../references/handover-jdreadme.md)
