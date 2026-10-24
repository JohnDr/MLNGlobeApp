---
type: Entry Point
title: main.cpp
description: The MLNGlobeApp C++ entry point — graphics API, application scale, QML engine and load.
tags: [ entry-point, cpp ]
status: draft
---
## Summary

`main.cpp` creates the Qt application, configures the rendering backend, builds a `QQmlApplicationEngine` and loads the QML from the compiled resources (`qrc:/MLNGlobeApp/main.qml`).

## What it does

1. Sets identity: `QCoreApplication::setApplicationName(QStringLiteral("MLNGlobeApp"))` (and the organisation, so `QSettings` lands under `HKCU\Software\MapLibre\MLNGlobeApp`).
2. Reads the persisted **application scale** (a `QT_SCALE_FACTOR`-style setting) and reports the platform / graphics API / renderer.
3. Creates the QML engine and loads the QML module resource.
4. Exits non-zero if no root objects were created (QML failed to load).

## Notes

- The app is built as a Windows GUI subsystem executable (`qt_add_executable`).
- The QML module URI is `MLNGlobeApp`, matching the `qrc:/MLNGlobeApp/` path.

## Related

- [`main.qml`](./main-qml.md) · [MLNGlobeApp module](../modules/mapplibrerearth-app.md)
