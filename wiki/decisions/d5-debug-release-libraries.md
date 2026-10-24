---
type: ADR
title: D5 — Debug vs Release libraries
description: A Debug app cannot load the Release MapLibre QML plugin, so a Debug QMapLibre is built and its runtime copied next to the executable.
tags: [ adr, build ]
status: accepted
---
## Status

Accepted (2026-10-11).

## Context

Running MLNGlobeApp **Debug**, Qt refused the Release MapLibre QML plugin:

```
The plugin '.../declarative_maplibre.dll' uses incompatible Qt library.
(Cannot mix debug and release libraries.)
```

After switching to a Debug plugin, it could not find its sibling `QMapLibreQuickPrivated.dll`. Separately, the Open Waters elevation tiles are WebP and the WebP plugin path was broken on Android (backslashes stripped when passed to `androiddeployqt`).

## Decision

- Build and install a **Debug** `QMapLibre` (`C:\hda\dev\tmp\install-maplibre-native-qt-debug`) and point the Debug build config at it.
- Add a **POST_BUILD** step in `MLNGlobeApp/CMakeLists.txt` that copies the QMapLibre runtime next to the executable (Windows), so the app and the QML plugin resolve their DLLs without QMapLibre's `bin` on `PATH`.
- Fix the Android WebP plugin path with `file(TO_CMAKE_PATH)`.

## Consequences

- Debug **and** Release both run from Qt Creator.
- The runtime-copy glob uses the per-config `QMapLibre_DIR`, so Debug copies the Debug DLLs and Release the Release DLLs.

## Related

- [Qt Creator Debug/Release runbook](../runbooks/qt-creator-debug-release.md) · [Android build](../runbooks/build-android.md) · [Environment](../architecture/environment.md)
