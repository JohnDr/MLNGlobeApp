---
type: Architecture
title: Environment
description: Repositories, install prefixes, build directories, SDKs and devices for the MLNGlobeApp project.
tags: [ architecture, environment ]
status: draft
---
## Summary

Where everything lives on the build machine. Build directories are all under `C:\hda\dev\tmp` (Qt Creator is configured with `Directories > BuildDirectory.TemplateV2`).

## Repositories

| Repo | Local path | Remote |
|------|-----------|--------|
| MLNGlobeApp | `C:\hda\dev\Projects\MapLibreEarth` | `JohnDr/MLNGlobeApp` (public) |
| MapLibre Native Qt | `C:\hda\dev\Projects\maplibre-native-qt` | `origin` = `maplibre/maplibre-native-qt`; `fork` = `JohnDr/maplibre-native-qt` |
| MapLibre Native | submodule of the above | fork `JohnDr/maplibre-native` |
| Handover doc | `C:\hda\dev\Projects\JDReadmeMapLibreNativeQt.txt` | (outside any repo) |

## QMapLibre installs (what MLNGlobeApp builds against)

| Config | Prefix |
|--------|--------|
| Windows Release | `C:\hda\dev\tmp\install\maplibre-native-qt` |
| Windows Debug | `C:\hda\dev\tmp\install-maplibre-native-qt-debug` |
| Android arm64-v8a | `C:\hda\dev\tmp\install-maplibre-android` |
| Android x86_64 | `C:\hda\dev\tmp\install-maplibre-android-x86_64` |

Each install has `lib/cmake/QMapLibre/QMapLibreConfig.cmake`, `bin/QMapLibre*.dll` (Windows) or `lib/libQMapLibre_<abi>.so` (Android), and the QML module under `qml/MapLibre/`.

## Build directories

- **MLNGlobeApp**: `C:\hda\dev\tmp\build-MLNGlobeApp-Desktop_Qt_6_12_0_MSVC2022_64bit-{Debug,Release}`; Android `C:\hda\dev\tmp\build-maplibreearth-android`.
- **MapLibre Native Qt**: `C:\hda\dev\tmp\build-maplibre-native-qt-Desktop_Qt_6_12_0_MSVC2022_64bit-{Release,Debug}`; Android `build-maplibre-native-qt-Android-Vulkan`, `build-maplibre-native-qt-Android-x86_64`.

## SDKs

| SDK | Path |
|-----|------|
| Qt | `C:\Qt\6.12.0\{msvc2022_64,android_arm64_v8a,android_x86_64}` |
| Vulkan | `C:\VulkanSDK\1.4.304.0` |
| Android SDK | `C:\Users\JohnD\AppData\Local\Android\Sdk` |
| Android NDK | `...\Sdk\ndk\27.2.12479018` |
| Android build-tools | `...\Sdk\build-tools\36.0.0` |
| JDK | `C:\Program Files\Eclipse Adoptium\jdk-21.0.0.35-hotspot` |

## Devices

- **Galaxy S23** — `adb` serial `RFCW910087W`. Deployment target for the [Android deploy runbook](../runbooks/deploy-android.md).

The [Open Waters](../flows/open-waters-rendering.md) elevation tiles are WebP, so Qt's `qwebp` imageformats plugin is installed for both the Windows host and Android ([D5](../decisions/d5-debug-release-libraries.md)).

## Related

- [Technology](./technology.md) · [Runbooks](../runbooks/index.md)
