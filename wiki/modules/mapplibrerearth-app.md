---
type: Module
title: MLNGlobeApp app
description: The MLNGlobeApp application target — its files, its QMapLibre dependency and its build behaviour. The CMake target still uses MapLibreEarth.
tags: [ module, app ]
status: draft
---
## Summary

`MLNGlobeApp` is the application target: a Qt Quick app that finds an installed `QMapLibre` package and renders a map. The GitHub repository is now `JohnDr/MLNGlobeApp`; the local clone path (`C:\hda\dev\Projects\MapLibreEarth`), CMake target and QML URI still use `MapLibreEarth` until the code rename. Source: `C:\hda\dev\Projects\MapLibreEarth`.

## Files

| File | Role |
|------|------|
| [`main.cpp`](../entry-points/mapplibrerearth.md) | Entry point: sets the graphics API, engine, loads the QML. |
| [`main.qml`](../entry-points/main-qml.md) | The entire UI — the map, the dialogs and the gestures. |
| `CMakeLists.txt` | The build: a single `qt_add_executable` + `qt_add_qml_module` (URI `MapLibreEarth`). |
| `CMakePresets.json` | A `default` desktop preset reading `QT_ROOT_DIR` / `QMapLibre_DIR`. |

## Dependency

`find_package(QMapLibre COMPONENTS Core Quick REQUIRED)` — the app links `QMapLibre::Core` and pulls in the `MapLibre` QML module. Set `QMapLibre_DIR` to the install's `lib/cmake/QMapLibre`.

## Build behaviour

- **Windows**: a POST_BUILD step copies the QMapLibre runtime next to the executable (from the per-config `QMapLibre_DIR`).
- **Android**: fetches `android_openssl`, and bundles Qt's `qwebp` imageformats plugin (path fixed with `file(TO_CMAKE_PATH)`) so WebP raster tiles decode.

## Features

Style picker (Liberty / Bright / Positron / Open Waters + user URLs), camera presets, settings (app scale), dark mode, 2D/3D toggle, 3D-buildings toggle, gestures. Full list in the [handover §7](../references/handover-jdreadme.md).

## Related

- [Architecture overview](../architecture/overview.md) · [Build (Windows)](../runbooks/build-windows.md) · [Build (Android)](../runbooks/build-android.md)
