---
type: Reference
title: Handover (JDReadme)
description: The original MapLibre Native Qt build handover, preserved — environment, Windows/Android builds, the example, and the 13.6.1 upgrade + patch.
tags: [ reference, handover ]
status: draft
---
## Summary

Preserved capture of the build handover `C:\hda\dev\Projects\JDReadmeMapLibreNativeQt.txt` (kept outside any repo). It documents building MapLibre Native Qt (Vulkan), the Windows/Android builds, the standalone example, and the MapLibre Native 13.6.1 upgrade with the style-spec patch. Facts here back the [runbooks](../runbooks/index.md) and [decisions](../decisions/index.md).

## 1. Get the source

```
cd C:\hda\dev\Projects
git clone https://github.com/maplibre/maplibre-native-qt.git
cd maplibre-native-qt
git submodule update --init --recursive
```

The vendored core (`vendor/maplibre-native`) is pinned to tag **android-v13.6.1** and patched at configure time (§8).

## 2. Required fix — vendored Vulkan headers in `src/core`

With Vulkan SDK 1.4.x the system Vulkan-Hpp renamed `VULKAN_HPP_DISPATCH_LOADER_DYNAMIC_TYPE`; `MLNQtCore` must use the repo's vendored headers. In `src/core/CMakeLists.txt`, inside `target_include_directories(MLNQtCore ... PRIVATE ...)` add:

```cmake
$<$<BOOL:${MLN_WITH_VULKAN}>:${MLN_CORE_PATH}/vendor/Vulkan-Headers/include>
$<$<BOOL:${MLN_WITH_VULKAN}>:${MLN_CORE_PATH}/vendor/VulkanMemoryAllocator/include>
```

(Now upstream PR **#324**.)

## 3. Build in Qt Creator

Build dirs under `C:\hda\dev\tmp`. Kit **Desktop Qt 6.12.0 MSVC2022 64bit**; CMake initial parameters `-DMLN_WITH_VULKAN:BOOL=ON -DMLN_QT_WITH_WIDGETS:BOOL=OFF -DMLN_QT_WITH_LOCATION:BOOL=OFF`. The repo ships `CMakePresets.json`, so Qt Creator defaults to **presets** mode; the project is used in **kit** mode (target `qt.qt6.6120.win64_msvc2022_64_kit`), saved in `.qtcreator\CMakeLists.txt.user`.

## 4. Manual command-line build + install

```
cmake -S . -B C:\hda\dev\tmp\build-maplibre-native-qt-vulkan -G "Ninja Multi-Config" ^
      -DCMAKE_TOOLCHAIN_FILE=%QT_ROOT_DIR%\lib\cmake\Qt6\qt.toolchain.cmake ^
      -DCMAKE_CONFIGURATION_TYPES="Release;Debug" -DCMAKE_POLICY_VERSION_MINIMUM=3.19 ^
      -DMLN_WITH_VULKAN=ON -DMLN_QT_WITH_WIDGETS=OFF -DMLN_QT_WITH_LOCATION=OFF
cmake --build ... --config Release ; cmake --build ... --config Debug
cmake --install ... --config Release --prefix C:\hda\dev\tmp\install\maplibre-native-qt
```

## 5. Build results (verified)

- Release → `build-maplibre-native-qt-Desktop_Qt_6_12_0_MSVC2022_64bit-Release`: `QMapLibre.dll`, `QMapLibreQuickPrivate.dll`, `declarative_maplibre.dll`.
- Debug → `build-...-Debug`: `QMapLibred.dll`, `QMapLibreQuickPrivated.dll`, debug `declarative_maplibre.dll`.
- Both with `MLN_WITH_VULKAN=ON`, generator `NMake Makefiles JOM`, Qt 6.12.0.

## 6. Android build + deploy

Qt for Android 6.12.0 installed; kit **Qt 6.12.0 for Android arm64-v8a**. SDK `...\Android\Sdk`, NDK `27.2.12479018`, JDK 21. Environment and commands are in the [Android build](../runbooks/build-android.md) and [deploy](../runbooks/deploy-android.md) runbooks. The release APK is unsigned — sign with the debug keystore, then install.

## 7. Standalone example — status

The `examples\quick-standalone` example (now **MapLibreEarth**, see [D1](../decisions/d1-standalone-app.md)) is built for Windows (Release/Debug, Vulkan) and Android arm64-v8a/x86_64. Features: Liberty default style; a **Maps** dialog to list/add/remove style URLs; a **Presets** dialog of named camera presets; a **Settings** dialog for app scale; a dark/light switch; a 2D/3D toggle; zoom +/- buttons; wheel = stepped zoom; right-drag = smooth zoom. Gestures use `PinchHandler`s (see [Gestures](../flows/gestures.md)): a 2-point pinch (scale about the centroid, guarded against the finger add/remove spike), a 1-point pan (a `PinchHandler`, not a `DragHandler`, to avoid the stale-baseline snap on lift-off), and a 1-point **right-button** `PinchHandler` for smooth zoom. The right-drag required the library change `setAcceptedMouseButtons(Qt::LeftButton \| Qt::RightButton)` (commit `1177540`).

## 8. MapLibre Native 13.6.1 upgrade + style-spec patch (commit `6db61e9`)

Upgraded the vendored core from `android-v13.4.0` (`702ebc6114ad`) to `android-v13.6.1` (`c7506d6aff38`): `include/mbgl`→`include/mln`, namespace `mbgl`→`mln` (incl. forward declarations), and the installed include dir. ~30 files under `src/core` and `src/quick`; CMake target names unchanged.

Because Native drops an entire layer on an unknown property, the Open Waters style's newer properties dropped ~16 layers (buoys, beacons, lights, topmarks, landmarks, …). The [style-spec patch](./fork-patches.md) fixes this. Result: Open Waters renders buoys/marks/lights and dashed hazard areas with **0 style-parse warnings** (was 16 + 2); Windows and Android arm64-v8a/x86_64; only `[General]: Invalid geometry in line layer` remains.

## Related

- [Decisions](../decisions/index.md) · [Runbooks](../runbooks/index.md) · [Downstream patches](./fork-patches.md)
